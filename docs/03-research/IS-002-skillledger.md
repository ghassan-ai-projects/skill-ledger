---
idea-id: "IS-002"
title: "SkillLedger — On-Chain Agent Skill Marketplace"
status: "capture"
priority: "P1"
stage: "capture"
created: "2026-04-27"
updated: "2026-04-27"
source: "Ghassan"
consensus: 0.0
tags: [web3, agents, marketplace, blockchain, smart-contracts, verification]
---

# IS-002: SkillLedger — On-Chain Agent Skill Marketplace

## 1. Problem

> AI agent skills are not composable, verifiable, or tradeable. There's no trust-minimized way to buy, sell, or compose agent capabilities.

**Problem Statement:**
- Agent skills today are opaque black boxes — you have no way to verify a skill's quality or SLO compliance before paying
- Composability across skill providers requires custom integration work, not standardized contracts
- There's no marketplace where skill creators can monetize their work trustlessly

**Evidence that this problem is real:**
- IS-001 (A2A Service Discovery) identified reputation as the #1 unsolved problem
- No existing agent marketplace has trustless verification or on-chain guarantees
- zkML, FHE, and verifiable compute are maturing but have no marketplace layer

**Current alternatives (how do people cope today?):**
- Blind trust in API providers (no recourse if a model degrades)
- Custom integration contracts between parties (slow, expensive)
- Manual reputation via reviews (gamable, non-portable)

---

## 2. Initial Thoughts / Raw Notes

> Ghassan's original analysis:

**Core concept:** SkillLedger — a composable, trust-minimized marketplace where AI agent skills are packaged, listed, transacted, and quality-guaranteed on-chain.

**Key components:**
1. **Skill as Tokenised Asset** — ERC-721/1155 wrapping:
   - API interface (input/output schema)
   - Pricing (per-call, per-1k tokens, flat subscription, royalty splits)
   - SLO (latency, uptime, accuracy thresholds)
   - Required stake/bond (slashable on failure)

2. **On-chain escrow & trustless payments** — pay into smart contract escrow, execution off-chain, release on verification attestation

3. **Verification layer (accountability)** — three models:
   - Optimistic verification (challenge period, Kleros-style courts)
   - zkML proofs (trustless but 1000x too slow for large models)
   - Evaluator DAO (validator nodes with stake-weighted voting)

4. **Reputation & composability** — soulbound tokens, skill pipelines with automatic royalty distribution

5. **Discovery & curation** — DApp with search, rankings, SDKs for LangChain/CrewAI/AutoGPT

**Improvements that add moats:**
- Deploy on L2 (Arbitrum, Base) or dedicated Avalanche subnet
- Proof-of-competence registration — silent benchmark before listing
- Pay-per-performance tuning — real-time feedback weighted by stake
- Privacy-preserving invocation — encrypted inputs/outputs via threshold decryption
- Open marketplace for verification oracles — third-party verifiers compete

---

### Deep Criticism (Ghassan's follow-up — 5 structural flaws)

**a. Verification dilemma is unsolved for generative AI**
- For non-deterministic outputs (marketing copy, images), what IS "correct execution"?
- Subjective quality can't be programmatically slashed — devolves into human court (slow, gameable)
- Only works for deterministic tasks: math, code execution, DB queries — that's a small subset of AI skills
- Without automatable pass/fail, the entire escrow + slashing mechanism collapses

**b. Blockchain is wrong for micro-transactions**
- AI inference calls are sub-cent and extremely frequent
- Even L2 gas makes per-call on-chain nonsensical
- Would need payment channels or L3 aggregation — which centralizes trust and defeats the purpose

**c. Cold-start vs centralized giants**
- OpenAI GPT Store, Hugging Face, Replicate already have liquidity + payment rails + zero crypto friction
- Developers won't learn blockchain tooling + stake capital for a smaller audience

**d. Sybil attacks on slashing**
- Low-stake creators can game subjective disputes via manipulated juries
- Reputation resets with new identities
- Would need Proof of Personhood — more friction

