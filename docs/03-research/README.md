# Research Index

This directory contains the foundational research and analysis that led to SkillLedger.

---

## Documents

### IS-002: SkillLedger — On-Chain Agent Skill Marketplace (Original Idea)
- **File:** [IS-002-skillledger.md](./IS-002-skillledger.md)
- **Source:** Idea Engine, 2026-04-27
- **Content:** Full idea capture with 5 structural criticisms, pivot analysis, ideation rounds (18 candidates → 1 winner at 0.85 consensus), Lean Canvas, risk matrix
- **Key takeaway:** The idea survived multi-model ideation and Ghassan's 5 structural criticisms through a sharp pivot from "consumer marketplace" to "payment & accountability layer for multi-agent ecosystem."

### 2026-04-27 Working Backwards (Full Engine)
- **File:** [working-backwards-full.md](./working-backwards-full.md)
- **Source:** PP-001 working backwards v2 run
- **Content:** All 7 stages: End State → Press Release → FAQ → Inversion → Backward Chain → Decision Tree → Execution Plan
- **Key takeaway:** 0 kill triggers. Key decisions locked: deterministic only, Arbitrum first, optimistic for MVP.

### Discovery Report
- **File:** [discovery-report.md](./discovery-report.md)
- **Source:** PP-001 discovery stage
- **Content:** Assumption wall (12 assumptions, risk-ranked), quadrant analysis, JTBD analysis, user interview plan (Mom Test), cheapest test design, risk register
- **Key takeaway:** 4 high-risk assumptions need testing before any code should have been written.

### Product Review (2026-05-28)
- **File:** [product-review.md](./product-review.md)
- **Source:** Post-MVP retrospective
- **Content:** Honest assessment of what exists vs. what's validated, prioritization for next phase
- **Key takeaway:** Great codebase, zero market validation. Recommended: shrink to cheapest test, validate with 5 developer interviews before building further.

### SkillLedger v1 Research Synthesis (2026-06-19)
- **File:** [skillledger-v1-research-synthesis-2026-06-19.md](./skillledger-v1-research-synthesis-2026-06-19.md)
- **Source:** Deep research package at `~/ai-projects/projects/skill-ledger-deep-research/v1/`
- **Content:** Synthesis of the corrected v1 direction: verified artifact registry, local execution, MCP-first acquisition, optional Web3 adapters, ALMS bridge, LLM competition, and near-term market test.
- **Key takeaway:** v1 is stronger than the old on-chain escrow thesis, but must prove verified skill reuse beats free LLM generation for complex, edge-case-heavy skills.

### Handoff Document
- **File:** [handoff.md](./handoff.md)
- **Source:** PP-001 → Product Planner
- **Content:** Identity, elevator pitch, personas, success metrics, stakeholders

### Adjacent Ideas
- **IS-005:** [Agent SLA Registry & Fault Resolution Gateway](./IS-005-agent-sla-registry.md) — machine-readable SLAs, dual-signature hash chains, on-chain settlement on threshold violations
- **IS-007:** [Agent Execution Attestation Layer](./IS-007-agent-attestation-layer.md) — lightweight sidecar wrapping agent actions with verifiable execution proofs (TEE → ZK → Transparency Log hybrid)

---

## Key Insights for Next Phase

1. **Current direction:** SkillLedger v1 is a verified skill artifact registry with local acquisition, not a hosted execution or on-chain escrow platform.
2. **Market validation gap:** The Rails MVP is built, but the core assumption remains untested: users must prefer verified reusable skills over free LLM-generated one-offs for at least some important categories.
3. **First priority:** Ship anchor skills, measure real acquisition behavior, and interview users who publish or acquire skills.
4. **Scope for next build phase:** Strengthen artifact schema, verification records, structured capability discovery, MCP purchase/acquire flows, and buyer-side verification tooling before external proof or payment adapters.
