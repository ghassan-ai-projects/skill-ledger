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

### Handoff Document
- **File:** [handoff.md](./handoff.md)
- **Source:** PP-001 → Product Planner
- **Content:** Identity, elevator pitch, personas, success metrics, stakeholders

### Adjacent Ideas
- **IS-005:** [Agent SLA Registry & Fault Resolution Gateway](./IS-005-agent-sla-registry.md) — machine-readable SLAs, dual-signature hash chains, on-chain settlement on threshold violations
- **IS-007:** [Agent Execution Attestation Layer](./IS-007-agent-attestation-layer.md) — lightweight sidecar wrapping agent actions with verifiable execution proofs (TEE → ZK → Transparency Log hybrid)

---

## Key Insights for Next Phase

1. **Market validation gap:** The Rails MVP is fully built (Phases 1-6) but none of the core value assumptions (A1-A6) have been tested with real developers.
2. **First priority:** Interview 5-10 agent developers to confirm the problem exists before building Phase 7 features.
3. **Cheapest test:** 5 warm prospects from the 205 prospect micro-audits + LinkedIn survey polls designed in `06-marketing/`.
4. **Scope for next build phase:** Escrow & dispute resolution (Phase 7 Feature 2) is the highest-value unbuilt piece.
