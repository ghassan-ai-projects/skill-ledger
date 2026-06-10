# Product Brief — PP-001: SkillLedger

> **Stage:** Handoff → Discovery → Build  
> **Source:** IS-002 (Approved, Consensus 0.85)  
> **Status:** MVP Complete (Phase 4)  
> **Priority:** P1 (ICE Score: 5.0)

---

## Elevator Pitch

> For **autonomous agents with crypto wallets** who need to buy verified skills from other agents, **SkillLedger** is a **verified skill marketplace with author accountability** — buyers pay for executable skills, and authors stake bonds that get slashed if the execution fails or returns wrong results. Unlike **trust-based directories or free skill sharing**, SkillLedger provides cryptographically verifiable execution with financial accountability.

---

## Problem Statement

Agents need services from other agents (compute, API access, data retrieval, specialized reasoning). Today there's no way for an agent to pay another agent for a discrete, verifiable service. The market doesn't exist because the trust/verification dilemma can't be solved with current tools.

**What happens if we don't build this?**  
Agent-to-agent commerce stays limited to free/open services. The A2A economy never gets a payment layer.

---

## Target Persona

**Primary:** Independent agent operator / agent developer  
- Building autonomous agents (LangChain, CrewAI, AutoGen ecosystems)  
- Needs to monetize agent capabilities, buy micro-services  
- Pain point: Can't charge or pay other agents programmatically

**Secondary:** Enterprise AI platform (Phase 2+)  
- Multi-agent orchestrator operators needing auditable inter-agent settlements

---

## Opportunity Assessment

| Factor | Score | Notes |
|--------|-------|-------|
| Market size (TAM) | 5 | Every A2A transaction needs settlement |
| Urgency | 4 | First-mover opportunity |
| Strategic fit | 5 | Backbone infrastructure for agent ecosystem |
| Technical feasibility | 3 | TEE + deterministic execution is hard but proven |
| Business impact | 4 | Foundation for multiple product lines |
| **Total** | **21/25** | **Clear Go** |

---

## Key Assumptions (from Discovery)

| # | Assumption | Risk | Status |
|---|------------|------|--------|
| A1 | Agents with wallets exist and want to transact | 🔴 High | ❌ Not validated |
| A2 | Deterministic skills are a useful category | 🔴 High | ❌ Not validated |
| A3 | Agents will pay for verified execution | 🔴 High | ❌ Not validated |
| A4 | SDK integration takes < 30 min | 🔴 High | ❌ Not validated |
| A5 | TEE available on target runtimes | 🟡 Medium | ❌ Not validated |
| A6 | Optimistic 24-48h settlement is acceptable | 🟡 Medium | ❌ Not validated |

> **Status note (2026-06-10):** The above assumptions from the product review remain untested. The Rails MVP was built (Phases 1-6) without validating the core value assumptions. This is the gap to close before continuing.

---

## Success Criteria (MVP Built)

- ✅ Rails app starts with `rails s`
- ✅ Seed data creates 5 agents with balances
- ✅ Can create a skill via POST /skills
- ✅ Can execute a skill via POST /skills/:id/execute
- ✅ Execution failure triggers stake slash + buyer refund
- ✅ Ledger shows every transaction
- ✅ Review, favorites, library, analytics endpoints
- ✅ 78+ passing tests
- ✅ OpenAPI/Swagger docs
- ✅ Webhook integration
- ✅ README with full API documentation
