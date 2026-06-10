# Product Brief — PP-001: SkillLedger MVP

> **Stage:** Handoff
> **Source:** IS-002 (Approved, Consensus 0.85)
> **Inspired:** #3 (ideas are starting points), #4 (solve problems), #42 (deep customer understanding)

## 1. Identity

- **PP-ID:** PP-001
- **Source Idea:** IS-002 — SkillLedger: On-Chain Agent Skill Marketplace
- **Status:** handoff
- **Priority:** P1
- **Created:** 2026-04-27
- **Updated:** 2026-04-27
- **Working Backwards v2:** Complete. Decision: GO. 0 kill triggers. Full run: `obsidian/working-backwards/runs/2026-04-27-IS-002-skillledger.md`
- **Discovery Stage:** Active (2026-04-27). Tests designed and queued. See `03-discovery.md`

## 2. Elevator Pitch

> For **autonomous agents with crypto wallets** who need to buy verified skills from other agents, **SkillLedger** is a **verified skill marketplace with author accountability** — buyers pay for executable skills, and authors stake bonds that get slashed if the execution fails or returns wrong results. Unlike **trust-based directories or free skill sharing**, SkillLedger provides cryptographically verifiable execution with financial accountability.

## 3. Problem Statement

**The user problem we're solving:**
Agents need services from other agents (compute, API access, data retrieval, specialized reasoning). Today there's no way for an agent to pay another agent for a discrete, verifiable service. The market doesn't exist because the trust/verification dilemma can't be solved with current tools.

**Evidence this is real:**
- IS-002's Ideation R1 produced 18 solutions across 3 models — all independently concluded "verification is the blocker"
- Consensus 0.85 across all models on the core thesis
- 205 prospect micro-audits all document trust concerns about non-deterministic AI behavior
- No existing solution: fiat marketplaces can't settle dynamically; crypto marketplaces don't do deterministic verification

**What happens if we don't build this?**
Agent-to-agent commerce stays limited to free/open services. The A2A economy never gets a payment layer. Trust remains the bottleneck for any agent selling services to other agents.

## 4. Target Persona

**Primary persona:** Independent agent operator / agent developer
- Who they are: Developers building autonomous agents that run 24/7, consume external services, and participate in agent networks (LangChain, CrewAI, AutoGen ecosystems)
- Goals: Monetize their agent's capabilities, buy reliable micro-services from other agents, create passive income streams
- Pain points: Can't charge or pay other agents; have to build custom billing; no trust model for agent-to-agent payments
- Current solution/workaround: Hardcoded API keys, shared wallets, manually invoiced — doesn't scale

**Secondary persona:** Enterprise AI platform (Phase 2+)
- Multi-agent orchestrator operators who need auditable inter-agent settlements
- Different needs: compliance, audit trails, cost allocation per department

## 5. Success Metrics (North Star)

**North star metric:** **Total value settled through SkillLedger** (volume that flows through the system)

**Leading indicators** (movement within weeks):
- 10 active agent pairs using escrow settlement
- Avg settlement time < 5 minutes
- 0 escrow disputes escalated to human review
- Developer NPS > 40

**Lagging indicators** (movement within months):
- 50+ unique agents registered
- €10K+ total value escrowed
- Repeat usage rate > 70% (agents that settle again)

**Counter-metrics:**
- Settlement failure rate (should stay < 1%)
- Dispute rate (should stay < 5% of transactions)

## 6. Product Vision

> SkillLedger becomes the default settlement layer for the agent economy. Any agent that discovers another agent via IS-001's directory can settle payments through SkillLedger with cryptographic guarantees. By Phase 3, it handles millions of micro-transactions per day across thousands of agent pairs, with enterprise-grade compliance for regulated industries.

## 7. Opportunity Assessment

| Factor | Score | Notes |
|--------|-------|-------|
| Market size (TAM) | 5 | Every agent-to-agent transaction needs settlement. TAM = total agent economy |
| Urgency | 4 | First-mover opportunity. Google/Microsoft building A2A but not settlement layer |
| Strategic fit | 5 | Backbone infrastructure for the entire agent ecosystem we're building |
| Technical feasibility | 3 | TEE attestation + deterministic execution is hard but proven technology |
| Business impact | 4 | Foundation for multiple product lines (SkillLedger → Audit → Attestation) |
| **Total** | **21/25** | **Clear Go** |

**Priority Score (ICE):** (4 × 5) ÷ 4 = 5.0 — Highest priority.

**Recommended timeline:** Immediate. Phase 0 (validation) this week.

---

## 8. Questions for Discovery

1. How do agents discover each other's services to buy? (IS-001 dependency)
2. What's the minimum viable "skill" that agents will pay for? (First use case)
3. Is TEE attestation available on the target runtimes our developer persona uses?
4. Will agent developers actually integrate a payment SDK, or is friction too high?
5. What's the minimum escrow amount that makes sense for agent micro-transactions?

## 9. Key Assumptions (to be tested)

| Assumption | Type | Risk Level | How to Test |
|------------|------|------------|-------------|
| Agents with wallets exist and want to transact | Value | High | Interview 10 agent developers |
| Deterministic skills are a useful category (not too narrow) | Value | High | Prototype + trial with 5 developers |
| TEE attestation is available on target runtimes | Feasibility | High | Technical spike: survey runtimes |
| SDK integration takes < 30 min | Usability | Med | Build SDK mock + time 3 developers |
| Agents will pay for skills they can verify cryptographically | Viability | Med | Pricing test: would they pay €0.01/call? |
| Human-checkpoint approval is acceptable overhead | Usability | Med | Prototype the checkpoint flow + test |

## 10. Stakeholders

| Role | Person/Team | What they care about |
|------|-------------|---------------------|
| PM | Orchestrator | Product-market fit, viability |
| Design | Orchestrator | Developer UX, agent UX |
| Engineering | Orchestrator | TEE integration, smart contracts |
| IS-001 (Sister product) | Orchestrator | Agent discovery → Settlement handoff |
| IS-007 (Sister product) | Orchestrator | Attestation layer compatibility |
| GTM | Orchestrator | First 10 agent pairs |

---

## 11. Version History

| Date | Author | Change |
|------|--------|--------|
| 2026-04-27 | Orchestrator | Initial handoff from IS-002 |
