# SkillLedger v1 Research Synthesis

**Date:** 2026-06-19
**Source:** `~/ai-projects/projects/skill-ledger-deep-research/v1/`
**Status:** Current strategic research synthesis
**Supersedes:** Older IS-002 on-chain hosted-execution thesis

## Summary

The v1 research confirms that the product correction is directionally sound:

```text
Old thesis:
Hosted execution marketplace + on-chain escrow + agent wallets + runtime verification

v1 thesis:
Verified skill artifact registry + local execution + MCP-first acquisition + optional adapters
```

This materially reduces technical, regulatory, and market-timing risk. SkillLedger no longer depends on agents having wallets, TEE infrastructure, ZK proofs, or mature agent-to-agent payment behavior. The core product can work as a standard Rails-backed registry that verifies, distributes, and tracks acquisition of reusable agent skill artifacts.

The remaining risk is not mostly technical. It is whether developers and agent builders will value verified reusable skills enough to use SkillLedger instead of generating one-off code with an LLM or copying examples from existing package ecosystems.

## Core Findings

### v1 Is Stronger Than IS-002

The v1 direction is more executable because it keeps Rails as the source of truth, keeps local acquisition as the default execution model, and treats Web3 as optional proof or settlement infrastructure.

The old IS-002 framing required too many external conditions:

- mature agent wallets
- meaningful agent-to-agent commerce
- on-chain escrow adoption
- TEE or optimistic runtime verification
- crypto-native developer behavior

The v1 framing requires a narrower assumption:

> Developers and agents want reusable skill artifacts with clearer provenance, verification, and acquisition records than ad hoc LLM output.

That assumption is still unproven, but it is much easier to test.

### Verification Is Useful, But Not Sufficient

The v1 research defines a practical verification ladder:

```text
Level 1: Artifact integrity
- manifest validation
- canonical checksum
- runtime and version consistency

Level 2: Provenance and signing
- publisher identity
- artifact signatures
- key rotation and revocation

Level 3: Static safety
- explicit permission declarations
- suspicious pattern checks
- dependency and file-path inspection

Level 4: Test-backed validation
- examples and fixtures
- deterministic expected outputs
- test result records

Level 5: External proof
- third-party attestations
- external hash anchoring
- portable validation references
```

L1 and L2 are immediately feasible. L3 is feasible for bounded manifest-based artifacts. L4 is valuable but introduces sandboxed test-runner risk. L5 should remain optional and should never be the MVP center.

The important limitation:

> SkillLedger can verify what it published and distributed. It cannot guarantee that a locally executed skill is safe in every buyer environment.

That boundary should remain explicit in docs, API responses, and product messaging.

### Distribution May Matter More Than Verification

One of the strongest critiques in the v1 reviews is that npm, PyPI, Docker Hub, and GitHub Packages won primarily through distribution and convenience, not verification.

SkillLedger should not assume buyers will pay for verification alone. The product must also make skill discovery and acquisition easier than generating or reconstructing the same skill from scratch.

Practical implication:

- structured capability discovery matters
- MCP acquisition flow matters
- examples and golden-path packages matter
- buyer-side verification tooling matters
- frictionless first use matters

If SkillLedger is harder than asking an LLM for a solution, only high-stakes or edge-case-heavy skills will survive.

### LLM Competition Is The Main Market Threat

The real competitor is not only another marketplace. The real competitor is a buyer asking an LLM:

```text
"Write me a script that fixes this problem."
```

For simple skills, LLM-generated code will often be good enough and free. SkillLedger should therefore focus on skills where reuse has defensible value:

- high-stakes workflows
- repeated operational edge cases
- domain-specific compliance or safety requirements
- integrations with fragile external APIs
- skills with known failure modes and battle-tested fixes
- artifacts with tests, provenance, and compatibility metadata

Avoid building the catalog around trivial snippets. They will be commoditized quickly.

### MCP-First Is Correct, But Should Not Become Protocol Lock-In

The v1 research strengthens the MCP-first API direction. The agent-facing surface should prioritize:

- `skills/search`
- `skills/list`
- `skills/get`
- `skills/versions`
- `skills/purchase`
- `skills/acquire`
- future `skills/verify`
- future `reports/submit`
- future `disputes/create`

