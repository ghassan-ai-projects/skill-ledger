# Working Backwards: SkillLedger (IS-002)

**Date:** 2026-04-27
**Domain:** Product
**Mode:** Full Engine

---

## Stage 1: End State

**In one sentence:** Autonomous AI agents can hire other agents' skills trustlessly — pay for deterministic code execution, SQL queries, API orchestration — with on-chain settlement, programmatic verification, and no bank account required.

**In detail:**
It's 2027. A team of 4 autonomous research agents is running a competitive analysis pipeline. Agent A needs a SQL query executed against a private data warehouse. It posts the task with a stake to SkillLedger, finds Agent B (a verified SQL executor), pays into escrow. Agent B executes, the result is verified optimistically within the dispute window, and payment settles. No human involved. No credit card. No contract negotiation. The entire lifecycle — discovery, payment, execution, verification — happens in minutes, trustlessly, between agents with crypto wallets.

Agent developers deploy skills to the network with a single command. They never touch Solidity. They never manage gas. The SDK wraps their code, deploys it to TEE-attested execution nodes, and the protocol handles tokenization + escrow + settlement. An agent can list a skill at 9am and have its first paying customer (another agent) by 11am.

**Evidence this state has been achieved:**
- A measurable volume of A2A escrow transactions on a live testnet (or L2)
- Developers have deployed at least 100 skills
- At least one production multi-agent pipeline uses SkillLedger as its settlement layer
- Dispute rate below 2% with average resolution time under 24 hours

**Time horizon:** 12-18 months

---

## Stage 2: Press Release

```
FOR IMMEDIATE RELEASE

## SkillLedger Launches: The First Trust-Minimized Payment Layer for AI Agents

*Provably honest skill execution for autonomous agents — without a credit card, bank account, or legal contract.*

---

BERLIN — April 27, 2026 — SkillLedger today launched the first on-chain settlement layer purpose-built for AI agents to hire each other's skills. Unlike existing API marketplaces designed for humans with credit cards, SkillLedger enables autonomous agents to discover, pay for, and verify skill execution entirely programmatically.

"This is the missing piece for multi-agent economics," said Ghassan, project lead. "Agents can't use Stripe. They can't sign contracts. They need a trust-minimized system where they can hire another agent's skill, pay into escrow, and get provably honest execution — all without human intervention."

**How it works:**
A developer deploys their Python/Rust/TypeScript function to SkillLedger's TEE-attested execution nodes. The function is automatically tokenized with pricing, SLO thresholds, and a slashable bond. When an agent posts a task, it discovers available skills through a curated directory, pays into an optimistic escrow contract, and receives the output — verified or challenged within the dispute window.

**What early developers are saying:**
> "I deployed a code execution skill in 30 minutes. The SDK handled the tokenization and escrow setup. The first paying agent found me within a day. This is the first time agent-to-agent payments have felt as natural as API calls."
> — [Name], [Title]

**Why this matters:**
As autonomous agents proliferate, they will need to hire each other complex workflows. Without SkillLedger, every agent-to-agent transaction requires custom integration, manual billing, or centralized intermediaries. With SkillLedger, agents transact the same way they execute code — as a primitive.

**Availability:**
Beta launch on Arbitrum Sepolia testnet. Mainnet expected Q3 2026.

---

*For more information, visit [placeholder] or follow @SkillLedger*
```

---

## Stage 3: FAQ

### External (Customer-facing)

**Q: What is SkillLedger?**
A: A decentralized settlement layer where AI agents can hire other agents' skills — pay into escrow, get verified execution, settle trustlessly. No bank account required. For deterministic tasks only: code execution, SQL queries, API orchestration, data transforms.

**Q: Who is it for?**
A: Agent developers building autonomous multi-agent pipelines. The primary customer is an agent with a crypto wallet, not a human with a credit card.

**Q: Why now?**
A: Two trends converge: (1) autonomous agents are proliferating and need to hire each other programmatically, (2) crypto infrastructure (L2s, TEEs, gas abstraction) is finally mature enough to support A2A micropayments without friction.

**Q: How is it different from existing solutions?**
A: Three differences: (1) Designed for agents, not humans — agents don't have Stripe accounts. (2) Trust-minimized — escrow + optimistic verification + TEE attestation. (3) Permissionless — any agent can list a skill, any agent can buy one.

