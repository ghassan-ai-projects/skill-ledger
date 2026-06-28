# Skill Approval Workflow Plan

## Purpose

SkillLedger currently has automated artifact verification, not marketplace approval. Verification proves that a submitted artifact is structurally valid and internally consistent. Approval should decide whether a verified skill version is allowed to be publicly listed, purchased, and acquired through the marketplace.

This plan adds an explicit approval layer while preserving the current product model: SkillLedger distributes verified client-side acquisition packages and does not execute third-party skills on a hosted runtime.

## Goals

- Separate artifact verification from marketplace approval.
- Require approval before a skill version can become publicly purchasable.
- Keep controllers thin by putting review and approval rules in services.
- Record durable review decisions for auditability.
- Support automated policy checks first, with manual review as the final authority.
- Allow maintainers to suspend or revoke approval for a risky version after publication.

## Non-Goals

- Do not add hosted execution for acquired skills.
- Do not claim complete malware detection.
- Do not block local acquisition of already purchased versions unless revocation rules explicitly require it.
- Do not introduce external scanning services in the first implementation phase.

## Current State

Publishing a version creates a `SkillVersion`, stores a `SkillArtifact`, and immediately runs `SkillArtifactVerificationService`.

If all verification checks pass:

- `skill_versions.status` becomes `verified`
- `skill_verifications.status` becomes `verified`
- the author can set the skill listing to `listed`

This is enough for MVP artifact consistency, but it does not answer marketplace approval questions such as safety, policy compliance, publisher trust, provenance, permissions, or post-publication revocation.

## Proposed State Model

Keep verification status focused on artifact validity. Add approval status for marketplace eligibility.

Recommended version lifecycle:

```text
draft
  -> verified
  -> pending_review
  -> approved
  -> rejected
  -> revoked
  -> retired
```

Interpretation:

- `draft`: version has been created but is not usable.
- `verified`: automated artifact checks passed.
- `pending_review`: version is waiting for policy or admin approval.
- `approved`: version may be listed, purchased, and acquired.
- `rejected`: version failed review and must be resubmitted as a new version.
- `revoked`: version was previously approved but is no longer trusted for new purchases.
- `retired`: author intentionally stopped promoting the version.

Important rule: `verified` is necessary but not sufficient for public marketplace use. Public listing and purchase require an approved version.

## Data Model

Add a dedicated review record instead of overloading `skill_verifications`.

```text
skill_reviews
  id
  skill_version_id
  status                  # pending, approved, rejected, revoked
  review_type             # automated, manual, appeal, revocation
  reviewer_account_id     # nullable for automated decisions
  policy_checks           # json
  decision_reason         # text
  submitted_at
  decided_at
  created_at
  updated_at
```

Potential later additions:

```text
publisher_trust_profiles
  account_id
  identity_status         # unverified, verified, trusted
  risk_score
  last_reviewed_at

skill_version_permissions
  skill_version_id
  filesystem_access       # none, read, write
  network_access          # none, restricted, unrestricted
  shell_access            # boolean
  secrets_access          # none, declared
  declared_domains        # json array
```

## Policy Checks

Phase 1 should use deterministic checks that can run locally:

- manifest declares expected fields and categories
- artifact size is within configured limits
- bundled files use allowed paths and media types
- declared permissions are present and explicit
- suspicious file paths are rejected, such as absolute paths or parent directory traversal
- package does not include obvious secret names or credential-looking values
- description and manifest metadata are not empty, misleadingly generic, or inconsistent with the skill name

Phase 2 can add stronger checks:

- static code scanning for dangerous calls
- dependency allowlist or vulnerability scanning
- publisher trust score
- signature or provenance validation
- reviewer checklist templates

## Approval Rules

Public marketplace visibility should require:

- skill listing status is `listed`
- latest selected version has `skill_versions.status = approved`
- associated `skill_verifications.status = verified`
- associated `skill_reviews.status = approved`
- associated artifact exists and checksum still matches the manifest

Purchases should require the same approved-version rule.

Acquisition behavior should be explicit:

- New purchases of `revoked` versions are blocked.
- Existing purchases of `revoked` versions return a warning and may be blocked by policy.
- Existing purchases of `approved` versions continue to acquire normally.

