# Architecture: SkillLedger MVP

A Rails API app for agent-to-agent skill publishing, discovery, purchase, and settlement. The "blockchain" is a local database-backed ledger. Single server, single tenant, no external APIs.

---

## Design Decisions

| Decision | Chosen | Rejected |
|----------|--------|----------|
| Rails mode | **API-only** (`rails new --api`). No views, cookies, session middleware. | Full-stack Rails — unnecessary complexity with no UI. |
| Database | **SQLite**. Zero-config, ships with Rails, sufficient for single-server single-tenant MVP. | PostgreSQL — adds setup/daemon overhead for zero benefit at this scale. |
| Module structure | **Namespaced models + service objects** under `app/`. Each domain (Accounts, Ledger, Skills, Executions, Reports) gets its own namespace. | Rails engines — mountable engines are overkill for a single-app codebase. |
| Stake handling | **Declared on skill; deducted on failure only.** The stake amount is stored on the Skill model. No upfront transfer. On execution failure, the author's current balance is debited by the stake, and the buyer is refunded. | Upfront escrow transfer — adds complexity (need to return on edit/delete) with no functional benefit. |
| Execution | **Synchronous.** Everything happens in the request-response cycle. | Background jobs (Sidekiq/ActiveJob) — no external API calls to wait on; sync is simpler and sufficient. |
| Authentication | **`X-API-Key` header (per-account API keys with bcrypt digest storage).** Stateless API auth for account-scoped access. | Session or cookie auth — unnecessary for this API-only app. |
| Testing | **Rails default (Minitest).** No RSpec or other frameworks. Ships with Rails, no extra dependency. | RSpec — adds a dependency with no benefit for this scale of app. |

---

## Components

### 1. Accounts (`app/models/account.rb`)
- **Responsibility:** Represents an agent with a name and balance.
- **State:** `name` (string), `balance` (decimal, non-negative)
- **Constraints:** Balance must never go negative (validated on every transfer).
- **Seed:** 3–5 agents with starting balances.

### 2. Ledger (`app/models/ledger_entry.rb`)
- **Responsibility:** Immutable record of every financial transaction.
- **State:** `from_account_id`, `to_account_id`, `amount` (decimal), `entry_type` (string — `payment`, `stake`, `slash`, `refund`), `timestamp`
- **Constraints:** Created inside a transaction alongside the actual balance updates. Read-only after creation.
- **Entry types:**
  - `payment` — buyer pays author for skill execution
  - `stake` — author's stake (conceptual; no upfront transfer, recorded at failure time)
  - `slash` — author's stake forfeited on failed execution
  - `refund` — buyer receives refund on failed execution

### 3. Skills (`app/models/skill.rb`)
- **Responsibility:** A published skill that agents can execute.
- **State:** `name` (string), `description` (text), `author_id` (FK to account), `stake_amount` (decimal), `price_per_call` (decimal)
- **Constraints:** Stake and price must be positive. Author must have sufficient balance to cover stake at creation time (checked, not transferred).

### 4. Executions (`app/models/execution.rb`)
- **Responsibility:** Records a single invocation of a skill by a buyer.
- **State:** `skill_id` (FK), `buyer_id` (FK to account), `status` (string — `completed` or `failed`), `result` (text, nullable), `timestamp`
- **Flow:** On creation, validates buyer has sufficient balance, debits buyer, credits author, records ledger entry. If marked as `failed`, triggers slash + refund.

### 5. Reports (service object: `app/services/reports/generate.rb`)
- **Responsibility:** Aggregate statistics across models.
- **Outputs:** Total skills, total executions, total slashed amounts, current ledger balance.

---

## Data Flow

### Create Skill
```
POST /skills
  → validate author exists, balance ≥ stake_amount
  → create Skill record
  → return skill JSON
```

### Execute Skill
```
POST /skills/:id/execute
  → validate skill exists, buyer exists
  → validate buyer.balance ≥ skill.price_per_call
  → Account.transaction do
       buyer.balance -= skill.price_per_call
       author.balance += skill.price_per_call
       LedgerEntry.create!(type: "payment", ...)
       Execution.create!(status: "completed")
     end
  → return execution JSON
```

### Failed Execution (explicitly set by API consumer or stubbed)
```
PATCH /executions/:id/fail
  → Account.transaction do
       author.balance -= skill.stake_amount      # slash
       buyer.balance += skill.stake_amount        # refund (covers lost payment too)
       buyer.balance += skill.price_per_call      # refund the payment
       author.balance -= skill.price_per_call     # reverse the payment credit
       LedgerEntry.create!(type: "slash", ...)
       LedgerEntry.create!(type: "refund", ...)
       execution.update!(status: "failed")
     end
  → return execution JSON
```

**Simpler alternative considered:** Deduct stake + refund in one combined entry. Rejected because separate entries give a clear audit trail.

---

## Key Interfaces (API)

All endpoints return JSON and require the `X-API-Key` header.

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/skills` | List all skills |
| `POST` | `/skills` | Create a skill |
| `GET` | `/skills/:id` | Show a skill |
| `POST` | `/skills/:id/execute` | Execute a skill |
| `GET` | `/executions` | List all executions |
| `PATCH` | `/executions/:id/fail` | Mark execution as failed (triggers slash + refund) |
| `GET` | `/ledger` | List all ledger entries |
| `GET` | `/reports` | Summary statistics |

---

## Out of Scope

- Multi-tenancy, roles, permissions
- Real blockchain, crypto, smart contracts
- TEE, ZK proofs, or any cryptographic verification
- Hosted or sandboxed remote execution
- External payment processors
- Background jobs, async processing
- Frontend, views, UI of any kind
- Skill editing or deletion (create-only for MVP)
- Pagination (data set is small for MVP)

Phase 5 and Phase 6 documents in `docs/` are planning artifacts for backlog work, not part of this baseline architecture document.