**Q: How much does it cost?**
A: 1-3% escrow fee on settled transactions. TEE execution node staking for high-value workloads. Gas costs on L2 (Arbitrum/Base) — per-tx cost targeted below $0.001.

**Q: When can I use it?**
A: Beta on Arbitrum Sepolia testnet now. Mainnet expected Q3 2026.

**Q: What do I need to use it?**
A: An agent framework (LangChain, CrewAI, AutoGPT) and a crypto wallet. The SDK handles the rest.

### Internal (Team-facing)

**Q: How will this work technically?**
A: Optimistic escrow contracts on an L2 (Arbitrum or Base). Off-chain TEE execution nodes verify deterministic skill outputs. Settlement batched periodically — not per-call on-chain. SDK wraps agent framework integrations.

**Q: What are the key risks?**
A: (1) Agent adoption slower than expected. (2) TEE hardware supply chain trust is imperfect. (3) Competing L1/L2 launches native A2A settlement. (4) Dispute court governance capture. (5) Regulatory classification of A2A payments.

**Q: What could go wrong?**
A: Worst case: we build a great technical solution but the agent ecosystem doesn't materialize at the scale needed for network effects. The protocol works, but nobody uses it.

**Q: What would make agents hate this?**
A: High latency on verification windows. Complex dispute process. Unexpected gas costs. Buggy SDK that breaks their pipeline. TEE node downtime during critical tasks.

**Q: What would make this fail in the market?**
A: A centralized player (OpenAI, Hugging Face) launches "Agent API payments" with zero friction and more liquidity. Or the agent ecosystem consolidates around a single dominant framework that builds its own settlement layer.

**Q: What's the hardest technical challenge?**
A: The verification dilemma for non-deterministic skills. We solve this by excluding generative AI from scope — but that limits the addressable market. If the market demands generative skill verification, we need zkML, which is 3-5 years from production.

**Q: What dependencies do we have that could block us?**
A: L2 gas abstraction maturity (EIP-4337). TEE hardware availability (Intel SGX, AMD SEV, NVIDIA Confidential Computing). Agent framework adoption of our SDK.

**Q: What do we NOT know yet?**
A: The biggest unknown is agent adoption rate. We can build the protocol, but we can't control whether agents will need to hire each other at meaningful scale. If agent-to-agent workflows are an edge case rather than a core pattern, the market is too small.

**Q: What assumption, if wrong, kills the entire idea?**
A: "Agents will need to hire other agents' skills programmatically at scale." If most multi-agent pipelines use homogeneous agent clusters (same provider, same framework, pre-integrated), there's no need for a cross-agent marketplace.

---

## Stage 4: Inversion

### Component: Value Proposition

| Failure Mode | Likelihood | Impact | Mitigable? |
|-------------|-----------|--------|-----------|
| Agents don't need to hire external skills — they execute everything internally | Medium | Critical | Partial — focus on heterogeneous multi-agent architectures where agents from different systems interact |
| Deterministic-only scope is too narrow — market wants generative AI verification | High | Significant | Mitigated by roadmapping zkML. Generative verification is a future phase, not a blocker for MVP. |
| "Agent hiring agent" is a science fiction use case, not a real market | Low | Critical | Monitor: if no genuine use cases emerge in 6 months, pivot to enterprise API settlement |

### Component: Technical Architecture

| Failure Mode | Likelihood | Impact | Mitigable? |
|-------------|-----------|--------|-----------|
| TEE hardware supply chain compromised | Low | Critical | Multi-TEE strategy (Intel + AMD + NVIDIA) |
| L2 gas abstraction not mature enough for target tx costs | Medium | Significant | Fallback: batched settlement with off-chain state channels (worse UX but still viable) |
| SDK bugs cause agent pipeline failures | Medium | Significant | Thorough testing + phased rollout + versioned SDK |

### Component: Market Position

| Failure Mode | Likelihood | Impact | Mitigable? |
|-------------|-----------|--------|-----------|
| OpenAI/centralized platform launches "Agent API Payments" | Medium | Critical | Differentiate on trustlessness + permissionlessness. Centralized solutions can't offer escrow without a bank. |
| Agent ecosystem consolidates around one framework | Medium | Significant | Multi-framework SDK (LangChain + CrewAI + AutoGPT + custom) |
| Regulatory: A2A payments classified as money transmission | Medium | Critical | Legal structure as protocol, not company. Jurisdictional routing. |

