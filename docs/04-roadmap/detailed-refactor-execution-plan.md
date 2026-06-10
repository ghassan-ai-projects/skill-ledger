# Detailed Refactor Execution Plan

**Status:** Planned  
**Scope:** Refactor SkillLedger from hosted execution to verified skill acquisition for client-side execution  
**Branch:** `codex/clarified-vision-refactor`  
**Current implementation preserved on:** `codex/hosted-exec-baseline` at `13aef09`

## Objective

Ship a narrow MVP for the clarified product:

> A buyer agent can discover a verified skill, pay to acquire it, receive the artifact plus verification metadata, and execute it locally.

SkillLedger should verify and sell skill artifacts. It should not host the runtime for those skills.

## Product Invariant

The central invariant for this refactor:

> SkillLedger delivers verified skill artifacts; buyer agents execute those artifacts outside SkillLedger.

Any design that requires SkillLedger to run the skill as the primary flow is outside the clarified scope.

## Second Critical Review Decisions

These decisions tighten the plan after review and should be treated as implementation constraints.

### Do Not Overclaim Verification

MVP verification proves artifact shape, integrity, provenance, and publication eligibility. It does not prove the skill is useful, safe in every buyer environment, or behaviorally correct.

Required product language:
- say `verified artifact`
- avoid saying `trusted execution`
- avoid saying SkillLedger guarantees runtime behavior

### Accountability Is Deferred From Automatic Slashing

The product vision includes author accountability and rewards. The first refactor slice must not fake this with automatic slashing based on buyer-side execution, because SkillLedger will not observe buyer execution.

MVP accountability boundary:
- author identity and artifact provenance are recorded
- purchases and acquisition events are auditable
- `slash` remains a reserved ledger type
- automatic slashing is out of scope until there is a dispute, report, or external evidence flow

### Purchases Must Be Retry Safe

Buyer agents will retry MCP calls. A retry must not silently double-charge a buyer for the same skill version.

MVP rule:
- one active paid purchase per `[buyer_id, skill_version_id]`
- repeated purchase request for the same buyer and version returns the existing paid purchase
- balance movement and ledger entry happen exactly once

Optional later enhancement:
- add a caller-provided `idempotency_key` for stricter client-side replay control

### Rollout Must Be Additive First

The first implementation pass should add the corrected acquisition model without deleting hosted-execution code.

Required rollout behavior:
- old execution tests keep passing during transition
- new services do not call `ExecutionService`
- new MCP acquisition methods do not create `Execution`
- old execution endpoints are documented as transitional until removed

### Authorization Rules Are Product Rules

Authorization is part of the marketplace contract, not a controller detail.

Required rules:
- only the author can create versions or artifacts for their skill
- public discovery returns only listed skills with verified versions
- purchase is allowed only for verified versions
- buyer cannot purchase their own skill
- acquire is allowed only for the account that owns the purchase
- suspended skills and retired versions cannot be newly purchased

## First MVP Use Case

### Use Case Name

Verified MCP skill acquisition for local execution.

### User Story

As a buyer agent, I want to discover a verified MCP-style skill, purchase it, and acquire its artifact package so I can execute it locally with confidence about provenance, version, verification status, and author accountability.

### End-To-End Flow

1. Author publishes a skill listing.
2. Author creates version `1.0.0`.
3. Author attaches a skill artifact of type `mcp_tool_manifest`.
4. SkillLedger verifies the artifact.
5. SkillLedger lists only the verified version publicly.
6. Buyer calls `skills/list` through MCP.
7. Buyer calls `skills/purchase` for the verified version.
8. SkillLedger transfers payment from buyer to author and records a ledger entry.
9. Buyer calls `skills/acquire`.
10. SkillLedger returns artifact, manifest, checksum, verification metadata, and entitlement.
11. Buyer executes locally. SkillLedger does not return hosted execution output.

## MVP Artifact Decision

