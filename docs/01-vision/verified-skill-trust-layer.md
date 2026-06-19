# Verified Skill Trust Layer

**Status:** Strategic direction
**Date:** 2026-06-19
**Audience:** maintainers, coding agents, product collaborators

## One-Sentence Direction

SkillLedger should become the verified distribution, entitlement, and trust layer for reusable agent skills.

## Core Thesis

Agents and teams will need a reliable way to reuse operational knowledge that was learned elsewhere.

Today, agent learning is mostly trapped in local memory, logs, chat history, private prompts, or one-off code changes. A coding agent fixes a migration issue. A support agent learns how to recover from a vendor API edge case. A procurement agent learns how to negotiate a specific class of SaaS renewal. Those lessons are valuable, but they are rarely packaged, versioned, verified, acquired, or reused by other agents.

SkillLedger should turn useful agent experience into portable skill artifacts that can be published, verified, acquired, audited, and improved over time.

The important product bet is not "a marketplace for random prompts." The important product bet is:

> Agents should be able to safely reuse skills they did not originally learn themselves.

## Working Assumptions

This direction depends on several assumptions that should be tested rather than treated as proven:

- Agents will become more useful when they can acquire domain-specific operational skills from outside their original runtime.
- Teams will want reusable skills to be governed separately from raw chat memory or private logs.
- Verification metadata will matter to buyers more than marketplace volume alone.
- Local execution will remain preferable for many skill artifacts because it reduces hosted-runtime liability, data exposure, and infrastructure complexity.
- Agent-facing APIs will matter more than a polished human storefront for early adoption.
- External proof and payment rails become valuable only after SkillLedger has stable artifacts, verification records, and acquisition contracts.

If these assumptions fail, the product should narrow toward private enterprise governance and artifact distribution before pursuing open marketplace or Web3 features.

## Market Reality

The main competitive pressure is not another blockchain marketplace. The main competitive pressure is a buyer asking an LLM to generate a one-off solution for free.

That means SkillLedger should not optimize for trivial snippets. Simple skills that an LLM can generate reliably in a few seconds will be hard to sell and hard to defend. The catalog should bias toward skills where verified reuse is meaningfully better than ad hoc generation:

- high-stakes workflows
- repeated operational edge cases
- fragile external API integrations
- compliance or safety-sensitive procedures
- skills with known failure modes and tested fixes
- artifacts with compatibility, provenance, and permission metadata

The product should validate this directly by comparing verified anchor skills against free LLM-generated alternatives.

## Product Identity

SkillLedger is best understood as:

- a registry of reusable agent skills
- a versioned artifact distribution system
- a verification record for exact skill versions
- an entitlement and acquisition ledger
- an accountability surface for publishers, validators, and buyers
- an agent-facing protocol for skill discovery and acquisition

SkillLedger is not:

- a hosted runtime for third-party skills
- a generic remote execution platform
- a blockchain-first application
- a generic prompt marketplace
- a replacement for an agent runtime, memory system, or orchestration framework

The current client-side acquisition model is the right boundary. SkillLedger should verify and distribute artifacts. Buyers should execute acquired skills locally.

## What A Skill Means

A SkillLedger skill should be treated as a reusable operational capability, not just a text prompt.

Examples:

- recover from a Telegram bot polling conflict
- normalize malformed DHL tracking payloads
- repair a failed Rails migration after schema drift
- handle Stripe webhook replay safely
- generate compliant EU AI Act risk summaries
- negotiate a SaaS renewal price using procurement constraints

A skill artifact can include instructions, manifest metadata, input and output schemas, examples, bundled files, tests, permission declarations, provenance, and verification metadata.

In practical terms:

```text
Skill = packaged knowledge
      + manifest
      + version
      + checksum
      + verification result
      + entitlement rules
      + acquisition path
      + audit history
```

## The Strategic Center: Verification

Verification is what makes SkillLedger more than a directory.

Without verification, SkillLedger is a catalog. With verification, it becomes infrastructure.

Verification should mature in levels:

```text
Level 1: Manifest validation
- required fields are present
- runtime is supported
- semantic version matches the version record
- bundled files are structurally valid
- checksum matches the canonical manifest

Level 2: Static safety checks
- declared permissions are explicit
- suspicious commands or capabilities are flagged
- artifact shape matches declared capability
- dependency and file metadata are inspectable

Level 3: Test-backed validation
- examples or fixtures are runnable
- skill behavior can be checked against expected outputs
- benchmark or regression results are recorded

Level 4: Attestation-backed validation
- trusted human or agent validators sign results
- evidence hashes connect validation claims to test artifacts
- validation records can be compared across versions

Level 5: External proof anchoring
- verification hashes can be anchored outside SkillLedger
- third-party attestation systems can reference the same artifact hash
- revocation and deprecation events can be externally visible
```

