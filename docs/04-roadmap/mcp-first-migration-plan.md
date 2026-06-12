# MCP-First Migration Plan

**Status:** implementation plan, not yet complete
**Last updated:** 2026-06-12
**Critical path:** publisher MCP parity, protocol contract hardening, documentation canonicalization

## Objective

Make SkillLedger MCP-first for normal agent workflows.

That means an agent should be able to complete the full publisher and buyer lifecycle through MCP without depending on REST as the primary product contract.

MCP-first does not mean REST disappears. It means REST stops leading the product shape.

## Critical Review

The current direction is right, but the plan is not done until these uncomfortable details are designed and tested:

1. **MCP is currently a thin JSON-RPC endpoint, not a fully specified contract.** Method names exist for buyer acquisition, but request/response schemas, error codes, compatibility rules, and idempotency semantics are not documented strongly enough for external agent clients.
2. **Publisher writes are the riskiest gap.** Creating listings and publishing versions changes money-facing inventory. Those flows need authorization, duplicate-version behavior, replay safety, and ownership visibility from day one.
3. **Artifact transport is under-specified.** Manifest-in-database is fine for MVP, but "bundle upload" can mean inline JSON, file archive, signed URL, checksum-only reference, or external object storage. The plan must name the MVP transport and the later migration path.
4. **Verification timing cannot stay implicit.** Synchronous verification is convenient for tests, but real verification may become async. MCP responses must distinguish accepted, verifying, verified, and rejected outcomes without forcing clients to guess.
5. **REST deprecation is documentation-sensitive.** REST should be demoted only after MCP covers the workflow and docs accurately show REST as compatibility/admin. Claiming MCP-first too early will make the product story look stronger than the contract.
6. **The roadmap still contains hosted-execution history.** That history is useful, but public-facing docs need to clearly separate history from the current acquisition model.

## Current State

### Already MCP-backed

- `skills/list`
- `skills/get`
- `skills/purchase`
- `skills/acquire`

These methods support the buyer acquisition flow:

1. Discover listed verified skills.
2. Inspect skill and version details.
3. Purchase a verified version.
4. Acquire the artifact and entitlement metadata for local execution.

### Still REST-first or internal

- skill listing creation
- version publication
- artifact registration
- author-owned listing/version inspection
- listing lifecycle changes
- verification result lookup for authors
- protocol-level schema and error documentation

## Target End State

The primary contract for agent clients should be MCP.

### Canonical Publisher Flow

1. Create a skill listing.
2. Publish a new immutable version with an artifact manifest.
3. Receive or poll for verification status.
4. Inspect owned skills and versions.
5. Update mutable listing metadata.
6. Change listing status.
7. Retire or supersede old versions without deleting buyer history.

### Canonical Buyer Flow

1. Discover listed verified skills.
2. Inspect skill and version details.
3. Purchase a version once.
4. Acquire the artifact bundle and entitlement.
5. Later: submit usage receipts, feedback, reports, or disputes.

### REST After Migration

REST should become:

- a compatibility surface for existing clients
- an admin/operator integration surface
- a debugging and human workflow surface

REST should not be required for normal publisher or buyer agent workflows.

## Non-Goals

- Do not reintroduce hosted execution as the primary product model.
- Do not delete REST endpoints during the MCP parity work.
- Do not add dispute, review, or reputation flows before the core publish/acquire contract is stable.
- Do not design generic arbitrary tool execution through SkillLedger.

## Design Principles

1. MCP is the canonical agent contract.
2. REST may mirror MCP behavior, but shared service-layer logic owns business rules.
3. Every artifact change creates a new immutable version.
4. Every uploaded version must be verified independently before public discovery.
5. SkillLedger delivers artifacts, provenance, entitlements, and verification metadata, not hosted execution output.
6. Mutating MCP methods must be retry-safe or explicitly documented as non-idempotent.
7. MCP responses must be structured enough for agents to handle success, rejection, authorization failure, validation failure, and temporary verification states.

## Proposed MCP Surface

### Existing Buyer Methods

| Method | Status | Notes |
|--------|--------|-------|
| `skills/list` | implemented | Public discovery of listed skills with verified versions. |
| `skills/get` | implemented | Public detail for a listed verified version. |
| `skills/purchase` | implemented | Purchase is currently retry-safe for the same buyer/version pair. |
| `skills/acquire` | implemented | Returns artifact manifest, checksum, verification metadata, and entitlement. |

### Phase 1: Publisher Read + Create Parity

Goal: make authors able to create and inspect their MCP-side inventory without REST.

