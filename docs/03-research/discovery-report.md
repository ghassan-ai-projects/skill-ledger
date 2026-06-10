# Discovery Report — PP-001: SkillLedger

> **Stage:** Discovery
> **Date:** 2026-04-27
> **Method:** Assumption mapping + risk quadrant analysis + market signals + cheapest test design
> **Framework:** JTBD, Risk Quadrants, Mom Test preparation
>
> **Pre-gate:** Working Backwards v2 completed. 0 kill triggers. GO decision.

---

## 1. Assumption Wall

All assumptions grouped by type, sorted by risk level.

### 🔴 High Risk / High Uncertainty (Must test first — these kill the idea)

| # | Assumption | Why It Matters | Source |
|---|-----------|---------------|--------|
| A1 | Agents with wallets exist and *want to* transact with other agents programmatically | If no one needs this, nothing else matters | WB Inversion |
| A2 | Deterministic skills (code exec, SQL, API orchestration) are a sufficiently large market category | If too narrow, TAM is too small | WB FAQ |
| A3 | Agents will pay for skills they can verify cryptographically (vs. free/trust-based) | Core revenue hypothesis | Handoff |
| A4 | Developer SDK integration takes < 30 minutes for a working skill deploy | If friction > 30 min, adoption dies | Handoff |

### 🟡 Medium Risk (Test before spec)

| # | Assumption | Why It Matters | Source |
|---|-----------|---------------|--------|
| A5 | TEE attestation is available on runtimes agent developers actually use | Technical feasibility gate | WB FAQ |
| A6 | Optimistic verification (24-48h challenge window) is acceptable for agent workloads | UX of settlement finality | WB Decision Tree |
| A7 | Human-checkpoint approval is tolerable (not a blocker) | MVP requires this for Phase 1 | Handoff |
| A8 | 1-3% escrow fee is acceptable for target transaction sizes | Business model viability | WB Inversion |
| A9 | L2 gas costs on Arbitrum can keep per-tx cost < $0.001 | Must match or beat centralized alternatives | WB FAQ |

### 🟢 Low Risk (Document, don't test yet)

| # | Assumption | Why It Matters | Source |
|---|-----------|---------------|--------|
| A10 | Multi-agent architectures will be heterogeneous (cross-framework) | If all agents use one framework, skill market shrinks | WB FAQ |
| A11 | Agents are long-running (days/weeks) not ephemeral | Transaction volume depends on agent lifespan | WB Inversion |
| A12 | Dispute rate stays < 5% | Core UX assumption for optimistic model | WB Decision Tree |

---

## 2. Risk Quadrant Analysis

Mapping assumptions by:
- **How important** (critical to viability vs. nice to confirm)
- **How uncertain** (high confidence vs. pure guess)

```
                      HIGH IMPORTANCE
                           │
                           │
         A1 (agents exist) │   A4 (SDK < 30 min)
         A2 (market size)  │   A5 (TEE available)
         A3 (will pay)     │   A6 (optimistic OK)
                           │
    LOW CONFIDENCE ────────┼────────────────── HIGH CONFIDENCE
                           │
                           │
         A8 (1-3% fee OK)  │   A10 (heterogeneous)
         A9 (gas < $0.001) │   A11 (long-running)
         A7 (human check)  │   A12 (dispute < 5%)
         A9 (developer UX) │
                           │
                      LOW IMPORTANCE
```

**The Critical Quadrant (High Importance + Low Confidence) — Must test IMMEDIATELY:**

1. **A1: Agents with wallets want to transact** — If this is wrong, stop everything.
2. **A2: Deterministic skills are a useful category** — If too narrow, rebuild positioning.
3. **A3: Agents will pay for verified execution** — If no willingness to pay, no business.
4. **A4: SDK takes < 30 minutes** — If friction kills adoption, redesign onboarding.
5. **A5: TEE available on target runtimes** — If not, MVP architecture changes.
6. **A6: Optimistic 24-48h is acceptable** — If not, verification strategy needs redesign.

---

## 3. JTBD Analysis (Jobs to Be Done)

### Primary Job: "Hire an agent skill programmatically without human overhead"

**Functional:**
- Find an agent that offers the skill I need
- Pay for it without a bank account or Stripe
- Get verified execution with recourse if it fails
- Integrate in < 30 minutes without blockchain expertise

**Emotional:**
- Feel confident the other agent will deliver (trust at scale)
- Don't feel stupid if I get scammed (economic safety)
- Feel like a sophisticated operator (status: early adopter of A2A economy)

