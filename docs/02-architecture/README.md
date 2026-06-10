# SkillLedger Architecture

**Status:** MVP (Phase 4 — Complete)  
**Stack:** Rails 8.1 API-only, SQLite3, Ruby 3.3.11

---

## Design Decisions

| Decision | Chosen | Rejected |
|----------|--------|----------|
| Rails mode | API-only (`rails new --api`) | Full-stack Rails |
| Database | SQLite (dev) / PostgreSQL (prod path) | Pure PostgreSQL — adds setup overhead |
| Module structure | Namespaced models + service objects | Rails engines — overkill for single app |
| Stake handling | Declared on skill; deducted on failure only | Upfront escrow transfer |
| Execution | Synchronous | Background jobs (no external APIs to wait on) |
| Authentication | API Key via `X-API-Key` header | None for MVP |
| Testing | Minitest (Rails default) | RSpec — no benefit at this scale |

---

## High-Level Architecture

```
                  ┌─────────────────────┐
                  │   Rails API Server   │
                  │   (Puma, API-only)   │
                  └──────┬──────┬───────┘
                         │      │
              ┌──────────┘      └──────────┐
              ▼                             ▼
     ┌────────────────┐          ┌────────────────────┐
     │  API Controllers│         │   Background Jobs   │
     │  (Api::V1::*)  │          │  (ActiveJob/SolidQ) │
     └───────┬────────┘          └──────────┬──────────┘
             │                              │
             ▼                              ▼
     ┌────────────────┐                    │
     │   Services     │                    │
     │  (Business     │←───────────────────┘
     │   Logic)       │
     └───────┬────────┘
             │
             ▼
     ┌────────────────┐
     │    Models      │
     │  (ActiveRecord)│
     └───────┬────────┘
             │
             ▼
     ┌────────────────┐
     │    SQLite3     │
     │   Database     │
     └────────────────┘
```

---

## Component Map

### Controllers (`app/controllers/api/v1/`)
- `BaseController` — authentication via `X-API-Key`, error handling
- `SkillsController` — CRUD + search/filter/pagination
- `ExecutionsController` — execute + fail
- `LedgerEntriesController` — read-only ledger
- `ReportsController` — summary stats
- `ReviewsController` — buyer ratings (1-5)
- `FavoritesController` — bookmarking skills
- `LibraryController` — personal library
- `AnalyticsController` — author dashboards

### Services (`app/services/`)
| Service | Responsibility |
|---------|---------------|
| `SkillCreationService` | Validates author + balance, creates skill |
| `ExecutionService` | Validates buyer, transfers payment, records execution |
| `LedgerTransactionService` | Creates immutable ledger entries inside transactions |
| `ReviewService` | Validates buyer, enforces one review per execution |
| `FavoriteService` | Toggle favorites with dedup |
| `LibraryService` | Composites favorites + purchased + authored |
| `AnalyticsService` | Aggregates stats with time-window filtering |

### Jobs (`app/jobs/`)
- `ExecutionWebhookJob` — POSTs to skill's `webhook_url` on completion/failure

### Models (`app/models/`)
| Model | Key Fields |
|-------|-----------|
| `Account` | `name`, `balance`, `api_key` |
| `Skill` | `name`, `description`, `author_id`, `stake_amount`, `price_per_call`, `webhook_url` |
| `Execution` | `skill_id`, `buyer_id`, `status`, `result`, `timestamp` |
| `LedgerEntry` | `from_account_id`, `to_account_id`, `amount`, `entry_type`, `timestamp` |
| `Review` | `execution_id`, `rating` (1-5), `review_text` |
| `Favorite` | `account_id`, `skill_id` (unique pair) |

---

## Database Schema

```sql
accounts:       id | name | api_key (unique) | balance (decimal)
skills:         id | name | description | author_id (FK) | stake_amount | price_per_call | webhook_url
executions:     id | skill_id (FK) | buyer_id (FK) | status (pending/completed/failed) | result | timestamp
ledger_entries: id | from_account_id (FK) | to_account_id (FK) | amount | entry_type | timestamp
reviews:        id | execution_id (FK, unique) | rating (1-5) | review_text
favorites:      id | account_id (FK) | skill_id (FK) — unique [account_id, skill_id]
```

---

## Data Flow

### Execute Skill (Happy Path)
```
POST /skills/:id/execute
  → Validate skill exists, buyer exists, buyer ≠ author
  → Validate buyer.balance ≥ skill.price_per_call
  → ActiveRecord transaction:
       buyer.balance  -= skill.price_per_call
       author.balance += skill.price_per_call
       LedgerEntry.create!(entry_type: "payment")
       Execution.create!(status: "completed")
  → Enqueue webhook job if webhook_url set
  → Return execution JSON
```

### Fail Execution (Slash + Refund)
```
PATCH /executions/:id/fail
  → Validate execution not already failed
  → ActiveRecord transaction:
       author.balance -= skill.stake_amount       # slash
       buyer.balance  += skill.stake_amount        # refund stake
       buyer.balance  += skill.price_per_call      # refund price
       author.balance -= skill.price_per_call      # reverse credit
       LedgerEntry.create!(entry_type: "slash")
       LedgerEntry.create!(entry_type: "refund")
       execution.update!(status: "failed")
  → Enqueue webhook job
  → Return execution JSON
```

---

## Key Constraints

- **Balance non-negative:** Validated on every transfer (`balance >= 0`)
- **No self-execution:** Buyer cannot be the author
- **Ledger is append-only:** Entries are never modified after creation
- **One review per execution:** Unique constraint on `execution_id`
- **Stake checked at creation:** Author must have sufficient balance for `stake_amount`
- **API key unique:** `SecureRandom.hex(32)` per account
