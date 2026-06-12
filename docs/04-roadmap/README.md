# SkillLedger Roadmap

## Current Direction

SkillLedger is being refocused around verified skill publication, artifact acquisition, and local buyer-side execution. The current strategic plan is:

1. finish the acquisition refactor away from hosted execution
2. make MCP the primary agent contract for both publishers and buyers
3. keep REST as a compatibility/admin surface until MCP is mature enough to stand on its own

Use these documents for active planning:

- [Next-Level Plan - 2026-06-12](./next-level-plan-2026-06-12.md)
- [MCP-First Migration Plan](./mcp-first-migration-plan.md)
- [Implementation Tracker](./implementation-tracker.md)
- [Refactor Plan — Client-Side Skill Acquisition Model](./refactor-plan-client-side-acquisition.md)
- [Detailed Refactor Execution Plan](./detailed-refactor-execution-plan.md)

## Historical Roadmap

The phase-by-phase roadmap below records the earlier hosted-execution implementation path. It is useful project history, but it should not be treated as the current product direction.

When the historical roadmap conflicts with the MCP-first acquisition model, prefer the active planning docs above.

## Completed Phases

| Phase | Description | Status | Git Commits |
|-------|-------------|--------|-------------|
| Phase 1 | Core data model (Accounts, Ledger, Skills, Executions) + seeds | ✅ | `9a5665d Phase 1` |
| Phase 2 | API controllers under Api::V1, CRUD, execution endpoints | ✅ | `2d3857a Phase 2` |
| Phase 3 | Trust/verification — slash author stake + refund on fail, reports | ✅ | `17c42de`, `417710e` |
| Phase 4 | Polish — error handling, logging, README, tests (78+) | ✅ | `856e77f`, `bf89967`, `a09898f` |
| Phase 5 | Auth (API keys), search/filter/pagination, webhooks | ✅ | `f4d14d1`–`6ddb862` |
| Phase 6 | Reviews, analytics dashboard, favorites & library | ✅ | `ea85722`–`4c16d63` |
| Phase 7 | Service extraction, OpenAPI docs, CI fix | ✅ | `4395869` |

---

## Built Features

### Data Layer
- [x] Account model with balance + API key auth
- [x] LedgerEntry (immutable audit trail for every transaction)
- [x] Skill model with stake_amount, price_per_call, webhook_url
- [x] Execution model (pending → completed/failed flow)
- [x] Review model (1-5 star rating, unique per execution)
- [x] Favorite model (bookmarking skills)

### API Endpoints
| Endpoint | Purpose |
|----------|---------|
| `GET/POST /api/v1/skills` | List (w/ search, filter, sort, pagination) / Create skills |
| `GET /api/v1/skills/:id` | Skill detail with ratings & favorites |
| `POST /api/v1/skills/:id/execute` | Execute a skill |
| `GET /api/v1/executions` | List executions |
| `PATCH /api/v1/executions/:id/fail` | Mark execution as failed (slash + refund) |
| `GET /api/v1/ledger` | List all ledger entries |
| `GET /api/v1/reports` | Summary statistics |
| `POST /api/v1/executions/:id/review` | Create a review |
| `GET /api/v1/skills/:id/reviews` | List reviews for a skill |
| `GET/POST/DELETE /api/v1/favorites` | Favorite management |
| `GET /api/v1/me/library` | Personal library |
| `GET /api/v1/authors/:id/analytics` | Author analytics dashboard |
| `GET /api/v1/authors/:id/earnings` | Earnings breakdown |

### Infrastructure
- [x] API key authentication (`X-API-Key` header)
- [x] Consistent error JSON shape
- [x] Lograge-style request logging
- [x] Webhook integration (execution.completed / execution.failed)
- [x] OpenAPI/Swagger spec (`openapi.yaml`)
- [x] CI pipeline (GitHub Actions)
- [x] Dockerfile + Kamal deploy config
- [x] 78+ passing tests

---

## Phase 7 — Backlog (Not Yet Built)

| # | Feature | Value | Complexity | Priority |
|---|---------|-------|------------|----------|
| 22 | Skill Versions & Changelog | Medium | Medium | 🟡 Next |
| 23 | Escrow & Dispute Resolution | High | High | 🔴 High |
| 24 | Referral & Bonus Credits | Low | Low | 🟢 Nice |
| 25 | Activity Feed | Medium | Low | 🟢 Nice |
| 26 | Scheduled & Recurring Executions | Medium | High | 🟡 Next |

### Feature 22: Skill Versions & Changelog
- Add `version` column to skills (integer, default 1)
- `skill_versions` table snapshots state before updates
- Executions reference `skill_version_id`
- Changelog notes per version

### Feature 23: Escrow & Dispute Resolution
- Escrow holding on execution, not immediate settlement
- Dispute raising with evidence text
- Admin resolution (refund_buyer / pay_author / split)
- Escrow statuses: `pending`, `failed_escrow`, `disputed`, `resolved_refund`, `resolved_author`

### Feature 24: Referral & Bonus Credits
- Auto-generated referral codes
- Welcome bonuses + referrer credits for new accounts
- Ledger entries for referral bonuses
- Anti-gaming (max 10 referrals/day)

### Feature 25: Activity Feed
- Composite query across skills, reviews, accounts
- Sections: new skills, trending, top-rated, recent reviews, new authors
- Cached (60s)

### Feature 26: Scheduled & Recurring Executions
- Cron expressions per schedule
- `scheduler:tick` rake task
- Auto-disable after 3 consecutive failures
- Insufficient credits → skip, don't crash

---

## Beyond MVP — Future Vision

### Phase 8: Real Cryptography
- Optimistic verification with challenge period
- TEE attestation integration (Intel SGX, AMD SEV, Nitro Enclaves)
- Hybrid routing (optimistic for low-value, TEE for high-value)

### Phase 9: Agent Framework SDKs
- LangChain plugin
- CrewAI integration
- One-command skill deploy

### Phase 10: Multi-Chain
- Deploy on L2 (Arbitrum/Base)
- Cross-chain bridge strategy
- Gas abstraction (EIP-4337)

### Phase 11: Attestation Layer (IS-007)
- Proof of correct execution
- ZK compression for selective disclosure
- Transparency log for auditability

### Phase 12: SLA Registry (IS-005)
- Machine-readable SLAs during discovery
- Dual-signature hash chains
- On-chain settlement on threshold violations