The purchase flow should remain idempotent by buyer and skill version, so agent retries do not double-charge.

The caveat is protocol fragmentation. MCP is a strong starting point, but SkillLedger should avoid tying the domain model too tightly to one protocol. The core domain should remain protocol-neutral; MCP should be the first adapter.

### ALMS Is Probably The Strongest Moat

The v1 research identifies the ALMS bridge as the most defensible path.

Without ALMS, skill creation depends on humans manually deciding what to package. With ALMS, useful lessons can be promoted from repeated real agent experience:

```text
Agent solves a problem
-> ALMS records the lesson
-> repeated use or human review marks it valuable
-> lesson is packaged as a skill artifact
-> SkillLedger verifies and distributes it
-> buyer feedback improves future ranking and packaging
```

Promotion criteria should include:

- lesson used more than three times
- pattern is reusable beyond one company
- solution has clear inputs and outputs
- expected behavior can be tested
- no existing skill covers the same problem
- sensitive data can be sanitized

This is more defensible than a public marketplace of manually authored skills because it creates a pipeline from actual operational learning to reusable artifacts.

### Enterprise Is Promising But Premature

The enterprise registry path is plausible:

- private catalogs
- approval workflows
- org-scoped entitlements
- publisher verification
- audit logs
- policy metadata
- compliance records

But enterprise should not become the primary build path before basic SaaS/community demand is tested. Enterprise sales cycles are long, category awareness is early, and the product would need stronger security posture before serious regulated buyers trust it.

The right stance:

> Serve enterprise-like needs lightly when they appear, but do not build a full enterprise sales motion until the core artifact and acquisition flow has live usage.

## Recommended Near-Term Test

The v1 research proposes a market test around anchor skills. The stricter version is better:

1. Build 10 anchor skills, not only 3.
2. Focus on edge-case-heavy, useful problems rather than trivial snippets.
3. Price some skills at different levels, such as `$0`, `$0.50`, `$1`, and `$5`.
4. For selected skills, compare verified artifacts against LLM-generated equivalents.
5. Track whether real users acquire verified skills when a free generated alternative exists.
6. Interview every buyer or publisher who completes a meaningful action.

Useful initial skill candidates:

- `normalize-dhl-tracking`
- `recover-telegram-polling-conflict`
- `repair-rails-migration-schema-drift`
- `validate-eu-ai-act-risk-summary`
- `normalize-webhook-payload`
- `check-ssl-certificate-expiry`
- `extract-contract-terms-from-pdf-text`

The test should answer:

> Is verified reuse compelling enough to beat free generation for real users?

## Kill And Adjust Criteria

The research should not become another analysis loop. The next decision should be driven by usage.

Possible criteria:

- If 10 anchor skills produce no external acquisitions, public marketplace demand is weak.
- If users browse but do not acquire, pricing or purchase friction is too high.
- If users acquire only free skills, distribution may matter but direct skill monetization may not.
- If users mainly ask for private catalogs, pivot toward enterprise registry and ALMS bridge.
- If users say LLM-generated alternatives are good enough, focus only on complex, high-stakes, edge-case-heavy skills.
- If ALMS-originated skills outperform hand-authored skills, make ALMS the strategic center.

## Implications For The Repo

Near-term implementation should prioritize:

1. richer artifact schema and permission declarations
2. detailed verification result records
3. structured capability tags and search
4. stable MCP purchase and acquire contracts
5. idempotent purchase behavior
6. buyer-side checksum/signature verification tooling
7. publisher identity and signing
8. usage reports and lightweight dispute records
9. anchor skill examples

Work to defer:

- on-chain escrow
- TEE or ZK verification
- wallet-first authentication
- hosted runtime execution
- automatic slashing
- full enterprise sales motion
- external proof anchoring before verification records stabilize

## Bottom Line

SkillLedger v1 is a stronger and more buildable direction than the original on-chain marketplace thesis. Its success depends less on blockchain infrastructure and more on whether it can make verified skill reuse easier, safer, and more valuable than one-off LLM generation.

The next step is not more architecture. It is a narrow usage test with real anchor skills, real acquisition flows, and real feedback.