### Component: Business Model

| Failure Mode | Likelihood | Impact | Mitigable? |
|-------------|-----------|--------|-----------|
| 1-3% escrow fee too high for high-frequency low-value agent tasks | High | Significant | Tiered pricing: flat monthly for active agents, percentage for infrequent use |
| TEE node staking creates capital barrier for small developers | Medium | Significant | Allow pooled staking / node delegation |

### Component: Competition

| Failure Mode | Likelihood | Impact | Mitigable? |
|-------------|-----------|--------|-----------|
| Bittensor subnet for verified execution | Medium | Significant | Bittensor's incentive mechanism is different (miner rewards). We're focused on settlement. |
| Olas (Autonolas) adds escrow to their agent platform | High | Significant | Olas targets autonomous service operations (coverage, prediction markets). Adjacent but not identical. Apply pressure by integrating with Olas as a settlement layer. |
| Fetch.ai's Agentverse adds payment rails | Medium | Significant | Fetch.ai agent framework + their own ledger. We're chain-agnostic — can settle on any EVM chain. |

### Inversion Summary

| Classification | Count | Action |
|---------------|-------|--------|
| Kill triggers (Critical + High + Unfixable) | 0 | ✅ No immediate kill |
| Critical risks (mitigable) | 3 | Monitor + Mitigate |
| Significant risks (manageable) | 6 | Include in risk register |
| Minor risks | 2 | Document, low priority |

**Verdict:** No kill triggers. The critical risks are all mitigable. Proceed.

---

## Stage 5: Backward Chain

```
T+0 (12-18 months): Live mainnet, 100+ skills deployed, multi-agent pipelines using SkillLedger as settlement layer
    ↑
T-1: Mainnet launch on L2. 10 anchor skills active. First paying customers.
    ↑
T-2: Beta on testnet. 3 anchor skills (code exec, SQL, API orchestration). Agent framework SDK v1.
    ↑
T-3: Prototype: optimistic escrow contract deployed. TEE node network (2-3 nodes). Single-agent pipeline test.
    ↑
T-4: Spec complete: escrow contract, verification protocol, SDK architecture, node requirements.
    ↑
T-5: Working Backwards decision: Go → Product Planner handoff (we are here)
    ↑
T-6: Idea Store validation complete (IS-002, APPROVED conditional)
    ↑
T-7: Idea captured (Ghassan's original concept)
```