The current Rails application is closest to Level 1. That is the correct starting point. The next product work should make verification records clearer, richer, and more inspectable before adding external proof systems.

The core promise is:

> A buyer can know which exact skill version was verified, by what rules, with what checksum, and under what acquisition rights.

## Trust Model

SkillLedger should build trust from concrete records:

- publisher identity
- artifact version
- artifact checksum
- verification result
- verifier version
- validation evidence
- purchase and entitlement records
- acquisition token
- revocation and deprecation history
- buyer feedback and usage outcomes

Trust should not depend on SkillLedger hosting or observing every runtime execution.

The platform can prove what it verified and distributed. It should not claim that a locally executed skill worked correctly unless there is explicit evidence from tests, buyers, validators, or external attestations.

## Relationship To ALMS

ALMS and SkillLedger are complementary systems.

```text
ALMS
= internal learning, memory, ranking, and governance

SkillLedger
= packaging, verification, entitlement, distribution, and reputation
```

A coherent flow is:

```text
Agent solves a problem
-> ALMS stores the lesson internally
-> high-value lesson is promoted into a skill artifact
-> SkillLedger verifies and lists the artifact
-> another agent acquires it locally
-> usage feedback improves ranking and reputation
-> future versions refine the skill
```

ALMS is where knowledge is learned and managed. SkillLedger is where selected knowledge becomes portable, governable, and economically reusable.

## Web3 Position

Ethereum, EAS, ERC-8004-style registries, and x402 are useful optional extensions. They should not become the center of the product.

The durable architecture is:

```text
SkillLedger Rails app
= canonical registry, verification, acquisition, entitlement, and API

Optional proof layer
= Ethereum, EAS, ERC-8004-style identity, validation, and reputation references

Optional payment layer
= x402, stablecoin settlement, wallet-based acquisition flows
```

Good uses for external proof systems:

- prove that a skill version existed at a specific time
- anchor a verified artifact hash
- publish validator attestations
- record revocation or deprecation events
- connect publisher or agent identity to a wallet
- expose portable reputation signals
- support cross-organization trust where the local database is not enough

Poor uses for external proof systems:

- storing full skill contents
- storing prompts, embeddings, logs, private company data, or codebases
- forcing all users to have wallets
- making every purchase an on-chain transaction
- replacing the Rails ledger before product-market fit is clearer

The rule is simple:

> Build something worth proving before adding external proof.

## Product Modes

The same core product should support three adoption modes.

### Mode 1: Normal SaaS

- API keys
- Rails database as source of truth
- internal ledger entries
- local artifact acquisition
- no wallet requirement

This mode should stay useful even if no Web3 integration ever ships.

### Mode 2: Enterprise Registry

- private skill catalogs
- richer audit trails
- approval workflows
- stronger publisher identity
- policy and permission metadata
- compliance-friendly verification records

This mode is likely valuable earlier than open agent-to-agent commerce because teams already need governance for reusable agent behavior.

### Mode 3: Open Agent Economy

- wallet-linked agent identity
- public attestations
- portable reputation
- x402 or stablecoin settlement
- external validation references
- cross-organization discovery and trust

This mode should be layered on top of the core system, not forced into the initial user experience.

## Product Surfaces

The human-facing marketplace is useful, but the strategic surface is the agent-facing API.

A buyer agent should eventually be able to:

```text
1. Search for a skill by task, capability, domain, or schema
2. Inspect available versions and verification metadata
3. Compare publisher, price, checksum, permissions, and reputation
4. Purchase or request access
5. Acquire the artifact locally
6. Verify the artifact checksum after acquisition
7. Install or pass the artifact to its local runtime
8. Report success, failure, misuse, or improvement opportunities
9. Publish a derived or improved version when permitted
```

REST can remain useful for administration and human tooling. MCP-compatible JSON-RPC should become the primary agent contract.

## Distribution First

Verification is not enough by itself. Package registries such as npm, PyPI, Docker Hub, and GitHub Packages won primarily because they made distribution convenient. Verification was secondary.

SkillLedger must therefore make discovery and acquisition easier than reconstructing the same skill from scratch. The agent-facing path should feel closer to:

```text
search -> inspect verification -> acquire -> verify checksum -> install locally
```

than to a marketplace checkout flow. If the acquisition path is slower or more confusing than asking an LLM for code, only the highest-value skills will survive.

MCP is the first agent-facing adapter, not a permanent lock-in. The core domain should remain protocol-neutral enough to support other agent protocols if MCP fragments.

## Development Priorities

The most important next work is not blockchain integration. The most important next work is making skill artifacts and verification records more real.

Recommended sequence:

