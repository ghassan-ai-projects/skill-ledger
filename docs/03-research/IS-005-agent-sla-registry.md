---
idea-id: "IS-005"
title: "Agent SLA Registry & Fault Resolution Gateway"
status: "ideation"
priority: "P2"
stage: "ideation"
created: "2026-04-27"
updated: "2026-04-27"
source: "Idea Engine — Run 2026-04-27, Lens A: Gap Analyst (adjacent gap in IS-001 tension map)"
type: "adjacent"
consensus: 0.88
tags: [engine-generated, adjacent, sla, agents, marketplace]
---

# IS-005: Agent SLA Registry & Fault Resolution Gateway

## 1. Problem

> IS-001 builds an A2A agent directory and escrow bridge, but explicitly defers SLA monitoring to Phase 2 ("Thick"). IS-002 handles execution correctness (did the skill run right?) but not operational SLAs (was it under 200ms?). No existing A2A marketplace provides runtime SLA guarantees for agent-to-agent service calls.

**Problem Statement:**
- Agent buyers in IS-001's directory have no idea if a listed agent will actually meet latency, uptime, or accuracy promises
- IS-002's escrow only covers the binary "did the skill run?" — not quality of service
- Without pre-defined SLAs, agents can't make informed purchasing decisions
- SLA breaches have no automatic recourse mechanism built into the agent economy

## 2. Initial Thoughts

**Concept:** A Dual-Phase SLA Gateway that sits between IS-001 (discovery) and IS-002 (payment). Agents declare machine-readable SLAs at listing time. Every interaction logs locally with dual-signature hash chains. Only threshold violations trigger on-chain settlement.

**How it works (Phase 1 — Off-chain):**
- Agents negotiate SLAs during discovery (latency P99, uptime %, accuracy floor)
- Both agents log each interaction with dual-signature hash chain (structured as Merkle tree of SLA measurements)
- Logs stored off-chain (IPFS/blob) with root hash published to registry
- Reputation bonds handle sub-threshold breaches

**How it works (Phase 2 — On-chain):**
- When threshold violation occurs (e.g., response time exceeds P99 SLA by 2x), aggrieved agent submits Merkle path to stateless on-chain resolver
- Resolver validates proof against SLA terms declared in DID document
- Triggers escrow adjustment: partial refund to consumer, slash to provider reputation bond
- No oracle, no jury, no dispute — pure cryptographic proof

**Key requirement:** Agents have economic incentive to log honestly — bond at stake exceeds any gain from cheating on a single interaction.

**Falsifiable test:** If 10 agent developers shown a 30-second demo say "I don't want agents to have this much visibility into my runtime," the adoption thesis is wrong.

## 3. Ideation Log

**Status:** Ideation R1 (Divergent) complete — 20 solutions from 3 models.
**Status:** Ideation R2 (Convergent) complete — winner selected at 0.88 consensus.

### Round 1 Solutions Summary (Divergent)

**Lens A — DeepSeek (Technical):** 6 solutions spanning trust models from fully on-chain to off-chain hybrid:
1. On-Chain SLA Registry + Multi-Sig Oracle Panel
2. Peer-Monitored SLA with Reputation Bonds (No Oracles)
3. **► Hybrid: Off-Chain SLA Log + On-Chain Settlement on Threshold Violations (WINNER)** 
4. Aggregator Gateway (Hub-and-Spoke SLA Proxy)
5. Reputation-Only Penalties (No Financial Slashing)
6. SLA Futures Market (Economic Incentive, Not Enforcement)

**Lens B — Gemini (Market/Adoption):** 7 solutions focusing on developer adoption:
1. "SLA-as-a-Decorator" SDK (DevEx — one-line decorator)
2. "Insured Escrow" Gateway (auto-refund on breach)
3. "Verified Performance" Leaderboard (SEO ranking)
4. "SLA-Tiered" Pricing API
5. "Zero-Config" Proxy (Cloudflare-for-Agents)
6. "Proof of Stake" Quality Bond
7. "SLA.yaml" Crawler (robots.txt for agents)

**Lens C — Kimi (Creative):** 7 non-obvious solutions:
1. Prediction Market (market IS the monitor)
2. P2P Agent Jury (random agents vote on disputes)
3. SLA as Discovery Prerequisite (mandatory DID field)
4. Reputation Token Secondary Market
5. Post-Facto Arbitration Only ("Uber model")
6. Cooperative Guild System (cross-staking coalitions)
7. Irreversible Bonding ("Anti-SLA")

### Round 2 Convergence

**Winner: Hybrid: Off-Chain SLA Log + On-Chain Settlement on Threshold Violations (consensus 0.88)**

**Rationale:** Uniquely satisfies the three positional constraints (between discovery and payment). Off-chain log integrates naturally with agent telemetry. On-chain settlement hooks into IS-002 escrow. No oracle dependency (log is dual-signed by both agents; threshold violations trigger settlement). Maps to actual cost structure of agent economies: many cheap calls, few expensive failures.

**Design recommendation:** A Dual-Phase SLA Gateway — lightweight SDK/service embedded during discovery negotiation. Phase 1: both agents locally log interactions as dual-signature hash chains (Merkle trees of SLA measurements). Phase 2: threshold violations trigger stateless on-chain resolver that validates Merkle path against DID-declared SLA terms and adjusts escrow.

**Key open question:** What sets the on-chain settlement threshold? Per-agent → set high to avoid risk (system reduces to reputation-only). Global minimum → wrong for micro-work or complex tasks. Progressive sliding scale based on interaction value → creates game-theoretic meta-problem of mis-declared value.

**Adjacent idea worth tracking:** Cooperative Guild System (Lens C #6). Cross-staking coalitions solve the cold-start problem: new agents join guilds that pool bond stakes and provide collective SLA coverage. Guild reliability score becomes a market signal. Natural second-layer protocol on top of the off-chain log structure.

---

## 4. Validation

**Status:** Pending. Ready for Lean Canvas / competitive analysis.

---

## 5. Decision

**Status:** Pending.

---

## 6. Activity Log

| Date | Action | Notes |
|------|--------|-------|
| 2026-04-27 | Idea captured | Idea Engine Run 1 — adjacent gap: IS-001 defers SLA monitoring |
| 2026-04-27 | Ideation R1 | 20 solutions from DeepSeek + Gemini + Kimi |
| 2026-04-27 | Ideation R2 | Converged: Hybrid Off-Chain Log + On-Chain Settlement. Consensus 0.88 |
