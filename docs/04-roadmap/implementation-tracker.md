# SkillLedger Implementation Tracker

**Status:** First client-side acquisition slice implemented  
**Date:** 2026-06-10  
**Owner:** Codex

## Goal

Refactor SkillLedger toward the clarified product:

> verify skill artifacts, sell them to buyer agents, and let buyers execute locally.

This tracker is the restartable log for the current refactor branch.

## Implemented In This Slice

### Scenario 1: Verified skill discovery

Covered now:
- `skills/list` returns only publicly listed, verified skill versions
- `skills/get` returns manifest summary, checksum, and verification metadata
- unverified versions are excluded from public discovery

### Scenario 2: Retry-safe purchase

Covered now:
- `skills/purchase` creates a durable `Purchase`
- buyer balance is debited once
- author balance is credited once
- one `skill_purchase` ledger entry is created
- retrying the same purchase returns the existing paid purchase without charging again

### Scenario 3: Artifact acquisition for local execution

Covered now:
- `skills/acquire` returns artifact payload, checksum, verification metadata, and entitlement
- acquisition sets `acquired_at`
- acquisition does not create `Execution`
- acquisition does not move money
- acquisition does not return hosted execution output

### Scenario 4: Publication verification

Covered now:
- `SkillArtifactVerificationService` verifies schema, runtime, version match, and checksum
- verification updates `SkillVerification`
- version status moves to `verified` or `rejected`

## Domain Added

- `Skill.slug`
- `Skill.listing_status`
- `SkillVersion`
- `SkillArtifact`
- `SkillVerification`
- `Purchase`

## MCP Status

### Current supported acquisition methods

- `skills/list`
- `skills/get`
- `skills/purchase`
- `skills/acquire`

### Legacy transitional methods still present

- `tools/list`
- `tools/call`

Reason:
- they preserve the old hosted-execution path during the refactor
- they should not be treated as the long-term primary product interface

## Tests Added

- model tests for new domain objects
- service tests for verification, purchase, and acquisition
- MCP request tests for the new acquisition methods
- end-to-end contract for verified skill acquisition

## Validation

Passing command:

```bash
RAILS_ENV=test PARALLEL_WORKERS=1 ~/.rbenv/versions/3.3.11/bin/bundle exec ~/.rbenv/versions/3.3.11/bin/ruby bin/rails test
```

Note:
- `PARALLEL_WORKERS=1` is now respected to avoid SQLite locking during local runs
- Bundler still prints local environment noise about `/Users/ghassan` not being writable, but the suite passes

## Remaining Work

### Product-facing

- remove or fully isolate the hosted-execution story from public documentation
- decide final naming migration away from `price_per_call` toward acquisition pricing
- define dispute/report flow before adding accountability claims beyond provenance and auditable purchase history

### Protocol-facing

- add idempotency keys to purchase requests if client-driven replay control is required
- decide whether `skills/get` should accept `slug` in addition to `skill_id`
- define package/download strategy if artifacts move out of database storage

### Domain-facing

- decide whether `Execution` should be archived, migrated, or removed in a later phase
- add explicit state transition guards if status changes become more complex

## Resume From Here

If work resumes later, start with:

1. remove hosted-execution language from the remaining public docs and API docs
2. decide whether to deprecate `tools/*` immediately or keep it behind a transitional flag
3. design the next useful acquisition artifact beyond the manifest-only MVP