New MCP methods:

- `skills/create`
- `skills/mine.list`
- `skills/version.get`

Responsibilities:

- `skills/create` creates a skill listing owned by the authenticated account.
- `skills/create` accepts `name`, `description`, `price`, and optional initial `listing_status`.
- `skills/create` defaults new listings to `draft` unless a verified version is created in the same future flow.
- `skills/mine.list` returns the authenticated author's skills, listing status, versions, latest verification state, and purchase summary.
- `skills/version.get` returns author-visible version metadata, artifact summary, checksum, verification status, and rejection reasons.

Why this comes first:

- It is low transport risk because it does not require large artifact payload design.
- It gives author agents a MCP-native control plane.
- It exposes rejected versions, which public buyer methods intentionally hide.

Phase 1 acceptance:

- An author can create a draft listing through MCP.
- An author can list only their own listings through MCP.
- An author can inspect verified and rejected versions they own through MCP.
- Buyer MCP behavior remains unchanged.

### Phase 2: Version Publication

Goal: make the core publisher release workflow MCP-native.

New MCP method:

- `skills/version.publish`

MVP payload decision:

- Accept an inline JSON manifest only.
- Support only `artifact_type: "mcp_tool_manifest"` for now.
- Compute checksum server-side from canonical manifest JSON.
- Reject payloads above a documented size limit.
- Defer archive uploads, signed URLs, and external object storage to a later artifact transport phase.

Responsibilities:

- Create a new immutable `SkillVersion`.
- Store the artifact manifest and server-computed checksum.
- Trigger verification immediately.
- Return `version`, `artifact`, and `verification` objects.
- Reject duplicate version strings for the same skill with a stable error shape.
- Require an idempotency key or equivalent replay rule before external clients depend on the method.

Verification response semantics:

- `verified`: artifact passed checks and can become publicly discoverable when listing state allows it.
- `rejected`: artifact failed checks; response includes structured failure reasons.
- `verifying`: accepted for async verification; caller must poll `skills/version.get`.

Phase 2 acceptance:

- An author can publish a new version with an inline manifest through MCP.
- Duplicate publish attempts do not create ambiguous versions.
- Verification result is visible through MCP.
- Public buyers can discover the version only when the listing is `listed` and the version is verified.

### Phase 3: Listing Lifecycle Control

Goal: move operational listing control into MCP.

New MCP methods:

- `skills/update`
- `skills/listing.set_status`
- `skills/version.retire`

Responsibilities:

- `skills/update` edits mutable listing metadata such as `name`, `description`, and `price`.
- `skills/listing.set_status` changes listing state among `draft`, `listed`, and `suspended`.
- `skills/listing.set_status` enforces that a listing cannot become publicly buyable without at least one verified version.
- `skills/version.retire` hides an old version from new purchases without deleting purchase history or acquired artifacts.

Phase 3 acceptance:

- Authors can manage listing state through MCP.
- Retired versions remain available to buyers who already acquired them.
- Public discovery never returns draft, suspended, rejected, or retired inventory.

### Phase 4: Protocol Hardening

Goal: make MCP robust enough to be the production contract.

Required work:

- request and response schemas for every MCP method
- method-level authorization rules
- idempotency semantics for every mutating method
- stable machine-readable error codes
- structured verification failure reasons
- explicit duplicate version conflict behavior
- pagination for list methods
- response compatibility/versioning policy
- end-to-end MCP contract tests for publisher and buyer workflows

Recommended error shape:

```json
{
  "code": -32000,
  "message": "Version already exists",
  "data": {
    "error": "version_conflict",
    "field": "version",
    "retryable": false
  }
}
```

### Phase 5: Documentation Canonicalization

Goal: make docs reflect MCP-first reality without overstating implementation status.

Required doc changes:

- README presents MCP as the default agent interface after publisher parity lands.
- API docs split MCP reference from secondary REST compatibility reference.
- Architecture docs name MCP as the primary protocol layer for agent workflows.
- Roadmap docs mark hosted execution and REST-first publication as historical/transitional.
- OpenAPI is described as the REST compatibility reference, not the full product contract.
- MCP method reference documents examples, schemas, errors, auth, and idempotency.

Documentation acceptance:

- A new agent developer can complete the publish and acquire workflow using MCP docs only.
- REST docs clearly say when an endpoint is compatibility/admin rather than canonical.
- No public doc implies SkillLedger executes acquired skills on behalf of buyers.

### Phase 6: Later MCP Expansion