**Social:**
- My agent can transact with any other agent (network access)
- I'm part of the agent economy, not watching from outside

### Secondary Job: "Monetize my agent's skills without building a payment system"

**Functional:**
- List my agent's capability as a skill others can buy
- Get paid automatically without invoicing
- Prove my agent actually performed the work (verification)

**Emotional:**
- Fair compensation without a middleman taking 30%
- Recognition for the value my agent provides
- Don't get cheated by dishonest buyers

---

## 4. User Interview Plan (Mom Test Preparation)

### Who to Interview

**Tier 1 (High Signal, Must Interview First):**
1. Agent developer building multi-agent pipelines (LangChain/CrewAI power users)
2. Crypto-native developer who's tried agent-to-agent payments
3. Independent agent operator with monetization ambitions

**Tier 2 (Supporting Signal, Interview After Tier 1):**
4. Enterprise AI platform (potential Phase 2 customer)
5. Smart contract developer interested in agent economics
6. Founder of an agent-first startup

### Questions (Mom Test — talk about *them*, not our idea)

**Opening (establish context):**
- "Tell me about the last time one of your agents needed something from another agent." 
- "How do your agents pay for services today? Walk me through the process."
- "What's the most frustrating part of running a multi-agent pipeline?"

**Explore the problem (don't pitch):**
- "How do you handle trust when one agent depends on another?"
- "What happens when an agent you hired doesn't deliver what it promised?"
- "Have you ever wanted to charge another agent for something your agent does?"

**Test the solution (carefully, after problem is established):**
- "If I could wave a wand and make agent-to-agent payments work with cryptographic proof, what would that change about how you build?"
- "What would need to be true for you to integrate a payment SDK into your agent pipeline?"
- "What's the minimum capability a skill needs before you'd pay another agent for it?"

**Inversion questions (test the failure modes):**
- "What would make you NOT integrate an agent payment system?"
- "What would make this feel like a toy, not a real tool?"
- "When would you tell another developer NOT to use this?"

### Signal vs. Noise

| Signal (Believe) | Noise (Ignore) |
|-----------------|----------------|
| "I spent 3 hours last week trying to make two agents settle payments" | "That sounds cool, I'd use it" |
| "Here's exactly what I'd build if I had your solution" | "Great idea!" |
| "The biggest problem is [specific technical/trust issue]" | "The market is huge for this" |
| Concrete numbers: "I'd pay €X per call for skill Y" | Vague: "I'd definitely pay for this" |
| Stories about failures: "My agent got burned when [specific incident]" | Hypothetical: "I could see this being useful" |

---

## 5. Cheapest Test Design

### Test 1: Agent Existence & Willingness (A1 + A3)

**Method:** Run the interview plan above with 6 Tier 1 candidates (2 agent devs, 2 crypto devs, 2 independent operators). Measure:

- **Pass:** ≥ 4/6 describe a *real, specific* pain around A2A payments or trust
- **Strong pass:** ≥ 2/6 have *attempted* to solve this themselves (custom code, hacky workaround)
- **Fail:** ≤ 2/6 can describe a real pain. Most say "sounds interesting but haven't thought about it"

**Timeline:** 3 days
**Cost:** Time to find and interview 6 people

### Test 2: SDK Friction (A4)

**Method:** Build a dummy SDK for one agent framework (LangChain). One command to "deploy" a skill. Hand it to 3 developers. Time them from "here's the SDK" to "I have a working skill deployed." Do not help them unless they're truly stuck. Record: time, confusion points, questions asked.

- **Pass:** All 3 complete within 30 minutes without major confusion
- **Strong pass:** Average < 15 minutes. No direct help needed.
- **Fail:** Any developer takes > 1 hour or gives up

**Timeline:** 1 week (build SDK mock + run test)
**Cost:** ~2 days dev time for SDK mock

### Test 3: Market Scope (A2)

**Method:** Present 10 deterministic skill categories to 5 agent developers. For each: "Would one of your agents pay another agent for this? How much? How often?"

Categories to test:
1. Code execution (run arbitrary code, return output)
2. SQL query execution (run query against database, return results)
3. API orchestration (call an external API, return transformed data)
4. Data format conversion (JSON → CSV, XML → Parquet)
5. Web scraping (fetch and structure content from URL)
6. Image processing (resize, compress, format convert)
7. Text extraction (summarize, key entity extraction, structure)
8. Model inference (run a small model on a specific task)
9. Contract parsing (extract terms from legal/commercial docs)
10. Monitoring alert processing (deduplicate, enrich, route alerts)

- **Pass:** ≥ 5/10 categories score "would pay" from ≥ 3/5 developers
- **Strong pass:** ≥ 7/10 categories score "would pay" and at least 2 are "would pay frequently (daily+)"
- **Fail:** ≤ 3/10 categories score "would pay." Market is too narrow.

**Timeline:** 1 week
**Cost:** 30-minute survey per developer

### Test 4: TEE Availability on Target Runtimes (A5)

**Method:** Technical spike. Survey the 5 most common agent deployment runtimes (AWS Lambda, GCP Cloud Run, fly.io, Railway, local Docker) for TEE attestation support. Are Intel SGX / AMD SEV / NVIDIA Confidential Computing available? Is there a simple API to attest execution?

- **Pass:** At least 2/5 runtimes support TEE via straightforward API
- **Strong pass:** At least 3/5, and the simplest (local Docker) has a TEE plugin
- **Fail:** 0-1/5. TEE strategy needs redesign (pure optimistic for longer)

**Timeline:** 2 days
**Cost:** Research time + test deployment

---

## 6. Discovery Execution Plan

### Week 1 (Current)

| Day | Activity | Deliverable |
|-----|----------|-------------|
| 1 | Run Test 4: TEE availability (technical spike) | TEE compatibility matrix |
| 1-3 | Find Tier 1 interview candidates | Interview queue (6 candidates) |
| 2-4 | Conduct interviews (3 sessions) | Interview transcripts |
| 5 | Conduct remaining 3 interviews | Interview transcripts |
| 5 | Run Test 2 prep: Build SDK mock | SDK mock package |

### Week 2

| Day | Activity | Deliverable |
|-----|----------|-------------|
| 1-2 | Run Test 2: SDK friction test with 3 developers | SDK time measurements |
| 2-3 | Run Test 3: Market scope survey with 5 developers | Category scoring matrix |
| 3-4 | Synthesize all findings | Discovery synthesis report |
| 5 | Go/Pivot/Kill decision based on evidence | Decision (validate.go.md) |

---

## 7. What We Need to Learn Before Spec

1. **Do agents exist?** (A1) — Interview signal. Real pain or hypothetical?
2. **What's the first skill category?** (A2) — Which of the 10 categories scores highest on willingness-to-pay?
3. **What's the acceptable friction?** (A4) — SDK integration time. If > 30 min, redesign.
4. **Can we build the verification layer?** (A5) — TEE availability on target runtimes.
5. **What's the willingness to pay?** (A3) — Price sensitivity from Test 3 survey.
6. **Is optimistic settlement OK?** (A6) — Developer tolerance for 24-48h challenge window.

### Minimum Viable Learning

We don't need all answers. We need the *first three*:
1. Real agents with real agent-to-agent payment pain exist? (A1)
2. At least one deterministic skill category has willingness-to-pay signal? (A2)
3. SDK friction is below 30-minute threshold? (A4)

**If these three are confirmed → Proceed to Spec.**
**If any fails → Pivot (narrower scope, different positioning) or Kill.**

---

## 8. Risk Register (Updated from Working Backwards)

| Risk | Likelihood | Impact | Status | Trigger | Response |
|------|-----------|--------|--------|---------|----------|
| Agent adoption too slow | Medium | Critical | 🔴 Monitor | < 4/6 interviews describe real pain | Pivot to enterprise API settlement |
| Deterministic scope too narrow | Medium | Significant | 🟡 Unknown | < 5/10 categories score "would pay" | Expand market scope or redefine persona |
| TEE unavailable on target runtimes | Medium | High | 🟡 Unknown | < 2/5 runtimes support TEE | Pure optimistic for MVP. TEE deferred. |
| SDK friction too high | Low | High | 🟡 Unknown | Integration time > 30 min | Redesign SDK. Simpler deploy. |
| Centralized competitor beats us | Medium | Critical | 🟢 Accept | Announced by Q3 2026 | Differentiate on trustlessness + permissionlessness |

---

## 9. Discovery Artifacts

- [ ] Interview transcripts (Tier 1, n=6)
- [ ] SDK friction measurement report (n=3)
- [ ] Market scope survey results (n=5)
- [ ] TEE availability matrix (target runtimes)
- [ ] Discovery synthesis (this document updated with findings)
- [ ] Go/Pivot/Kill decision

**Next step after discovery:** Stage 4 — Validate (if Go) or Iterate/Kill (if not).
