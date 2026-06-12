# MCP-First Migration Plan

## Objective

Make SkillLedger **MCP-first** end to end.

That means an agent should be able to complete the full publisher and buyer lifecycle through MCP without depending on REST as the primary product contract.

## Why This Matters

Today the product is only partially MCP-first:

- buyer-side discovery, purchase, and acquire already exist in MCP
- publisher-side creation and version upload are still primarily REST-driven
- several docs and contracts still describe REST as the canonical surface

This creates a split product shape:

- agents buy through MCP
- authors publish through REST

That is workable for now, but it is not the long-term product we want.

## Target End State

The primary contract for agent clients should be MCP.

### Canonical MCP Flows

#### Publisher flow

1. Create skill listing
2. Upload new version with artifact bundle
3. Trigger or receive verification result
4. Inspect owned skills and versions
5. Update listing state
6. Retire or supersede old versions

#### Buyer flow

1. Discover listed verified skills
2. Inspect skill and version details
3. Purchase a version
4. Acquire the artifact bundle and entitlement
5. Optionally submit usage receipts, feedback, or disputes later

### Role Of REST After Migration

REST should become:

- a secondary compatibility/admin surface
- a human/operator integration surface
- no longer the primary product protocol for agent workflows

## Design Principles

1. MCP is the canonical agent contract.
2. REST mirrors MCP where useful, but should not lead product design.
3. Every artifact change creates a new version.
4. Every uploaded version must be verified independently.
5. SkillLedger delivers artifacts and verification metadata, not hosted execution.
6. Migration should be incremental and keep existing buyer MCP flows stable.

## Current State

### Already MCP-backed

- `skills/list`
- `skills/get`
- `skills/purchase`
- `skills/acquire`

### Still not MCP-first enough

- skill creation is REST-first
- version upload is REST-first
- publisher ownership views are missing from MCP
- listing lifecycle controls are missing from MCP
- verification is an internal service, not a full publisher protocol
- docs still present REST and MCP as mixed-primary

## Proposed MCP Surface

## Phase 1: Publisher Parity

Goal: achieve feature parity for the core publisher lifecycle.

### New MCP methods

- `skills/create`
- `skills/version.publish`
- `skills/version.get`
- `skills/mine.list`

### Responsibilities

#### `skills/create`

- create a skill listing owned by the authenticated account
- accept `name`, `description`, `price`
- optionally accept initial listing status

#### `skills/version.publish`

- create a new `SkillVersion`
- accept `version`, `changelog`, `artifact_type`, and `manifest`
- compute checksum server-side
- store artifact bundle
- immediately trigger verification
- return version status plus verification result

#### `skills/version.get`

- return version metadata, artifact summary, checksum, and verification status
- support author-side inspection of rejected versions

#### `skills/mine.list`

- list the authenticated author's skills
- include versions, latest verification state, listing status, and purchase summary

### REST status after Phase 1

- keep `POST /api/v1/skills`
- keep `POST /api/v1/skills/:id/versions`
- mark them as compatibility endpoints
- document MCP as preferred for agent publishers

## Phase 2: Listing Lifecycle Control

Goal: move operational listing control into MCP.

### New MCP methods

- `skills/update`
- `skills/listing.set_status`
- `skills/version.retire`

### Responsibilities

#### `skills/update`

- edit mutable listing metadata like name, description, and price
- preserve immutable publication history per version

#### `skills/listing.set_status`

- change listing state among `draft`, `listed`, and `suspended`
- enforce that only verified versions are publicly buyable

#### `skills/version.retire`

- retire an old version without deleting purchase history
- preserve previously acquired artifacts for existing buyers

## Phase 3: Protocol Hardening

Goal: make MCP robust enough to be the real production contract.

### Needed improvements

- idempotency for publisher writes
- explicit error codes for verification and authorization failures
- version conflict behavior for duplicate version strings
- request and response schemas documented per MCP method
- structured verification failure reasons
- stable acquisition and entitlement payloads

### Recommended additions

- `request_id` / idempotency handling on mutating methods
- normalized machine-readable error shapes
- explicit method versioning if payloads evolve materially

## Phase 4: Documentation Canonicalization

Goal: make docs reflect MCP-first reality.

### Required doc changes

- README: present MCP as the default agent interface
- API docs: split MCP reference from secondary REST compatibility reference
- architecture docs: name MCP as the primary protocol layer
- roadmap docs: treat REST-first flow as transitional history
- OpenAPI: either demote its role or pair it with an MCP method reference

## Phase 5: Optional Later MCP Expansion

These are not needed to call the platform MCP-first, but are logical next steps.

- `purchases/get`
- `purchases/mine.list`
- `receipts/submit`
- `reviews/create`
- `disputes/create`
- `authors/reputation.get`

## Data Model Implications

The current model is already close enough for the migration:

- `Skill`
- `SkillVersion`
- `SkillArtifact`
- `SkillVerification`
- `Purchase`

The main change is not the model. It is which protocol is treated as canonical for writing and reading that model.

## Implementation Sequence

1. Add publisher MCP methods on top of the current services and models.
2. Reuse existing REST-backed services where possible instead of duplicating logic.
3. Add MCP request tests for every new publisher method.
4. Update docs to declare MCP preferred for agent clients.
5. Demote REST docs and endpoints to compatibility status.
6. Only later decide whether some REST endpoints should be removed entirely.

## Acceptance Criteria

SkillLedger can be called MCP-first when all of the following are true:

1. An author can create a skill listing through MCP.
2. An author can publish a new version with bundled files through MCP.
3. Verification runs automatically and returns structured results through MCP.
4. An author can inspect their own listings and versions through MCP.
5. A buyer can discover, purchase, and acquire through MCP.
6. The README and API docs describe MCP as the primary contract.
7. REST remains optional rather than required for normal agent workflows.

## Risks

### 1. Contract duplication

If REST and MCP evolve separately, behavior will drift.

Mitigation:
- keep shared service-layer business logic
- test both surfaces against the same rules

### 2. Overloading one generic MCP endpoint

`POST /api/v1/mcp` can become hard to reason about if payloads are loosely defined.

Mitigation:
- define strict method schemas
- keep method names narrow and domain-specific

### 3. Premature REST deletion

Removing REST too early would make debugging and human ops harder.

Mitigation:
- demote first
- remove only after MCP maturity is proven

## Recommended Next Implementation Slice

The best next slice is:

> Add publisher MCP parity for `skills/create`, `skills/version.publish`, and `skills/mine.list`.

Why this slice:

- it completes the basic author workflow
- it builds directly on the version-upload code already in place
- it is the smallest meaningful step that changes the product from MCP-supported toward MCP-first

## Open Questions

1. Should MCP publishing support draft versions, or always publish-and-verify in one step?
2. Should authors be able to upload large bundles inline forever, or do we eventually need external artifact storage with signed references?
3. Do we want separate MCP methods for verification trigger vs verification result lookup, or is synchronous verification enough for MVP?
4. At what point do we mark REST publication endpoints as deprecated in docs?
