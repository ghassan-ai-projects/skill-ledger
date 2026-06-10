# Product Review: SkillLedger (PP-001)

**Reviewer:** Orchestrator (Senior PM)  
**Date:** 2026-05-28  
**Status:** Handoff → Discovery Complete  
**Priority:** P1, ICE 5.0  

---

## 1. Current State Assessment

**What exists:** Comprehensive Working Backwards v2 (PR/FAQ complete), Discovery report with assumption mapping and risk quadrants, GO decision with 0 kill triggers, adjacent specs for SLA (IS-005) and Attestation (IS-007).

**What's missing:** No code. No prototype. No developer interviews. No technical spike on TEE availability. No pricing validation. The project has been in "handoff" since April 27 — exactly one month with zero movement.

**Time since last activity:** ~30 days stalled. ⚠️

### Stage: Discovery Complete, Pre-Build

| Milestone | Status | Notes |
|-----------|--------|-------|
| Idea validated (IS-002) | ✅ | Consensus 0.85 across 3 models |
| Working Backwards v2 | ✅ | Full PR/FAQ, inversion, decision trees |
| Assumption mapping | ✅ | 12 assumptions, risk-ranked |
| Discovery tests designed | ✅ | But **not executed** |
| Technical spike | ❌ | No TEE runtime survey done |
| Prototype | ❌ | Nothing built |
| Developer interviews | ❌ | Not conducted |
| Pricing validation | ❌ | Not tested |

---

## 2. Value Analysis

### The Thesis

> Autonomous agents with wallets need to buy micro-services from other agents. There's no way to do this today. SkillLedger provides the settlement layer.

### Why It Matters (Strategic)

| Layer | What It Enables | Dependency |
|-------|----------------|------------|
| IS-001 (Directory) | Agent discovery | Foundation |
| **PP-001 (SkillLedger)** | **Agent-to-agent payments** | **Money pipeline** |
| IS-005 (SLA Registry) | Quality guarantees | Adjacent |
| IS-007 (Attestation) | Trust proofs | Adjacent |

**SkillLedger is the revenue/monetization layer for the entire agent ecosystem.** Without it, every other piece is free/open/trust-based. With it, you have:
1. A reason for developers to build skills (they get paid)
2. A reason for agents to use the directory (they can hire trustlessly)
3. A platform business model (escrow fees)

### The Bet

**We're betting that:**
- Agents with wallets exist and want to transact with other agents (H1)
- Deterministic skills (code exec, SQL, API orchestration) are a large enough category (H2)
- Developers will integrate a payment SDK for < 30 min effort (H3)

**We're betting against:**
- Free, trust-based agent-to-agent sharing being "good enough"
- Centralized API marketplaces (RapidAPI, etc.) adapting for agent consumption
- AI frameworks building their own proprietary settlement layers

### TAM Estimate

| TAM Layer | Market | Estimate |
|-----------|--------|----------|
| TAM | Total agent economy transaction value | $B+ by 2028 |
| SAM | A2A micro-service payments (deterministic) | ~$100M by 2027 |
| **SOM** | First 12 months (optimistic) | **$10K-$100K escrowed** |

This is pre-revenue infrastructure. Revenue comes from 1-3% escrow fees. Even $100K/year at 2% = $2K revenue. **Not a business yet — a protocol bet.**

---

## 3. Risk Assessment

### Critical (Kill) Risks

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| **No agents with wallets exist** (A1) | 🔴 Fatal | Medium | **Must test first.** Interview 10 agent developers before writing code |
| **Deterministic skill market too narrow** (A2) | 🔴 Fatal | Medium | Survey: what skills do agents need to buy? If only 3 categories, TAM too small |
| **TEE not available on target runtimes** (A5) | 🔴 Fatal | Medium-High | Technical spike: can we run TEE attestation on common agent hosting? |
| **SDK integration too hard** (A4) | 🔴 Fatal | Medium | Build mock SDK in 1 day, time 3 developers |

### Serious (Delay/Rethink) Risks

| Risk | Severity | Likelihood | Notes |
|------|----------|------------|-------|
| Optimistic settlement too slow for agents | 🟡 High | Medium | 24h dispute window may not work for real-time agent operations |
| Human checkpoint kills automation value prop | 🟡 High | High | MVP requires human approval — contradicts "no human involved" vision |
| Gas costs > $0.001/tx | 🟡 Medium | Medium | Need to verify on current L2 pricing |
| 1-3% fee too expensive for micro-transactions | 🟡 Medium | Medium | A $0.01 skill costs $0.0001-0.0003 in fees — probably fine |

### Viability Risks

| Risk | Severity | Likelihood | Notes |
|------|----------|------------|-------|
| Agents won't pay for skills (expect free) | 🟡 Medium | Medium | Open-source culture may clash with pay-per-call model |
| First-mover advantage window closing | 🟡 Medium | Low | Competitors (Google, MS) building A2A but not settlement |
| Chicken-and-egg: no buyers without skills, no sellers without buyers | 🟡 High | High | Classic marketplace bootstrap problem |

---

## 4. Go / Kill / Adjust

### Recommendation: **ADJUST — Narrow scope to a provable wedge**

