# SkillLedger Next-Level Plan

**Date:** 2026-06-12  
**Status:** Proposed active roadmap  
**Source of truth:** Current README and `documentation/` product model

## Executive Summary

SkillLedger has a credible MVP foundation: a Rails API for publishing, verifying, listing, purchasing, and locally acquiring agent skill artifacts. The next level is not another broad feature sprint. It is a trust, packaging, and developer-experience sprint that turns the project from a working marketplace prototype into a dependable skill distribution layer.

The current product direction should remain:

- SkillLedger distributes verified skill artifacts.
- Buyers acquire artifacts for local execution.
- SkillLedger does not execute third-party code on hosted infrastructure.
- MCP should become the primary agent-facing contract.
- REST should remain useful for compatibility, administration, and human-operated tooling.

The highest-leverage next work is:

1. make local and CI validation frictionless
2. harden authentication, artifact verification, and purchase integrity
3. formalize the skill package format
4. improve MCP and client developer experience
5. validate which marketplace direction users actually want before adding large product surfaces

## Current Assessment

### What Is Strong

- The domain boundary is clear: marketplace and entitlement layer, not hosted runtime.
- Controllers, services, and models are separated well.
- Public docs in `documentation/` are coherent and current.
- The codebase has meaningful Minitest coverage across controllers, services, models, and end-to-end flows.
- REST and MCP flows both exist for the core marketplace lifecycle.
- Docker Compose provides a PostgreSQL-backed development path.
- The repository has contributor, security, support, changelog, and OpenAPI artifacts in place.

### What Needs Attention

- API keys are stored as raw bearer secrets.
- Artifact verification checks manifest consistency, not supply-chain trust or runtime safety.
- Purchase accounting should be hardened for concurrent requests and future refund/revocation flows.
- Slug creation should handle collisions gracefully.
- Some historical roadmap files still describe older hosted-execution ideas; those should remain historical and should not guide current implementation.
- Local validation can fail in non-interactive shells unless the Ruby manager shims are on `PATH`.
- Rails parallel tests may fail in sandboxed environments; serial test mode should be documented for agents and CI-like local runs.

## Roadmap Principles

1. **Preserve the acquisition model.** Do not reintroduce hosted skill execution unless there is an explicit product decision to pivot.
2. **Prefer trust primitives over marketplace decoration.** A skill marketplace wins if buyers trust what they acquire.
3. **Keep MCP agent-native.** New buyer and publisher workflows should be designed MCP-first, then mirrored in REST where useful.
4. **Make every financial state auditable.** Balances, purchases, refunds, revocations, and entitlements should be reconstructable from ledger events.
5. **Validate before expanding.** Features like referrals, activity feeds, and richer social surfaces should follow evidence, not hope.
6. **Keep changes small and reviewable.** Each phase below can be delivered as independent PR-sized slices.

## Phase 0: Baseline And Tooling

**Goal:** Make the project easy to validate reliably from local shells, Codex, Docker, and CI.

### Work Items

- Document the recommended local command prefix for rbenv-backed shells:
  - `PATH="$HOME/.rbenv/shims:$PATH"`
- Document serial test mode for sandboxed or SQLite-sensitive environments:
  - `PARALLEL_WORKERS=1 bin/rails test`
- Add a short troubleshooting section to `documentation/development.md`.
- Consider adding a `bin/local-test` wrapper that sets safe defaults without hiding the underlying Rails commands.
- Ensure `bin/ci` runs tests, not only setup, style, and security checks.
- Add an OpenAPI validation step to CI.
- Update stale references in active docs if they imply hosted execution.

### Acceptance Criteria

- A contributor can run the full test suite with one documented command.
- `bin/ci` is the obvious pre-merge command.
- CI catches test failures, style failures, security warnings, and OpenAPI drift.
- Historical hosted-execution roadmap docs are clearly labeled as historical.

### Suggested Validation

- `PATH="$HOME/.rbenv/shims:$PATH" PARALLEL_WORKERS=1 bin/rails test`
- `PATH="$HOME/.rbenv/shims:$PATH" bin/rubocop`
- `PATH="$HOME/.rbenv/shims:$PATH" bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`
- `PATH="$HOME/.rbenv/shims:$PATH" bin/bundler-audit`
- `git diff --check`

## Phase 1: Authentication And Account Hardening

**Goal:** Make API-key authentication safer before the project handles broader usage.

### Work Items

- Replace raw API-key storage with digest storage.
- Show plaintext API keys only once at creation or rotation time.
- Add API-key rotation.
- Add `last_used_at` and optionally `last_used_ip` metadata.
- Add account status values such as `active`, `suspended`, and `disabled`.
- Add tests for invalid, rotated, disabled, and suspended keys.
- Update `README.md`, `documentation/security-model.md`, and `openapi.yaml` if request or response shapes change.

### Acceptance Criteria