**e. Developer experience gap vs Web2**
- Stripe/Replicate/Modal: zero up-front stake, per-token billing, instant deploy
- SkillLedger: capital lock-up, smart contract deployment, slower iteration
- Blockchain must unlock a revenue stream unavailable in Web2 (e.g., agent-to-agent without KYC)

**Validation verdict:** Viable as a niche Web3-native platform for a specific transaction type — not a general replacement. Deterministic code generation, API-calling agents, SQL query generation are the narrow wedge.

**Related projects:** SingularityNET, Fetch.ai, Ocean Protocol, Autonolas (Olas), Bittensor — all adjacent but none solved the accountability + verified execution problem.

**Product thesis if narrowed:** Focus on deterministic, verifiable, agentic micro-services (not open-ended creative AI).

---

### Ghassan's Pivot (April 27 follow-up)

**New positioning:** Not a consumer marketplace — **payment & accountability layer for the multi-agent ecosystem.**

**Why this survives the 5 criticisms:**
1. **Verification solved** — narrow to deterministic tasks (code execution, SQL queries, API orchestration) where pass/fail is machine-checkable. Generative/creative AI skills are out of scope.
2. **Micro-transactions solved** — deploy on high-speed EVM rollup (Arbitrum/Base) with gas abstraction (EIP-4337). Custom off-chain worker network aggregates and settles periodically. Per-call on-chain is not the goal.
3. **Cold-start solved** — don't compete with OpenAI GPT Store for human developers. Target **agents, not humans**. Agents have crypto wallets, not credit cards. This is a genuine need with zero Web2 competition.
4. **Sybil gaming** — accept optimistic verification + dispute court as pragmatic first step. zkML is on the roadmap but not required for MVP.
5. **DX gap** — SDK wraps existing agent frameworks (LangChain/CrewAI). Developer deploys standard code, the protocol handles tokenization + escrow behind the scenes.

**Market timing thesis:** Autonomous AI agents running continuously need to hire other agents' skills programmatically. A permissionless, trust-minimized settlement layer becomes more valuable as the agent ecosystem grows. Current market small but growing rapidly.

**Final verdict (Ghassan):** The idea is not fundamentally flawed, but over-ambitious if generalized to all AI skills. Narrow scope, solve accountability for machine-checkable categories, and you have a product that attracts both creators and capital. Starts as "crypto for agents" infrastructure, not mass-market creator economy.

---

## 3. Ideation Log

### Round 1 — Divergent (Multi-Model Brainstorming)

**Prompt Used:**
> "Generate 5-7 solutions to this problem: We need a trust-minimized marketplace where AI agent skills are packaged, listed, transacted, and quality-guaranteed on-chain. Skills are tokenised as ERC-721/1155 contracts with API interface, pricing, SLOs, and slashable bonds. Consumers pay into escrow, execution is off-chain, payment releases on verification. Key tension: verification is either too slow (zkML), too trust-dependent (optimistic+court), or too centralized (validator DAO). For each solution: (a) one-line pitch, (b) key assumption, (c) biggest risk."

**Results:** 18 candidates from 3 models:
- DeepSeek (Technical): Optimistic+Bonded Dispute, TEE Attestation, Verifier DAO (EigenLayer AVS), Hybrid verification routing, zkML-as-Market, Reputation-Bonded NFT Escalation
- Gemini (Growth): Optimistic Escrow, Skill Mining token program, Recursive Reputation NFTs, Insurance Pools, Modular SDK CLI, TEE-Attested Nodes
- Kimi (Creative): Proof-of-Waste verification, Recursive Composability as verification, Zero-Pricing+Bonding Curves, Insurance instead of Escrow, Token-Curated Registry, Dark Marketplace ZK discovery

### Round 2 — Convergent (Synthesis & Consensus)

**Key convergences (3/3 models):**
1. Optimistic verification + bonded dispute windows — found in all 3 models
2. TEE-attested execution — hardware-level integrity guarantees
3. Multi-layer reputation/escalation stacks — auto → optimistic → arbitration

**Partial convergence (2/3):** Insurance replaces escrow (Gemini+Kimi), Token-curated quality (Gemini+Kimi), Dev DX as first priority (DeepSeek+Gemini)