## Services

Add or update these services:

- `SkillReviewSubmissionService`: moves a verified version into review.
- `SkillPolicyCheckService`: runs deterministic local policy checks and returns structured results.
- `SkillApprovalService`: approves, rejects, or revokes a version.
- `SkillMarketplaceEligibilityService`: centralizes whether a version can be listed, purchased, or acquired.

Existing services to update:

- `SkillVersionRegistrationService`: after successful verification, create a pending review record instead of treating verification as full approval.
- `SkillListingStatusService`: require at least one approved version before allowing `listed`.
- `SkillPurchaseService`: require an approved version, not only a verified version.
- `SkillAcquisitionService`: include approval and revocation metadata in the acquisition response.
- `McpService`: expose approval state for author and buyer flows.

## API Changes

REST additions:

```text
GET    /api/v1/admin/skill_reviews
GET    /api/v1/admin/skill_reviews/:id
PATCH  /api/v1/admin/skill_reviews/:id/approve
PATCH  /api/v1/admin/skill_reviews/:id/reject
PATCH  /api/v1/admin/skill_reviews/:id/revoke
```

Author-facing additions:

```text
POST   /api/v1/skills/:skill_id/versions/:version_id/submit_review
GET    /api/v1/skills/:skill_id/versions/:version_id/review
```

MCP additions:

```text
skills/version.submit_review
skills/version.review_status
skills/review.list_pending       # admin only
skills/review.decide             # admin only
```

Existing responses should include approval status alongside verification status so clients can distinguish structural verification from marketplace approval.

## Admin Authorization

The first implementation can use an account-level admin flag:

```text
accounts.admin boolean default false
```

Admin endpoints and MCP review methods must require:

- valid `X-API-Key`
- `current_account.admin?`

Later versions can replace this with scoped API keys or roles.

## Rollout Plan

### Phase 1: Approval State And Gates

- Add `skill_reviews` table.
- Add approval status to version serialization.
- Create a pending review after a version verifies.
- Require approved versions for listing and purchase.
- Add admin approve, reject, and revoke service methods.
- Add targeted Minitest coverage for approval gates.

### Phase 2: Reviewer API

- Add REST admin review endpoints.
- Add author review status endpoints.
- Add MCP review status and admin decision methods.
- Update `openapi.yaml`, `documentation/rest-api.md`, and `documentation/mcp-api.md`.

### Phase 3: Policy Checks

- Implement `SkillPolicyCheckService`.
- Store policy check output in `skill_reviews.policy_checks`.
- Auto-reject clearly invalid submissions.
- Keep borderline submissions in `pending_review`.

### Phase 4: Revocation Semantics

- Define whether revoked purchased versions are warning-only or blocked.
- Add acquisition response warnings.
- Add audit-friendly revocation reasons.
- Add reporting for revoked or rejected versions.

### Phase 5: Publisher Trust And Provenance

- Add publisher trust profile.
- Add declared permission model.
- Add package signing or provenance fields.
- Use trust level to route low-risk updates through faster review.

## Testing Strategy

Coverage should include:

- verified-but-unapproved versions cannot be listed
- verified-but-unapproved versions cannot be purchased
- approved versions can be listed and purchased
- rejected versions stay blocked
- revoked versions block new purchases
- non-admin accounts cannot approve, reject, or revoke
- review decisions are recorded with reviewer, timestamp, reason, and policy checks
- MCP and REST response bodies expose both verification and approval status

## Documentation Updates

When implemented, update:

- `README.md`: explain verification versus approval.
- `documentation/how-it-works.md`: add approval to the author publishing flow.
- `documentation/security-model.md`: document approval limits and revocation behavior.
- `documentation/rest-api.md`: add review endpoints.
- `documentation/mcp-api.md`: add review methods.
- `openapi.yaml`: document all public API changes.

## Open Questions

- Should initial approval be manual-only, or should low-risk submissions auto-approve after policy checks?
- Should revocation block acquisition for existing purchasers, or only block new purchases?
- Should approval happen per version only, or should a skill listing also have its own approval record?
- What admin model is acceptable for MVP: account boolean, role enum, or scoped API keys?
- Should artifacts require signed provenance before approval can move beyond MVP?