- Database compromise does not directly expose usable API keys.
- Existing authentication behavior is preserved from the client's perspective.
- A compromised key can be rotated without deleting the account.
- Suspended or disabled accounts cannot publish, purchase, or acquire artifacts.

### Risks

- Seed data and tests currently depend on fixture API keys.
- Migration needs a careful transition path if existing installations matter.

## Phase 2: Purchase And Ledger Integrity

**Goal:** Make financial and entitlement state robust enough for concurrent use and future refund/revocation workflows.

### Work Items

- Lock buyer and author account rows during purchase.
- Make purchase idempotency explicit.
- Add an optional idempotency key for purchase requests.
- Add tests for duplicate purchase calls.
- Add tests for concurrent purchase attempts where feasible.
- Introduce service-level ledger helpers for credit, debit, refund, and revoke events.
- Add ledger reconciliation checks that compare account balances to ledger history.
- Define refund and revocation behavior even if public endpoints come later.
- Add admin/internal documentation for balance reconciliation.

### Acceptance Criteria

- Duplicate paid purchases cannot double-charge a buyer.
- Purchase state can be explained through ledger entries.
- Refund and revocation can be added without rewriting the purchase model.
- Balance drift can be detected with a testable reconciliation routine.

### Risks

- SQLite and PostgreSQL locking behavior differ; test design should account for both.
- Existing ledger entries may not be rich enough for all future audit needs.

## Phase 3: Artifact Verification And Package Format

**Goal:** Move from "manifest is internally consistent" to "artifact package is structured, constrained, and ready for stronger trust."

### Work Items

- Define a formal manifest schema version.
- Validate semantic versions explicitly.
- Validate `input_schema` and `output_schema` as JSON Schema objects.
- Add artifact size limits.
- Add bundled file count and per-file size limits.
- Reject unsafe or ambiguous bundled file paths:
  - absolute paths
  - parent traversal
  - empty path segments
  - duplicate paths
- Add allowed media-type rules.
- Add package examples in `documentation/`.
- Add machine-readable manifest schema in the repo.
- Add tests for every verification failure path.

### Acceptance Criteria

- A publisher can see exactly why a package was rejected.
- Artifact manifests have a stable, versioned contract.
- SkillLedger can safely store and return bundled files without path ambiguity.
- Future signing and external artifact storage can build on the same package model.

### Risks

- Tightening validation may reject packages that passed under MVP rules.
- Documentation and fixtures must evolve together.

## Phase 4: Signed Artifacts And Supply-Chain Trust

**Goal:** Add cryptographic trust metadata without claiming to prove runtime safety.

### Work Items

- Add publisher signing-key records.
- Add artifact signature fields.
- Sign canonical manifest checksums.
- Store signature algorithm and key fingerprint.
- Add verification checks for known publisher key and valid signature.
- Add key rotation and revocation model.
- Add trust status fields to public skill/version responses.
- Document exactly what signatures prove and do not prove.

### Acceptance Criteria

- Buyers can distinguish unsigned, signed, and signature-invalid artifacts.
- A signature binds a publisher identity to a specific artifact checksum.
- Verification language remains honest: signatures prove origin/integrity, not safety.

### Risks

- Poorly designed key management can create false confidence.
- This phase should not block basic local marketplace experiments if market validation is still pending.

## Phase 5: MCP-First Developer Experience

**Goal:** Make the agent-facing workflow easy enough that another developer can integrate in under 30 minutes.

### Work Items

- Add MCP discovery/help methods.
- Add schema examples for every MCP method.
- Add MCP contract tests.
- Ensure REST and MCP success/failure behavior stay aligned.
- Add a minimal CLI or script that demonstrates:
  - create skill
  - publish version
  - list marketplace
  - purchase skill
  - acquire artifact
- Add copy-pasteable examples to `documentation/mcp-api.md`.
- Add a fixture-backed "golden path" package example.

### Acceptance Criteria

- A developer can publish and acquire a skill from a clean checkout using documented commands.
- MCP error responses are predictable and documented.
- Agents can inspect available methods and expected params.
- The demo flow becomes the project's primary smoke test.

### Risks

- Adding too much SDK surface too early can freeze the wrong contract.
- Keep the first client helper thin and close to HTTP/JSON-RPC.

## Phase 6: Marketplace Discovery

**Goal:** Improve useful discovery without distracting from trust and acquisition.

### Work Items

- Add categories and tags.
- Add compatibility metadata:
  - supported agent clients
  - runtime expectations
  - required permissions
  - supported platforms
- Add richer search and filtering.
- Add author profile fields.
- Add version history endpoints.
- Add verified-version filters to REST and MCP list methods.
- Add public examples that show how buyers evaluate a package before purchase.

### Acceptance Criteria

- Buyers can find skills by purpose, compatibility, and trust status.
- Authors can explain what their skill requires.
- Listing responses remain compact enough for agents to consume efficiently.

### Risks

- Discovery data can become noisy if not validated.
- Avoid building social marketplace features before demand is proven.