The first supported artifact type is:

`mcp_tool_manifest`

### Minimal Artifact Shape

The artifact must contain:

```json
{
  "name": "deterministic-pricing-review",
  "description": "Review a pricing payload for deterministic rule violations.",
  "version": "1.0.0",
  "runtime": "client",
  "entrypoint": "pricing_review.evaluate",
  "input_schema": {
    "type": "object",
    "required": ["items"],
    "properties": {
      "items": {
        "type": "array"
      }
    }
  },
  "output_schema": {
    "type": "object"
  }
}
```

### Artifact Storage Decision For MVP

Store the artifact manifest in the database as JSON/text.

Reason:
- keeps the first refactor small
- avoids premature file storage complexity
- makes checksum generation deterministic and testable

Later versions can move artifact payloads to object storage or signed external URLs.

### Checksum Decision

Compute a SHA-256 checksum over canonical JSON for the manifest payload.

Acceptance criteria:
- same manifest generates same checksum
- acquired artifact includes checksum
- checksum is stored on `SkillArtifact`

Implementation note:
- canonical JSON means normalized object keys and stable serialization
- checksum must be computed by application code, not accepted blindly from the author
- verification must compare stored checksum to the canonical manifest payload before marking a version verified

## MVP Verification Decision

Verification is publication-time validation, not runtime execution.

### MVP Verification Checks

The verifier must check:

- artifact type is supported
- manifest is valid JSON/object data
- required fields exist:
  - `name`
  - `description`
  - `version`
  - `runtime`
  - `entrypoint`
  - `input_schema`
  - `output_schema`
- `runtime` equals `client`
- version matches the `SkillVersion`
- checksum is present and matches artifact contents

### Verification Statuses

Use:
- `pending`
- `verified`
- `rejected`

### Public Listing Rule

Only skill versions with `SkillVerification.status == "verified"` can be publicly listed or purchased.

### State Transition Rule

State transitions should be explicit. Avoid letting controllers mutate statuses directly.

Required transitions:
- `SkillVersion`: `draft -> verified`, `draft -> rejected`, `verified -> retired`
- `SkillVerification`: `pending -> verified`, `pending -> rejected`
- `Purchase`: `paid -> refunded`, `paid -> revoked`

## Domain Model Plan

### `Skill`

Existing model remains the stable listing.

Required changes:
- add `slug`
- add `listing_status`
- keep `author_id`
- keep `price_per_call` initially, but rename conceptually to acquisition price later

Suggested statuses:
- `draft`
- `listed`
- `suspended`

### `SkillVersion`

New model.

Fields:
- `skill_id`
- `version`
- `changelog`
- `status`
- timestamps

Statuses:
- `draft`
- `verified`
- `rejected`
- `retired`

Constraints:
- unique `[skill_id, version]`

### `SkillArtifact`

New model.

Fields:
- `skill_version_id`
- `artifact_type`
- `manifest`
- `checksum`
- timestamps

Constraints:
- one artifact per version for MVP
- `artifact_type` must be `mcp_tool_manifest` for MVP
- checksum required

### `SkillVerification`

New model.

Fields:
- `skill_version_id`
- `status`
- `checks`
- `verified_at`
- `failure_reason`
- timestamps

Constraints:
- one current verification per version for MVP

### `Purchase`

New model.

Fields:
- `buyer_id`
- `skill_version_id`
- `amount`
- `status`
- `acquired_at`
- `entitlement_token`
- timestamps

Statuses:
- `paid`
- `refunded`
- `revoked`

Constraints:
- buyer cannot purchase own skill
- version must be verified
- buyer balance must cover amount
- one active paid purchase per `[buyer_id, skill_version_id]`
- acquisition is allowed only for `paid` purchases

### `LedgerEntry`

Keep current model.

New entry types:
- `skill_purchase`
- `author_reward`
- `platform_fee`
- `refund`
- `slash`