These are not required to call the platform MCP-first, but they are natural extensions:

- `skills/versions.list`
- `purchases/get`
- `purchases/mine.list`
- `receipts/submit`
- `reviews/create`
- `reports/create`
- `disputes/create`
- `authors/reputation.get`

## Data Model Implications

The current model is close enough for MCP-first parity:

- `Skill`
- `SkillVersion`
- `SkillArtifact`
- `SkillVerification`
- `Purchase`

Likely follow-up model or schema needs:

- idempotency records for mutating MCP requests
- explicit retired/superseded version state
- artifact size and storage location fields if manifests move beyond inline JSON
- structured verification failure codes instead of only human-readable failure text

The main migration is not a table rewrite. It is making MCP the contract that writes and reads the domain model.

## Recommended Implementation Sequence

1. Add `skills/create`, `skills/mine.list`, and `skills/version.get`.
2. Add service-level authorization and MCP request tests for author-owned reads and writes.
3. Add `skills/version.publish` using inline manifest transport only.
4. Add duplicate-version and retry behavior before documenting publisher MCP as external-ready.
5. Add lifecycle controls: `skills/update`, `skills/listing.set_status`, and `skills/version.retire`.
6. Write the MCP method reference with schemas, examples, errors, and idempotency rules.
7. Demote REST publication docs to compatibility/admin status.

## Definition Of MCP-First

SkillLedger can be called MCP-first only when all of the following are true:

1. An author can create a skill listing through MCP.
2. An author can publish a new version with an artifact manifest through MCP.
3. Verification runs automatically or asynchronously with clear MCP-visible status.
4. An author can inspect their own listings, versions, and verification failures through MCP.
5. An author can manage listing status through MCP.
6. A buyer can discover, purchase, and acquire through MCP.
7. Mutating MCP methods have documented idempotency or replay behavior.
8. MCP methods have documented request schemas, response schemas, errors, and auth rules.
9. README and API docs describe MCP as the primary agent contract.
10. REST remains optional for normal agent workflows.

## Risks And Mitigations

### 1. Contract Drift Between REST And MCP

If REST controllers and MCP handlers evolve independently, behavior will drift.

Mitigation:
- keep business rules in shared services
- test REST and MCP against the same domain expectations where both surfaces exist
- avoid copying validation logic into protocol handlers

### 2. Loose JSON-RPC Payloads

`POST /api/v1/mcp` can become hard to reason about if payloads are loosely defined.

Mitigation:
- define strict method schemas
- reject unknown fields on mutating methods once the contract is external
- keep method names narrow and domain-specific

### 3. Replay And Double-Write Bugs

Agent clients retry. Publisher writes can create duplicate listings or versions if retries are not handled deliberately.

Mitigation:
- require idempotency keys for mutating publisher methods
- define duplicate version conflict behavior
- make purchase and publication replay behavior part of the MCP reference

### 4. Artifact Transport Lock-In

Inline manifest storage is simple, but it will not handle larger bundles.

Mitigation:
- document inline manifest as the MVP transport
- add size limits now
- design a future signed-reference transport before supporting archives

### 5. Verification Latency

Synchronous verification works for deterministic manifest checks, but richer verification may take longer.

Mitigation:
- allow `verifying` as a first-class state
- make `skills/version.get` the polling path
- avoid promising that publication always returns a final verification result

### 6. Premature REST Deletion

Removing REST too early would make debugging, admin workflows, and compatibility harder.

Mitigation:
- demote REST in docs first
- keep REST backed by the same services
- remove only after MCP maturity is proven and clients have migrated

## Recommended Next Slice

Implement Phase 1:

> Add publisher MCP parity for `skills/create`, `skills/mine.list`, and `skills/version.get`.

This is the strongest next slice because:

- it gives author agents a MCP-native control plane
- it avoids prematurely solving large artifact upload transport
- it exposes rejected verification outcomes to authors
- it sets up `skills/version.publish` without making the first slice too wide

Do not start with lifecycle controls or docs-only demotion. Those are valuable after authors can actually use MCP for core publication inventory.

## Open Questions

1. What exact idempotency mechanism should mutating MCP methods use: explicit `idempotency_key`, JSON-RPC `id`, or a separate request fingerprint?
2. What inline manifest size limit should Phase 2 enforce?
3. Should `skills/create` ever create a `listed` skill, or should listing require at least one verified version first?
4. Should async verification be modeled now even if the current verifier is synchronous?
5. What is the first public MCP method reference format: Markdown table, JSON Schema files, or generated docs?