## Phase 7: Reviews, Refunds, And Revocations

**Goal:** Add feedback and lifecycle controls that match local acquisition.

### Work Items

- Add reviews only for purchased or acquired versions.
- Store reviews against skill versions, not just skill listings.
- Add entitlement revocation model.
- Add refund service and ledger entries.
- Add author-visible purchase and refund analytics.
- Add buyer-visible entitlement status.
- Document revocation limits: SkillLedger can revoke future acquisition rights, but cannot erase already downloaded local artifacts.

### Acceptance Criteria

- Reviews correspond to actual buyer experience.
- Refunds and revocations are auditable.
- Public documentation is clear about the limits of local artifact control.

### Risks

- Revocation semantics are easy to overpromise.
- Refund rules should be policy-driven before adding public endpoints.

## Phase 8: Deployment And Operations

**Goal:** Make staging and small production deployments repeatable.

### Work Items

- Add staging deployment checklist.
- Add environment variable reference.
- Add backup and restore procedure.
- Add database migration rollback guidance.
- Add structured security event logging.
- Add request rate limiting.
- Add health checks for database and queue dependencies.
- Add operational runbooks for:
  - leaked API key
  - bad artifact published
  - ledger mismatch
  - failed deploy
  - database restore

### Acceptance Criteria

- A maintainer can deploy and roll back with documented steps.
- Security-sensitive incidents have predefined response steps.
- Backups are tested, not just configured.

### Risks

- Production hardening can sprawl; keep the target to small, real deployments first.

## Phase 9: Product Validation

**Goal:** Decide what SkillLedger should become before committing to expensive marketplace features.

### Questions To Validate

- Do agent developers want a public marketplace or a private/team registry first?
- Is verified packaging more valuable than payment handling?
- Will buyers pay for acquired skill artifacts, or do they expect free/open distribution?
- Which package categories are compelling enough to publish first?
- Is MCP the right primary integration surface for the target users?
- Does local acquisition create enough trust, or do users expect sandboxing/scanning?

### Experiments

- Interview 5-10 agent developers.
- Run a 30-minute integration test with 3 developers using only docs and the demo flow.
- Publish 3 realistic example skills and observe which one users understand fastest.
- Test pricing language:
  - paid marketplace
  - verified registry
  - private skill catalog
  - entitlement ledger
- Ask whether users prefer:
  - public marketplace
  - private team registry
  - open-source package index
  - compliance/audit layer

### Decision Gate

After validation, choose one primary direction:

- **Trust registry:** focus on signatures, provenance, audit, private registries.
- **Marketplace:** focus on search, reviews, payments, refunds, author tools.
- **SDK/distribution layer:** focus on package format, CLI, MCP clients, framework integrations.
- **Enterprise entitlement layer:** focus on orgs, roles, policy, audit exports, private catalogs.

Do not build all four at once.

## Suggested First Sprint

This is the recommended first implementation slice because it reduces risk without forcing a premature product bet.

### Sprint Goal

Make SkillLedger safer to run, easier to validate, and clearer for contributors.

### Scope

- Add documented local validation commands for rbenv and serial tests.
- Update `bin/ci` to include the Rails test suite.
- Fix slug collision handling.
- Harden purchase locking/idempotency.
- Add manifest path and size validation.
- Add tests for the new hardening behavior.
- Update docs and OpenAPI where public behavior changes.

### Out Of Scope

- Hosted skill execution.
- Real-money payment rails.
- Blockchain settlement.
- Social feed.
- Referral system.
- Full SDK.
- TEE or sandboxed execution.

### Done Means

- Tests pass locally.
- `bin/ci` passes or documented environment limitations are captured.
- Docs match current behavior.
- No new hosted-execution language appears in active docs.
- The final handoff names skipped checks and residual risks.

## Tracking Checklist

- [ ] Phase 0: Baseline and tooling
- [ ] Phase 1: Authentication and account hardening
- [ ] Phase 2: Purchase and ledger integrity
- [ ] Phase 3: Artifact verification and package format
- [ ] Phase 4: Signed artifacts and supply-chain trust
- [ ] Phase 5: MCP-first developer experience
- [ ] Phase 6: Marketplace discovery
- [ ] Phase 7: Reviews, refunds, and revocations
- [ ] Phase 8: Deployment and operations
- [ ] Phase 9: Product validation decision

## Validation Notes From Review

The project test suite passes when run with the installed rbenv Ruby and serial workers:

```bash
PATH="$HOME/.rbenv/shims:$PATH" PARALLEL_WORKERS=1 bin/rails test
```

Observed result:

```text
201 runs, 849 assertions, 0 failures, 0 errors, 0 skips
```

The default non-interactive Codex shell used `/usr/bin/ruby` until rbenv shims were added to `PATH`. Parallel Rails tests also attempted to use a DRb Unix socket that was blocked by the sandbox, so `PARALLEL_WORKERS=1` is the right validation mode for this environment.