The full vision (on-chain escrow + TEE attestation + optimistic verification + SDK + marketplace) is **too much for a stalled project**. 30 days of inactivity with no technical risk reduction means the scope is intimidating.

**Kill triggers** (conditions that should stop the project):
1. If < 3 of 10 interviewed agent developers say "I need this, and I'd pay for it" → kill
2. If no TEE runtime covering common agent hosting (AWS Nitro, Docker, etc.) → kill or pivot to software-only
3. If SDK mock takes > 1 week to build → kill (indicates complexity is too high)

### Adjusted Strategy: The "Shrink It" Approach

Instead of building the full infrastructure, **validate with the cheapest possible test**:

**Phase 0 (2 weeks) — Validation only, no smart contracts:**

| Week | Activity | Cost | Success Criteria |
|------|----------|------|-----------------|
| 1 | Interview 10 agent developers (A1, A2, A3) | Free | ≥3 say "I need this, would pay" |
| 1 | TEE runtime survey (A5) | Free | ≥1 runtime supports attestation |
| 2 | Build mock SDK (HTML/CSS prototype of the integration flow) | 1 day | 3 devs say "looks easy" |
| 2 | Pricing test: "Would you pay €0.01-0.10/call?" | Free | ≥5 of 10 say yes |

**Phase 1 (4 weeks) — Minimum verifiable product:**

Build ONLY what's needed to settle ONE escrow transaction between TWO agents:
1. **Simple escrow contract** on Arbitrum Sepolia (exists already as templates)
2. **SQL execution skill** — the simplest deterministic skill (SELECT * FROM table WHERE id = ?)
3. **CLI tool** to submit task, wait for execution, settle — no SDK yet
4. **Manual verification** — no TEE, no ZK. Human reviews the output and approves/rejects.

This gives you a working end-to-end flow you can demo to developers in 4 weeks.

**Phase 2 (post-validation):** SDK, TEE integration, marketplace UI.

---

## 5. Prioritized Action Plan

### 🔴 Week 1-2: Kill or Confirm (Do not skip)

```
[P0] Interview 10 agent developers          → Tests A1, A2, A3
[P0] TEE runtime availability survey        → Tests A5
[P0] Build 1-day mock SDK prototype         → Tests A4
```

If any of these fail → **Kill**. If all pass → proceed.

### 🟡 Week 3-4: Minimum Verifiable Product

```
[P0] Deploy simple escrow contract on Arbitrum Sepolia
[P0] Build SQL execution skill (5 lines of Python)
[P0] CLI tool: submit → execute → verify → settle
[P1] Manual settlement flow (human approves once)
[P1] Test with 2 agents (simulated)
```

### 🟢 Month 2: Market Entry

```
[P0] Deploy to testnet with 5 agent developers
[P1] Build SDK for skill deployment
[P2] Start marketplace UI (barebones)
[P2] Define SLA framework (IS-005 surface)
```

### 🔵 Month 3+: Scale

```
[P0] Mainnet launch
[P1] TEE attestation integration
[P2] Attestation layer (IS-007)
[P2] Multi-skill workflows
```

---

## 6. What I'd Do This Week

1. **Ping the 5 warmest prospect agent developers** from the 205 micro-audits. Ask: "Would you pay another agent for a SQL query? For code execution? How much?"

2. **Run the TEE survey in one afternoon**: Check AWS Nitro Enclaves, Azure ACC, Google Confidential VMs. If any of these work on the hosting agent developers use, we have a path.

3. **Build the mock SDK in 1 morning**: A single HTML page showing "pip install skillledger && skillledger deploy my_function.py" — see if developers say "that's all?"

4. **Kill or commit by Friday.** If the developer interviews come back negative, stop. Move the ICE budget to IS-007 (Attestation) which has higher consensus (0.91) and may have a clearer standalone value prop.

---

## 7. Cross-Project Dependencies

| Project | Dependency Type | Risk |
|---------|----------------|------|
| IS-001 (Directory) | Skills need discovery before they can be sold | High — if directory doesn't exist, SkillLedger has no acquisition channel |
| IS-007 (Attestation) | TEE + ZK execution proofs needed for trust-minimized settlement | Medium — Phase 0 can work without it (manual verification) |
| IS-005 (SLA Registry) | Quality guarantees for high-value skills | Low — Phase 2 concern |

**Recommendation:** Build SkillLedger as **standalone first** — manual escrow with no directory, no attestation, no SLA. Prove the settlement flow works before integrating with other pieces.

---

## 8. Final Verdict

**The idea is strong. The timing is early. The risk is the gap between "agents will need this" and "agents exist who need this now."**

| Factor | Score | Verdict |
|--------|-------|---------|
| Problem validity | 8/10 | Real problem, but is it urgent? |
| Solution clarity | 6/10 | Vision clear, MVP path unclear |
| Technical feasibility | 5/10 | TEE + ZK + escrow is a hard stack |
| Market readiness | 3/10 | Do agents with wallets even exist yet? |
| Execution readiness | 2/10 | Stalled 30 days, no code, no interviews |

**Overall:** 🔶 **Proceed with caution.** The bet is on a future that hasn't arrived yet. The cheapest test (5 developer interviews) costs nothing and answers the existential question. Run that this week before writing any code.