MVP can start with a single `skill_purchase` entry from buyer to author.

Payment decision:
- MVP transfers the full acquisition amount from buyer to author
- platform fee is reserved but not implemented in the first slice
- refunds and slashing are reserved states, not first-slice behavior

### `Execution`

Demote from primary flow.

Decision:
- do not delete immediately
- stop adding new primary product behavior to it
- keep existing tests passing during transition
- later replace usage with `Purchase`, `UsageReceipt`, or remove if obsolete

## API Plan

### MCP Methods

Implement these first:

- `skills/list`
- `skills/get`
- `skills/purchase`
- `skills/acquire`

### `skills/list`

Returns only publicly listed verified skill versions.

Response must include:
- skill id
- slug
- name
- author
- price
- latest verified version
- verification summary

### `skills/get`

Returns detailed metadata for one verified skill version.

Response must include:
- manifest summary
- checksum
- verification checks
- terms/acquisition price

### `skills/purchase`

Creates a purchase for a verified version.

Request:
- `skill_id`
- `version`

Behavior:
- validates buyer is not author
- validates version is verified
- if a paid purchase already exists for the same buyer and version, returns it without moving money again
- otherwise transfers amount from buyer to author in a transaction
- creates exactly one ledger entry for the first paid purchase
- creates purchase with status `paid`

### `skills/acquire`

Returns artifact package for a paid purchase.

Request:
- `purchase_id`

Behavior:
- validates purchase belongs to current account
- returns artifact and verification metadata
- sets `acquired_at` if not already set
- does not execute the skill

## Acceptance Criteria For First Slice

The first slice is accepted only if:

1. A verified skill version is returned by `skills/list`.
2. An unverified skill version is not returned by `skills/list`.
3. `skills/purchase` rejects unverified versions.
4. `skills/purchase` rejects self-purchase.
5. `skills/purchase` rejects insufficient buyer balance.
6. A valid purchase debits buyer and credits author exactly once.
7. A valid purchase creates a ledger entry.
8. Repeating the same purchase does not debit buyer, credit author, or create a second ledger entry.
9. `skills/acquire` returns artifact manifest, checksum, verification metadata, and entitlement.
10. `skills/acquire` rejects purchases owned by another account.
11. `skills/acquire` does not move money or create ledger entries.
12. No primary acquisition response contains hosted execution output.
13. Acquisition services and MCP handlers do not create `Execution` records.
14. Existing unrelated tests still pass.
15. The skipped E2E contract can be unskipped and passes.

## Definition Of Done

The refactor slice is done when:

- new domain models exist with tests
- publication verification flow exists with tests
- MCP acquisition methods exist with request tests
- the E2E acquisition contract is unskipped and green
- full test suite is green
- README and API docs describe acquisition as the primary product flow, not hosted execution
- hosted execution is no longer the primary product path
- old hosted-execution behavior is either clearly marked transitional or isolated from new acquisition code
- no docs claim SkillLedger executes acquired skills

## Implementation Sequence

### Step 1: Domain Schema

Implement:
- `SkillVersion`
- `SkillArtifact`
- `SkillVerification`
- `Purchase`

Tests:
- model association tests
- validation tests
- uniqueness tests

Exit criteria:
- model tests pass

### Step 2: Artifact Verification

Implement:
- `SkillArtifactVerificationService`
- deterministic checksum generation
- verification status persistence

Tests:
- valid manifest verifies
- missing required field rejects
- wrong runtime rejects
- checksum mismatch rejects

Exit criteria:
- verification service tests pass

### Step 3: Publication Fixture/Seed

Implement one verified sample skill:

`deterministic-pricing-review`

Fixture actors:
- author: `accounts(:alice)`
- buyer: `accounts(:charlie)`

Artifact type:
- `mcp_tool_manifest`

Expected manifest:
- `name`: `deterministic-pricing-review`
- `version`: `1.0.0`
- `runtime`: `client`
- `entrypoint`: `pricing_review.evaluate`