**Critical path items:**
- T-4 to T-3: Optimistic escrow smart contract development (can't prototype without it)
- T-3 to T-2: SDK for agent framework integration (developers need to test)
- T-2 to T-1: Anchor skill onboarding (need real working examples on beta)

**Parallel workstreams (can run simultaneously with critical path):**
- TEE node setup and testing
- L2 gas estimation and optimization
- Dispute court design and simulation
- Legal research on A2A payment regulation

**Dependencies outside our control:**
- L2 gas abstraction maturity (EIP-4337 adoption)
- Agent framework API stability (LangChain, CrewAI)
- TEE hardware availability (supply chain)

---

## Stage 6: Decision Tree

### Decision Node: Narrow to deterministic only vs. include generative

```
├── Deterministic only (MVP)
│   ├── ✅ Verification solvable (machine-checkable pass/fail)
│   ├── ⚠️ Market scope limited (30-40% of agent skill usage?)
│   └── ➡ Proceed to Phase 1 spec
│
└── Include generative (scope creep)
    ├── ❌ Verification unsolvable without zkML (3-5yr)
    ├── ❌ Subjective quality → human court → slow + gameable
    └── ➡ Blocked. Revisit when zkML production-ready.
```

**Decision:** Deterministic only. Generative on roadmap.

### Decision Node: L2 selection

```
├── Arbitrum
│   ├── ✅ Mature L2, largest TVL
│   ├── ✅ EIP-4337 support improving
│   └── ⚠️ Gas still non-trivial for high-frequency
│
├── Base
│   ├── ✅ Coinbase backing, developer-friendly
│   ├── ✅ Growing ecosystem
│   └── ⚠️ Less battle-tested than Arbitrum
│
├── Polygon zkEVM
│   ├── ✅ ZK rollup, theoretically lower fees
│   └── ❌ Less mature, smaller ecosystem
│
└── Custom Avalanche subnet
    ├── ✅ Full control over gas params
    └── ❌ Requires validator bootstrapping (cold-start problem)
```

**Decision:** Start on Arbitrum (mature, largest ecosystem). Cross-chain bridge strategy for Phase 2.

### Decision Node: Verification strategy for MVP

```
├── Optimistic only (challenge period + bonded dispute)
│   ├── ✅ Simplest to implement
│   ├── ✅ No TEE hardware dependency
│   ├── ⚠️ 24-48h settlement finality (slow for real-time agent tasks)
│   └── ➡ Phase 1
│
├── TEE-attested only
│   ├── ✅ Instant settlement (verified at execution)
│   ├── ❌ Hardware dependency + supply chain trust
│   └── ➡ Phase 2
│
└── Hybrid (optimistic for low-value, TEE for high-value)
    ├── ✅ Best of both worlds
    ├── ⚠️ More complex architecture
    └── ➡ Phase 3
```

**Decision:** Optimistic for MVP (Phase 1). Hybrid for Phase 2-3.

### Kill Triggers (Conditions That Stop Everything)

```
KILL IF: After 6 months on testnet, < 10 skills deployed and < 100 escrow transactions
    └── Reason: Insufficient market validation

KILL IF: A centralized competitor launches equivalent functionality with significantly better UX
    └── Reason: Our differentiation (trustlessness) may not be worth the UX tradeoff for most users

KILL IF: Agent-to-agent hiring turns out to be an edge case (agents mostly execute internally within homogeneous clusters)
    └── Reason: Core assumption invalidated
```

---

## Stage 7: Execution Plan

### Start Now (T-5 to T-4)

- [ ] **Pass handoff to Product Planner** — SkillLedger enters the adaptive pipeline as PP-002
- [ ] **Write Phase 1 spec** — Optimistic escrow contract for deterministic skills
- [ ] **Build SDK prototype** — LangChain integration (the dominant agent framework)
- [ ] **Research L2 gas costs** — Deploy test escrow contract on Arbitrum Sepolia, measure per-tx costs

### Biggest Unknown

**"Will agents actually need to hire external skills at meaningful scale?"**

**Cheapest test:** Build the SDK prototype and deploy 3 anchor skills (code execution, SQL query, API orchestration) on testnet. Seed to 5 multi-agent builders. Measure: do they integrate it into their pipeline within 2 weeks?

**Pass criteria:** At least 2/5 builders integrate within 2 weeks and complete at least 10 escrow transactions each.

### Decision Points

| Decision | When | Criteria | Kill Threshold |
|----------|------|----------|----------------|
| Phase 1 → Phase 2 (TEE) | After 3 months live | < 2% dispute rate, ≥ 3 active TEE nodes ready | Dispute rate > 5% → redesign verification |
| Mainnet readiness | After 6 months beta | < 10% user-reported issues, ≥ 10 skills, ≥ 100 tx | < 5 skills or < 50 tx → revisit |
| Full launch | After mainnet stable for 2 months | Growing tx volume, positive developer feedback | 2 consecutive months of declining usage → kill |

---

## Handoff Summary

**Decision:** ✅ **GO** → Pass to Product Planner as PP-002 SkillLedger

**Status from Working Backwards:**
- End State: Clear (12-18 month horizon, specific evidence criteria)
- Press Release: Compelling (agent-as-customer positioning is genuinely novel)
- FAQ: Risks identified, mitigations exist, no fatal unknowns
- Inversion: 0 kill triggers. 3 critical risks (all mitigable). 6 significant risks (documented).
- Backward Chain: Feasible. Critical path: escrow contract → SDK → anchor skills → beta.
- Decision Tree: Key decisions locked (deterministic only, Arbitrum first, optimistic for MVP)

**Key risks entering Product Planner:**
1. Market timing — agent-to-agent hiring may be too early (medium likelihood, critical impact)
2. Verification scope — deterministic-only may be too narrow (addressed by zkML roadmap)
3. Competition — centralized players could replicate basic functionality (mitigated by trustlessness moat)

**First action for Product Planner:** Stage 1 (Prioritize) — RICE + WSJF + Kano scoring against other pipeline ideas.
