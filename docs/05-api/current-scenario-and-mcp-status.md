# Current Scenario And MCP Status

**Date:** 2026-06-10  
**Status:** acquisition refactor slice implemented

## Covered Now

### 1. Verified skill discovery

Implemented:
- `skills/list`
- `skills/get`

Behavior:
- only `listed` skills with verified versions are publicly discoverable
- clients receive version metadata, artifact type, checksum summary, and verification status

### 2. Verified skill purchase

Implemented:
- `skills/purchase`

Behavior:
- buyer cannot purchase their own skill
- unverified versions are rejected
- insufficient balance is rejected
- a paid purchase is durable
- repeating the same purchase returns the existing paid purchase instead of charging again

### 3. Verified artifact acquisition

Implemented:
- `skills/acquire`

Behavior:
- only the purchase owner can acquire
- response includes artifact manifest, checksum, verification metadata, and entitlement
- acquisition sets `acquired_at`
- acquisition does not create `Execution`
- acquisition does not move funds
- acquisition does not return hosted execution output

### 4. Publication verification

Implemented:
- `SkillArtifactVerificationService`

Checks:
- supported artifact type
- manifest object validity
- required fields present
- `runtime == client`
- version matches `SkillVersion`
- checksum matches canonical manifest JSON

## MCP We Have Now

Endpoint:
- `POST /api/v1/mcp`

Current acquisition methods:
- `skills/list`
- `skills/get`
- `skills/purchase`
- `skills/acquire`

## What The Product Does Not Do

Not implemented:
- execute acquired skills on SkillLedger
- observe buyer-side runtime behavior
- automatically slash authors based on local buyer execution
- provide dispute workflow or evidence review
- provide artifact downloads outside database-backed manifest storage

## Useful State Today

The product is now useful for a narrow but real workflow:

1. an author publishes a client-side MCP-style skill artifact
2. the platform verifies the manifest and integrity metadata
3. a buyer agent discovers the verified listing
4. the buyer purchases once
5. the buyer acquires the verified artifact and executes it locally

## Still Missing

### Protocol

- purchase idempotency keys
- richer version negotiation
- artifact transport beyond manifest-in-database
- signed receipts or attestation payloads

### Product

- dispute/report flow
- reputation/accountability workflow beyond auditable purchase history
- deprecation plan for hosted execution