**Top 3 solutions:**
1. Hybrid Optimistic + TEE Attestation with Modular Escalation (consensus 0.85)
2. Optimistic Escrow + Insurance Pools (consensus 0.70)
3. Token-Curated Registry + Reputation NFTs (consensus 0.60)

### Round 3 — Deep Dive

**Winner: Hybrid Optimistic + TEE Attestation with Modular Escalation**

**Why it wins (survives all 5 criticisms):**
- **Verification:** TEE proves *execution was honest* (model+args ran faithfully) — doesn't need subjective "correct output" judgment. Optimistic for deterministic skills.
- **Micro-tx:** Off-chain order flow (EIP-712 signatures), batched L2 settlement. Per-tx cost <$0.001.
- **Cold-start:** Target agents with crypto wallets, not humans with credit cards. No Web2 competition for this use case.
- **Sybil:** TEE requires physical hardware per identity. Bonded disputes add economic sybil resistance.
- **DX:** One-command deploy to TEE nodes. Developer never touches Solidity or manages gas.

**Phased roadmap:**
- Phase 1: Optimistic escrow + dispute court for deterministic skills (code exec, SQL, API orchestration)
- Phase 2: TEE execution node network (introduce for higher-value / sensitive workloads)
- Phase 3: Modular escalation — route each skill to its best verification mode
- Phase 4: zkML integration when production-ready (roadmap, not blocker)

---

## 4. Validation

### Validation Summary

The idea survived multi-model ideation (18 candidates → 1 winner with 0.85 consensus) and Ghassan's 5 structural criticisms through a sharp pivot.

**What changed:** Consumer marketplace → **payment & accountability layer for the multi-agent ecosystem**

**Narrowed scope:** From all AI skills → deterministic only (code execution, SQL queries, API orchestration, data transforms)

**Target customer:** Agents with crypto wallets, not humans with credit cards. This is a genuine need with zero Web2 competition — agents can't use Stripe.

**Verification approach:** Hybrid.
- Optimistic + bonded disputes for low-value deterministic skills
- TEE-attested execution for higher-value / sensitive workloads
- zkML on roadmap when production-ready