Tests:
- fixture/seed supports the E2E contract
- verified version appears in discovery

Exit criteria:
- discovery tests pass

### Step 4: Purchase Service

Implement:
- `SkillPurchaseService`

Tests:
- successful purchase
- repeated purchase returns existing purchase without second charge
- insufficient funds
- self-purchase
- unverified version rejected
- ledger entry created

Exit criteria:
- purchase service tests pass

### Step 5: Acquisition Service

Implement:
- `SkillAcquisitionService`

Tests:
- owner can acquire artifact
- non-owner rejected
- acquired timestamp set
- artifact payload includes checksum and verification
- acquisition does not create ledger entries
- acquisition does not create executions

Exit criteria:
- acquisition service tests pass

### Step 6: MCP Alignment

Implement:
- `skills/list`
- `skills/get`
- `skills/purchase`
- `skills/acquire`

Tests:
- MCP request tests
- E2E contract unskipped

Exit criteria:
- E2E contract passes

### Step 7: Documentation And Cleanup

Update:
- README
- API docs
- scenario status docs

Clean up:
- label hosted execution endpoints as transitional or remove from docs
- stop describing built-in runtime as the primary use case

Exit criteria:
- docs match behavior

## Risk Register

### Risk: Old execution model leaks into new acquisition model

Mitigation:
- E2E contract explicitly asserts no `hosted_execution` payload
- keep `Execution` out of new services

### Risk: Verification is too weak to create trust

Mitigation:
- label MVP verification as schema/integrity verification
- do not overclaim cryptographic or behavioral guarantees
- keep public response explicit about what was checked

### Risk: Retry creates duplicate charges

Mitigation:
- enforce one active paid purchase per buyer/version
- return existing purchase on duplicate purchase request
- test that balance movement and ledger entry creation happen once

### Risk: Artifact model becomes too broad too early

Mitigation:
- support only `mcp_tool_manifest` first
- add new artifact types only after first use case is green

### Risk: Purchase and entitlement rules become unclear

Mitigation:
- purchase creates a durable `Purchase`
- acquisition requires purchase ownership
- acquisition response includes entitlement metadata

### Risk: Docs drift again

Mitigation:
- every phase has documentation exit criteria
- current docs must identify transitional hosted-execution behavior

## Non-Goals For First Slice

Not included:
- on-chain settlement
- cryptographic proof systems
- remote skill runtime
- buyer-side execution reporting
- automatic slashing
- human dispute workflow UI
- rich reputation scoring
- multi-artifact packages
- artifact file upload UI
- SDK generation

## Quality Bar

Code quality requirements:
- explicit service objects for verification, purchase, and acquisition
- no hidden runtime execution in acquisition services
- transactional money movement
- model validations for all important invariants
- request tests for public API/MCP behavior
- E2E test for the primary flow

Documentation requirements:
- no ambiguous “execute on SkillLedger” language in canonical docs
- clear distinction between verified artifact delivery and local execution
- clear explanation of what MVP verification does and does not prove

## E2E Contract Gate

The skipped E2E test at `test/e2e/verified_skill_acquisition_e2e_test.rb` is the product contract for the first slice.

It can be unskipped only after:
- sample verified skill data exists
- `skills/list` returns verified public versions
- `skills/purchase` is retry safe
- `skills/acquire` returns artifact and entitlement metadata
- acquire does not execute, charge, or create ledger entries

Validation command:

```bash
RAILS_ENV=test PARALLEL_WORKERS=1 bundle exec rails test test/e2e/verified_skill_acquisition_e2e_test.rb
```

## Immediate Next Task

Start with Step 1:

> Add `SkillVersion`, `SkillArtifact`, `SkillVerification`, and `Purchase` with tests.

Do not start by modifying MCP. The protocol should sit on top of the corrected domain model.
