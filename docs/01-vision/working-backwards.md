# Working Backwards v2 — SkillLedger

**Status:** Complete  
**Date:** 2026-04-27  
**Decision:** ✅ GO (0 kill triggers)

---

## Stage 1: End State (12–18 months)

Autonomous AI agents hire other agents' skills trustlessly — pay for deterministic code execution, SQL queries, API orchestration — with on-chain settlement, programmatic verification, and no bank account required.

**Evidence this state has been achieved:**
- Measurable volume of A2A escrow transactions on a live testnet (or L2)
- 100+ skills deployed by developers
- At least one production multi-agent pipeline using SkillLedger as its settlement layer
- Dispute rate below 2% with average resolution time under 24 hours

---

## Stage 2: Press Release

[Full text — see original](https://github.com/ghassan-ai-projects/skill-ledger/wiki)

Core positioning from the press release:
- "Provably honest skill execution for autonomous agents — without a credit card, bank account, or legal contract."
- First trust-minimized payment layer purpose-built for AI agents.
- Not a consumer marketplace — **payment & accountability layer for the multi-agent ecosystem.**

---

## Stage 3: FAQ Summary

### External
- **What is SkillLedger?** A decentralized settlement layer where AI agents hire other agents' skills — escrow, verified execution, trustless settlement.
- **Who is it for?** Agents with crypto wallets, not humans with credit cards.
- **How is it different?** Designed for agents (no Stripe), trust-minimized (escrow + optimistic verification), permissionless.
- **What's the cost?** 1-3% escrow fee. L2 gas costs targeted < $0.001/tx.
- **What's the scope?** Deterministic skills only: code execution, SQL queries, API orchestration.

### Key Internal FAQ Answers
- **Biggest risk:** Agent adoption slower than expected.
- **Hardest challenge:** The verification dilemma for non-deterministic skills — solved by excluding generative AI from scope.
- **Fatal assumption:** "Agents will need to hire other agents' skills programmatically at scale."
- **Competitors are not solving this:** Bittensor, Olas, Fetch.ai are adjacent but none have solved verified execution.

---

## Stage 4: Inversion Summary

0 kill triggers identified. Critical risks (all mitigable):
1. **Agents don't need external skills** → focus on heterogeneous multi-agent architectures
2. **Deterministic-only is too narrow** → roadmap zkML for future
3. **TEE hardware supply chain compromised** → multi-TEE strategy (Intel + AMD + NVIDIA)

---

## Stage 5: Backward Chain

```
T+0: Live mainnet, 100+ skills deployed
    ↑
T-1: Mainnet launch, 10 anchor skills, first paying customers
    ↑
T-2: Beta on testnet, 3 anchor skills, SDK v1
    ↑
T-3: Prototype — escrow contract, TEE node network, single-agent pipeline test
    ↑
T-4: Spec complete
    ↑
T-5: Working Backwards decision → GO (we are here)
```

---

## Stage 6: Key Decisions

### Deterministic Only vs. Generative
- **Decision:** Deterministic only (MVP). Generative on roadmap via zkML.
- Rationale: Verification is solvable for deterministic tasks. Generative requires zkML (3-5 years out).

### L2 Selection
- **Decision:** Start on Arbitrum (mature, largest ecosystem). Cross-chain bridge for Phase 2.
- Candidates evaluated: Arbitrum, Base, Polygon zkEVM, Avalanche subnet.

### Verification Strategy
- **Decision:** Optimistic for MVP (Phase 1). Hybrid (Optimistic + TEE) for Phase 2-3.
- Optimistic: 24-48h challenge window, simplest to implement.
- TEE: instant settlement but hardware dependency.
- Hybrid: best of both worlds.

### Kill Triggers
1. After 6 months on testnet: < 10 skills deployed AND < 100 escrow transactions
2. A centralized competitor launches equivalent functionality with significantly better UX
3. A2A hiring turns out to be an edge case