**Approach acknowledged (from Ghassan's final analysis):**
- Launch on high-speed EVM rollup with gas abstraction (EIP-4337)
- Custom off-chain worker network for verification aggregation
- Optimistic verification + dispute court as pragmatic first step
- Research zkML integration in parallel

**Market timing:** Small market now, growing rapidly as autonomous agents proliferate and need to hire other agents programmatically.

### Lean Canvas (Post-Pivot)

| Block | Content |
|-------|---------|
| **Problem** | 1. No trust-minimized settlement for agent-to-agent skill payments. 2. Agents can't use credit cards. 3. No way to verify skill execution quality programmatically. |
| **Solution** | 1. On-chain escrow with optimistic verification. 2. TEE-attested execution nodes. 3. SDK for agent frameworks (LangChain/CrewAI). |
| **Key Metrics** | Monthly escrow volume ($), successful dispute rate, TEE node uptime, developer activations |
| **Unique Value Prop** | "Provably honest skill execution for AI agents — without a bank account." |
| **Unfair Advantage** | First-mover on A2A settlement + IS-001 directory cross-pollination. DeepSeek provides concrete ERC-8183 architecture. |
| **Channels** | Agent framework plugins (LangChain, CrewAI, AutoGPT), crypto-native dev communities, CTOs at agent-first startups |
| **Customer Segments** | **Beachhead:** Agent developers building autonomous pipelines that need deterministic off-chain skills. **Expansion:** Enterprise multi-agent deployments. |
| **Cost Structure** | L2 deployment + TEE node infrastructure + dispute court operation. Variable: gas costs, oracle fees. |
| **Revenue Streams** | 1. Escrow fee (1-3%). 2. TEE execution node staking. 3. Premium verification tier for enterprises. |

### Key Risks (Post-Pivot)

| Risk | Impact | Likelihood | Score | Mitigation |
|------|--------|-----------|-------|-----------|
| TEE hardware supply chain trusted | 5 | 2 | 10 | Multi-TEE (Intel + NVIDIA + AMD); don't rely on single vendor |
| Agent adoption slower than expected | 4 | 3 | 12 | Seed with IS-001 partners; fund liquidity program for early auditor agents |
| Competing L1/L2 launches native solution | 4 | 2 | 8 | Focus on EVM rollup ecosystem + cross-chain bridge strategy |
| Dispute court governance capture | 3 | 3 | 9 | Multi-signature + time-locked upgrades; open-source dispute logic |
| Regulatory — agent-to-agent payments classified as money transmission | 3 | 2 | 6 | Legal structure as protocol (not company); jurisdictional routing |

### Go/No-Go

**Verdict: CONDITIONAL APPROVE**
- ✅ The idea is structurally sound after the pivot
- ✅ Narrow scope on deterministic skills makes the verification problem solvable
- ✅ Agent-as-customer positioning bypasses Web2 competition entirely
- ⚠️ First-mover risk: very early market
- ✅ If zkML matures (2-3yr), the same infrastructure graduates to trustless

**Decision rationale (Ghassan):** "The idea is not fundamentally flawed. Narrow scope, solve accountability for machine-checkable categories, and you have a product that attracts both creators and capital. Starts as 'crypto for agents' infrastructure."

---

## 5. Decision

**Status:** → HANDED OFF TO PRODUCT PLANNER (PP-002)

**Working Backwards Decision:** GO (2026-04-27)
- 0 kill triggers from inversion analysis
- End State: 12-18 month horizon with specific evidence criteria
- Key decisions locked: deterministic only, Arbitrum first, optimistic for MVP
- Biggest unknown: will agents hire external agents at scale? Cheapest test: seed 3 anchor skills to 5 multi-agent builders
- Decision log: `obsidian/working-backwards/runs/2026-04-27-IS-002-skillledger.md`

**Date:** 2026-04-27

**Decision maker:** Ghassan

**Reasoning:**
- Survived 5 structural criticism rounds
- Post-pivot positioning (agent infra layer) is defensible and timely
- Multi-model consensus: 0.85 for winning architecture
- Related projects (SingularityNET, Fetch.ai, Olas) are adjacent but none solved verified execution

**Next steps if approved:**
- [ ] Design Phase 1 spec: optimistic escrow for deterministic skills
- [ ] Build TEE attestation pipeline prototype
- [ ] Agent framework SDK (LangChain plugin first)
- [ ] Seed with 3 anchor deterministic skills (code execution, SQL, API orchestration)
- [ ] Cross-pollinate with IS-001 (A2A Directory) as distribution channel

---

## 6. Activity Log

| Date | Action | Notes |
|------|--------|-------|
| 2026-04-27 | Idea captured | From Ghassan — on-chain agent skill marketplace concept with full analysis |
| 2026-04-27 | Self-critique added | 5 structural flaws documented: verification dilemma, micro-tx unsuitability, cold-start, sybil gaming, DX gap vs Web2 |
| 2026-04-27 | Ideation R1 complete | 18 candidates from 3 models across tech/market/creative lenses |
| 2026-04-27 | Pivot from Ghassan | New positioning: payment & accountability layer for multi-agent ecosystem, not consumer marketplace. Narrow to deterministic skills. Target agents (crypto wallets) not human developers (credit cards). |
| 2026-04-27 | Ideation R2 complete | Convergence map, top 3 solutions, consensus scores. Winner: Hybrid Optimistic + TEE Escalation (0.85) |
| 2026-04-27 | Ideation R3 complete | Deep dive on winner with phased roadmap. Survivor of all 5 criticisms. |
| 2026-04-27 | Working Backwards applied | v2 full engine: 7 stages. End State → PR → FAQ → Inversion → Backward Chain → Decision Tree → Execution. 0 kill triggers. Decision: GO. |
| 2026-04-27 | Handoff to Product Planner | SkillLedger enters adaptive pipeline as PP-002. Next stage: Prioritization (RICE + WSJF + Kano). |
