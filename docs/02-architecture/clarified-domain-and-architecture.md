# Clarified Domain And Architecture

## Architectural Center Of Gravity

The system should be centered on **publication, verification, acquisition, and accountability**.

It should **not** be centered on hosted execution.

## Core Domain Model

### `Account`

Represents an agent author or buyer.

Responsibilities:
- identity
- balance
- stake
- purchase history
- publication ownership

### `Skill`

Represents the stable listing identity of a skill.

Responsibilities:
- display name
- author
- pricing
- listing state
- public metadata

### `SkillVersion`

Represents a versioned release of a skill.

Responsibilities:
- semantic version or revision ID
- changelog
- compatibility metadata
- links to artifacts and verification

### `SkillArtifact`

Represents the actual package that the buyer receives.

Possible forms:
- manifest JSON
- MCP tool definition
- prompt package
- workflow definition
- script bundle

Responsibilities:
- artifact location or stored body
- checksum
- package type
- size

### `SkillVerification`

Represents verification done before listing or release.

Responsibilities:
- verification status
- verification timestamp
- checks performed
- evidence or logs
- verifier identity or automated verifier metadata

### `Purchase`

Represents the economic acquisition event.

Responsibilities:
- buyer
- purchased skill version
- amount paid
- access or delivery status
- entitlement or acquisition token

### `LedgerEntry`

Represents financial movement and auditability.

Responsibilities:
- payment
- fees
- stake lock
- slash
- refund

### Optional Later Models

- `UsageReceipt`
- `Dispute`
- `Attestation`
- `AuthorReputation`

## Recommended Flow

### Publish flow

1. Author creates skill listing
2. Author uploads artifact and manifest
3. SkillLedger verifies the submission
4. On success, the version becomes publicly discoverable

### Acquire flow

1. Buyer discovers a skill version
2. Buyer inspects metadata and verification
3. Buyer purchases acquisition rights
4. SkillLedger records the ledger event
5. Buyer receives the artifact and proof metadata

### Execute flow

1. Buyer executes locally
2. SkillLedger is not the runtime
3. Optional later: buyer submits usage receipt, review, or dispute

## What To De-Emphasize In Current Code

The following concepts are likely transitional or wrong for the long-term model:
- hosted `Execution`
- `complete`
- `fail`
- escrow around our runtime decision
- built-in skills as primary product direction

## MCP Direction

The protocol surface should eventually look more like:
- `skills/list`
- `skills/get`
- `skills/versions/list`
- `skills/purchase`
- `skills/acquire`
- `skills/verify`

Possible later additions:
- `purchases/get`
- `receipts/submit`
- `disputes/create`

## Refactor Principle

Do not refactor toward “better hosted execution.”

Refactor toward:
- better artifact representation
- better verification representation
- better acquisition flows
- better agent-facing delivery protocols
