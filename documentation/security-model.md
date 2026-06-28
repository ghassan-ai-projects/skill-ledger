# Security Model

## Current Trust Model

SkillLedger is a trusted application server with account-scoped API keys and internal balance accounting. The current model assumes:

- the application server is trusted
- the database is trusted
- artifact verification checks format and consistency, not safety of execution
- buyers execute acquired artifacts in environments they control

## Authentication

- every endpoint requires `X-API-Key`
- API keys are generated on account creation
- authorization for author-only actions is enforced in service-layer logic

## Authorization Boundaries

Current important boundaries:

- only the authenticated author can publish versions for a skill
- only the authenticated author can change listing status for a skill
- only the authenticated author can access their analytics and earnings
- only the authenticated buyer can acquire a purchase
- only accounts with `admin: true` can list pending skill reviews or decide them (approve, reject, revoke), both over REST (`/api/v1/admin/skill_reviews`) and MCP (`skills/review.list_pending`, `skills/review.decide`)

## Purchase Integrity

Skill purchases are designed to be atomic:

- buyer balance is debited
- author balance is credited
- a ledger entry is created
- a paid purchase is created

These steps happen inside a transaction in the purchase service.

## Artifact Verification Limits

Verification currently proves that:

- the manifest is present and internally consistent
- the checksum matches the stored manifest
- required fields exist
- runtime is declared as client
- bundled file metadata is well formed

Verification does not prove:

- the code is safe
- the code will behave as described
- the artifact is free from malicious payloads
- the runtime environment is isolated

## Marketplace Approval Limits

Verification (above) is distinct from marketplace approval. A `SkillReview` record tracks the approval decision separately:

- `SkillPolicyCheckService` only runs deterministic, local checks (file paths, size, regex secret scanning, declared permissions). It is not a substitute for code review, sandboxed execution analysis, or external scanning.
- Automated rejection only happens for a small set of hard-fail conditions (path traversal, absolute paths, obvious secret-looking strings). Everything else is left `pending` for a human admin decision — manual review is the final authority.
- The `accounts.admin` boolean is the entire authorization model for reviewers in this version. There is no scoped reviewer role or multi-party sign-off.
- Every review transition is captured in an append-only `skill_review_events` log (actor, from/to status, reason, timestamp), so decision history survives later re-decisions. The log is not yet cryptographically tamper-evident — it relies on database integrity and the trusted-server assumption above.
- Revoking a review blocks new purchases of that version but does not retroactively affect prior purchases, acquisitions, or already-distributed artifacts.

## Hardening Priorities

If you plan to deploy this beyond local or experimental use, prioritize:

- secret management for API keys and Rails credentials
- rate limiting
- request logging review for sensitive data exposure
- artifact size limits and validation tightening
- more explicit ownership and policy checks
- backup and restore testing
- database strategy review if write volume will grow

## Disclosure

See [SECURITY.md](../SECURITY.md) for reporting guidance.