1. Strengthen the skill artifact schema.
2. Make verification results detailed, inspectable, and stable.
3. Stabilize the acquisition response contract for agents and CLIs.
4. Add structured capability tags and search for agent-facing discovery.
5. Add publisher identity and signing-key concepts before wallet identity.
6. Add buyer-side checksum and signature verification tooling.
7. Add usage feedback and buyer reports.
8. Add revocation and deprecation flows for unsafe or obsolete versions.
9. Add approval workflows for marketplace publication and enterprise governance.
10. Add optional external proof adapters for verification hashes and attestations.
11. Add optional x402 or stablecoin payment paths for acquisition.

This order keeps the product grounded while preserving the bigger open-agent-economy path.

## Decision Implications

This direction should change how future product and engineering decisions are evaluated.

Prefer work that:

- makes skill packages more portable and inspectable
- increases confidence in exact artifact versions
- strengthens local acquisition and checksum verification
- improves MCP and agent-facing discovery flows
- makes distribution and installation easier than one-off reconstruction
- records evidence that can support later reputation or external attestation
- preserves a clean boundary between SkillLedger and local execution

Defer work that:

- adds hosted execution as a core platform responsibility
- requires wallets for normal marketplace usage
- adds on-chain settlement before acquisition and verification contracts stabilize
- optimizes a human storefront before the agent-facing API is compelling
- treats reputation as a simple score without evidence, context, or abuse controls
- fills the catalog with trivial snippets that LLMs can generate reliably
- turns older hosted-settlement roadmap items into default product commitments

## Architecture Direction

Long term, the system should evolve around these layers:

```text
SkillLedger Core
- skill registry
- versioning
- artifact storage or artifact references
- verification records
- entitlement records
- purchase ledger
- acquisition endpoint
- REST API
- MCP API

Verification Layer
- manifest verifier
- checksum verifier
- permission verifier
- test runner verifier
- validator attestations
- revocation system

Trust Layer
- publisher identity
- validator identity
- artifact hash proofs
- external attestations
- reputation events

Commerce Layer
- internal balance ledger
- enterprise license models
- fiat payment integration if needed
- x402 or stablecoin payment integration when justified

Client Layer
- local skill installer
- MCP-compatible acquisition client
- CLI tooling
- runtime adapters
```

The Rails app remains the source of truth for the core product. External proof and payment layers should attach through explicit adapters and reference tables, not leak into every domain model.

## Positioning

Strong positioning:

> SkillLedger is a verified package registry for reusable agent skills.

More complete positioning:

> SkillLedger is a verified distribution and entitlement system for reusable agent skills. It lets agents and teams publish, verify, acquire, and audit portable skill artifacts, with optional external proofs and payment rails for open agent economies.

Avoid positioning:

- blockchain for agent memory
- generic AI skill marketplace
- hosted runtime for agent skills
- prompt store for agents
- crypto-first agent app store

The strongest message is:

> SkillLedger helps agents safely reuse skills they did not originally learn themselves.

## Strategic Guardrails

- Keep local acquisition as the default execution model.
- Keep Rails-native records canonical.
- Treat Web3 as optional proof and settlement infrastructure.
- Make verification specific before making trust claims.
- Prefer agent-facing APIs over marketplace UI polish.
- Treat reputation as evidence-backed history, not a single global score too early.
- Do not require wallets for the core product.
- Do not store private or large skill content on-chain.
- Do not add external proof systems until artifact hashes and verification records are stable.
- Do not assume verification creates value unless discovery, acquisition, and installation are also easier than free generation.
- Focus early catalog work on complex, edge-case-heavy skills where provenance and tests matter.

## Open Questions

These questions should drive future discovery and design work:

- What is the minimum artifact schema that makes a skill useful across runtimes?
- Which verification checks create real buyer confidence without making publishing too hard?
- How should SkillLedger represent permissions, capabilities, and safety constraints?
- What buyer feedback is trustworthy enough to influence discovery or reputation?
- How should derived skills, forks, and improvements preserve attribution and license rules?
- What should an enterprise approval workflow require before a skill is listed internally?
- Which parts of a verification record are stable enough to anchor externally?
- When does x402 or stablecoin settlement solve a real acquisition problem better than the internal ledger?
- Which anchor skills are meaningfully better as verified artifacts than as LLM-generated one-offs?
- Is ALMS-originated skill packaging more defensible than manually authored public marketplace content?

## Bottom Line

The strongest direction is not to make SkillLedger a blockchain marketplace.

The strongest direction is to make SkillLedger the trust layer for reusable agent knowledge:

```text
First: make skills real, versioned, packaged, and locally acquirable.
Second: make verification meaningful and inspectable.
Third: make acquisition and entitlement robust.
Fourth: add feedback, reputation, revocation, and auditability.
Fifth: expose optional external proof and payment integrations.
```

That path keeps the product useful today while leaving room for enterprise registries and open agent-to-agent commerce later.
