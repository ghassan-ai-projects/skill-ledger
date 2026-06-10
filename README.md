# SkillLedger

Agent-to-agent skill publishing, discovery, purchase, and verified execution with a local database-backed ledger.

**Status:** MVP  
**Stack:** Ruby on Rails 8.1 (API-only), SQLite3  
**Ruby:** 3.3.11  
**Organization:** [ghassan-ai-projects](https://github.com/ghassan-ai-projects)

---

## Description

SkillLedger is a Rails API that lets agent authors publish skills with a staked bond, and other agents discover, purchase, and verify execution. The "ledger" is a local SQLite database — no real crypto, no external APIs.

Key concepts:

- **Accounts** — Agents that author skills, buy executions, and hold balances.
- **Skills** — Published capabilities with a price per call and a staked bond.
- **Executions** — A record of a skill being purchased and executed by a buyer.
- **Ledger Entries** — Immutable audit trail of every financial transfer between accounts.

When an execution fails, the author's stake is slashed and refunded to the buyer along with the original price — creating an incentive for skill quality.

---

## Setup

### Prerequisites

```bash
ruby >= 3.3
bundler 4.0.12
```

### Installation

```bash
# Clone the repository
git clone git@github.com:ghassan-ai-projects/skill-ledger.git
cd skill-ledger

# Install the Bundler version used by this lockfile
gem install bundler:4.0.12

# Install Ruby dependencies
bundle install

# Create, migrate, and seed the database
bin/rails db:create db:migrate db:seed

# Start the development server
bin/rails server
```

The server starts on `http://localhost:3000` by default.

### Database

The project uses SQLite3. Database files are stored in `storage/`:

| Environment | Database file |
|-------------|---------------|
| Development | `storage/development.sqlite3` |
| Test | `storage/test.sqlite3` |
| Production | `storage/production.sqlite3` |

### Seeds

Running `bin/rails db:seed` creates:

| Account | Balance |
|---------|---------|
| Alice | 1000.00 |
| Bob | 500.00 |
| Charlie | 250.00 |
| Dana | 1000.00 |
| Eve | 1000.00 |

And two skills:

| Skill | Author | Price/call | Stake |
|-------|--------|-----------|-------|
| Data Analysis | Alice | 50.00 | 200.00 |
| Code Review | Bob | 35.00 | 150.00 |

---

## Authentication

All API endpoints require authentication via an API key passed in the `X-API-Key` request header.

Each **Account** has a unique `api_key` generated automatically on creation via `SecureRandom.hex(32)`.

### How to authenticate

Include the `X-API-Key` header with every request:

```bash
curl -s http://localhost:3000/api/v1/skills \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

### Obtaining an API key

API keys are printed during seeding. To view an account's API key:

```bash
bin/rails db:seed
# => Account: Alice (1000.0 credits) — API Key: abc123...
```

To backfill API keys for existing accounts:

```bash
bin/rails dev:generate_api_keys
```

### Error responses

**`401 Unauthorized`** — missing or invalid API key:

```json
{
  "error": "Invalid or missing API key",
  "details": []
}
```

---

## API Endpoints

All endpoints are namespaced under `/api/v1`. Request and response bodies use JSON.

### Skills

#### `GET /api/v1/skills` — List all skills

Returns all published skills with their author information.

```bash
curl -s http://localhost:3000/api/v1/skills | jq
```

**Response `200 OK`:**
```json
[
  {
    "id": 1,
    "name": "Data Analysis",
    "description": "Analyze datasets and generate reports",
    "author_id": 1,
    "stake_amount": "200.0",
    "price_per_call": "50.0",
    "created_at": "2026-05-28T20:23:37.000Z",
    "updated_at": "2026-05-28T20:23:37.000Z",
    "author": {
      "id": 1,
      "name": "Alice"
    }
  }
]
```

#### `POST /api/v1/skills` — Create a skill

Creates a new skill authored by an existing account.

```bash
curl -s -X POST http://localhost:3000/api/v1/skills \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{
    "skill": {
      "name": "Translation Service",
      "description": "Translate text between languages",
      "price_per_call": 25.00,
      "stake_amount": 100.00
    }
  }' | jq
```

**Parameters (JSON body under `skill` key):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | Yes | Skill display name |
| `description` | String | No | Detailed description |
| `price_per_call` | Decimal | Yes | Price in credits per execution |
| `stake_amount` | Decimal | Yes | Stake bonded by the author |

The author must have sufficient balance to cover `stake_amount`.

**Response `201 Created`:**
```json
{
  "id": 3,
  "name": "Translation Service",
  "description": "Translate text between languages",
  "author_id": 1,
  "stake_amount": "100.0",
  "price_per_call": "25.0",
  "author": { "id": 1, "name": "Alice" }
}
```

**Error `422 Unprocessable Entity`** — author not found:
```json
{ "error": "Author not found", "details": [] }
```

**Error `422 Unprocessable Entity`** — insufficient balance for stake:
```json
{ "error": "Author has insufficient balance for stake", "details": [] }
```

**Error `422 Unprocessable Entity`** — validation failed:
```json
{
  "error": "Validation failed",
  "details": ["Name can't be blank"]
}
```

**Error `400 Bad Request`** — missing `skill` parameter:
```json
{
  "error": "Missing required parameter",
  "details": ["param is missing or the value is empty: skill"]
}
```

#### `GET /api/v1/skills/:id` — Get a skill

Returns a single skill by ID.

```bash
curl -s http://localhost:3000/api/v1/skills/1 | jq
```

**Response `200 OK`:**
```json
{
  "id": 1,
  "name": "Data Analysis",
  "description": "Analyze datasets and generate reports",
  "author_id": 1,
  "stake_amount": "200.0",
  "price_per_call": "50.0",
  "created_at": "2026-05-28T20:23:37.000Z",
  "updated_at": "2026-05-28T20:23:37.000Z",
  "author": { "id": 1, "name": "Alice" }
}
```

**Error `404 Not Found`:**
```json
{
  "error": "Couldn't find Skill with 'id'=99999",
  "details": []
}
```

### Executions

#### `POST /api/v1/skills/:skill_id/execute` — Execute a skill

A buyer purchases and executes a skill. The buyer's account is charged `price_per_call`, the author is credited, and a ledger entry is created. Both accounts must be different.

```bash
curl -s -X POST http://localhost:3000/api/v1/skills/1/execute \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

**Parameters:**

No parameters required. The buyer is inferred from the API Key.

**Response `201 Created`:**
```json
{
  "id": 1,
  "skill_id": 1,
  "buyer_id": 2,
  "status": "completed",
  "result": null,
  "timestamp": "2026-05-29T11:30:00.000Z"
}
```

**Error `422 Unprocessable Entity`** — buyer not found:
```json
{ "error": "Buyer not found", "details": [] }
```

**Error `422 Unprocessable Entity`** — buyer is the author:
```json
{ "error": "Cannot execute your own skill", "details": [] }
```

**Error `422 Unprocessable Entity`** — insufficient balance:
```json
{ "error": "Buyer has insufficient balance", "details": [] }
```

**Error `404 Not Found`** — skill not found:
```json
{
  "error": "Couldn't find Skill with 'id'=99999",
  "details": []
}
```

#### `GET /api/v1/executions` — List executions

Returns all executions with associated skill and buyer information.

```bash
curl -s http://localhost:3000/api/v1/executions | jq
```

**Response `200 OK`:**
```json
[
  {
    "id": 1,
    "skill_id": 1,
    "buyer_id": 2,
    "status": "completed",
    "result": null,
    "timestamp": "2026-05-29T11:30:00.000Z",
    "skill": { "id": 1, "name": "Data Analysis" },
    "buyer": { "id": 2, "name": "Bob" }
  }
]
```

#### `PATCH /api/v1/executions/:id/fail` — Fail an execution

Marks an execution as failed. The author's stake is slashed and the buyer receives a refund (price + stake). Two ledger entries are created: one `slash` and one `refund`.

The author must have sufficient balance to cover the stake + price refund.

```bash
curl -s -X PATCH http://localhost:3000/api/v1/executions/1/fail | jq
```

**Response `200 OK`:**
```json
{
  "id": 1,
  "skill_id": 1,
  "buyer_id": 2,
  "status": "failed",
  "result": null,
  "timestamp": "2026-05-29T11:30:00.000Z"
}
```

**Error `422 Unprocessable Entity`** — execution already failed:
```json
{ "error": "Execution is already failed", "details": [] }
```

**Error `422 Unprocessable Entity`** — author has insufficient balance (validation):
```json
{
  "error": "Validation failed",
  "details": ["Balance must be greater than or equal to 0"]
}
```

**Error `404 Not Found`** — execution not found:
```json
{
  "error": "Couldn't find Execution with 'id'=99999",
  "details": []
}
```

### Ledger

#### `GET /api/v1/ledger` — List ledger entries

Returns all ledger entries with from/to account information.

```bash
curl -s http://localhost:3000/api/v1/ledger | jq
```

**Response `200 OK`:**
```json
[
  {
    "id": 1,
    "from_account_id": 1,
    "to_account_id": 2,
    "amount": "100.0",
    "entry_type": "transfer",
    "timestamp": "2026-05-28T20:23:37.000Z",
    "from_account": { "id": 1, "name": "Alice" },
    "to_account": { "id": 2, "name": "Bob" }
  }
]
```

### Reports

#### `GET /api/v1/reports` — Summary statistics

Returns aggregate statistics across the entire system.

```bash
curl -s http://localhost:3000/api/v1/reports | jq
```

**Response `200 OK`:**
```json
{
  "total_skills": 2,
  "total_executions": 5,
  "completed_executions": 4,
  "failed_executions": 1,
  "total_slashed": 200.0,
  "total_ledger_balance": 1750.0
}
```

| Field | Description |
|-------|-------------|
| `total_skills` | Number of published skills |
| `total_executions` | Total executions across all skills |
| `completed_executions` | Executions with status "completed" |
| `failed_executions` | Executions with status "failed" |
| `total_slashed` | Total credits slashed from failed executions |
| `total_ledger_balance` | Sum of all account balances |

### Reviews

#### `POST /api/v1/executions/:id/review` — Review an execution

Allows a buyer to rate a completed execution (1-5) with optional text.

```bash
curl -s -X POST http://localhost:3000/api/v1/executions/1/review \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{ "rating": 4, "review_text": "Great work!" }' | jq
```

**Response `201 Created`:**
```json
{
  "id": 1,
  "rating": 4,
  "review_text": "Great work!",
  "buyer_name": "Bob",
  "created_at": "2026-05-29T12:00:00.000Z"
}
```

**Error `403 Forbidden`** — not the buyer.

**Error `422 Unprocessable Entity`** — not completed, duplicate, or self-review.

#### `GET /api/v1/skills/:id/reviews` — List reviews for a skill

Returns all reviews for a skill, newest first, paginated.

```bash
curl -s http://localhost:3000/api/v1/skills/1/reviews \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

**Response `200 OK`:**
```json
{
  "reviews": [
    {
      "id": 1,
      "rating": 4,
      "review_text": "Great work!",
      "buyer_name": "Bob",
      "created_at": "2026-05-29T12:00:00.000Z"
    }
  ],
  "meta": { "current_page": 1, "total_pages": 1, "total_count": 1, "per_page": 20 }
}
```

### Favorites

#### `POST /api/v1/favorites` — Add a skill to favorites

```bash
curl -s -X POST http://localhost:3000/api/v1/favorites \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{ "skill_id": 1 }' | jq
```

**Response `201 Created`:**
```json
{ "message": "Skill added to favorites", "favorite_id": 1 }
```

**Error `422`** — duplicate, **`404`** — skill not found.

#### `DELETE /api/v1/favorites/:skill_id` — Remove a favorite

```bash
curl -s -X DELETE http://localhost:3000/api/v1/favorites/1 \
  -H "X-API-Key: YOUR_API_KEY"
```

**Response `204 No Content`**

#### `GET /api/v1/favorites` — List favorited skills

Returns favorited skills with full skill details, paginated.

```bash
curl -s http://localhost:3000/api/v1/favorites \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

**Response `200 OK`:**
```json
{
  "favorites": [
    {
      "id": 1,
      "name": "Data Analysis",
      "author": { "id": 1, "name": "Alice" },
      "average_rating": 4.0,
      "review_count": 1,
      "favorite_count": 2,
      "is_favorited": true
    }
  ],
  "meta": { "current_page": 1, "total_pages": 1, "total_count": 1, "per_page": 20 }
}
```

### Library

#### `GET /api/v1/me/library` — Personal library

Returns all skills relevant to the authenticated user: favorites, purchased, and authored.

```bash
curl -s http://localhost:3000/api/v1/me/library \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

**Response `200 OK`:**
```json
{
  "favorites": [ ...skills with full details... ],
  "purchased": [ ...skills executed, with last_execution_timestamp... ],
  "my_skills": [ ...authored skills... ]
}
```

---

### Analytics

#### `GET /api/v1/authors/:id/analytics` — Author analytics dashboard

Returns comprehensive analytics for an author, including earnings, execution stats, and ratings.
Only the author can access their own analytics.

Supports `?period=` parameter: `all`, `last_7_days`, `last_30_days`, `last_90_days`, `this_year`.

```bash
curl -s http://localhost:3000/api/v1/authors/1/analytics \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

**Response `200 OK`:**
```json
{
  "author": { "id": 1, "name": "Alice" },
  "total_skills": 2,
  "total_executions": 5,
  "total_earnings": 250.0,
  "total_slashed": 100.0,
  "average_rating": 4.5,
  "execution_breakdown": { "completed": 4, "failed": 1, "pending": 0 },
  "top_skills": [
    {
      "id": 1,
      "name": "Data Analysis",
      "execution_count": 3,
      "total_revenue": 150.0,
      "average_rating": 4.5
    }
  ],
  "recent_executions": [
    {
      "id": 5,
      "skill_name": "Data Analysis",
      "buyer_name": "Bob",
      "status": "completed",
      "amount": 50.0,
      "timestamp": "2026-05-29T12:00:00.000Z"
    }
  ]
}
```

| Field | Description |
|-------|-------------|
| `author` | Author id and name |
| `total_skills` | Number of skills authored |
| `total_executions` | Total executions across all skills |
| `total_earnings` | Sum of price_per_call for completed executions |
| `total_slashed` | Sum of slash ledger entries |
| `average_rating` | Average rating across all reviews |
| `execution_breakdown` | Counts of completed, failed, pending executions |
| `top_skills` | Top 5 skills by execution count |
| `recent_executions` | Last 10 executions with details |

**Error `403 Forbidden`** — accessing another author's analytics:
```json
{ "error": "You can only access your own analytics", "details": [] }
```

**Error `404 Not Found`** — author not found:
```json
{
  "error": "Couldn't find Account with 'id'=99999",
  "details": []
}
```

#### `GET /api/v1/authors/:id/earnings` — Daily earnings breakdown

Returns a daily breakdown of earnings with totals and best-performing skill.

```bash
curl -s http://localhost:3000/api/v1/authors/1/earnings \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

**Response `200 OK`:**
```json
{
  "earnings_over_time": [
    { "date": "2026-05-28", "amount": 100.0, "execution_count": 2 },
    { "date": "2026-05-29", "amount": 50.0, "execution_count": 1 }
  ],
  "total_earnings": 150.0,
  "average_per_day": 75.0,
  "best_skill": { "name": "Data Analysis", "revenue": 150.0 }
}
```

---

## Webhooks

Skills can notify external services when an execution completes or fails via a webhook URL.

### Setting a webhook URL

Set `webhook_url` on a skill when creating or updating it. Only `https://` URLs are accepted.

```bash
curl -s -X POST http://localhost:3000/api/v1/skills \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{
    "skill": {
      "name": "Webhook Skill",
      "description": "A skill with webhook",
      "author_id": 1,
      "price_per_call": 10.00,
      "stake_amount": 50.00,
      "webhook_url": "https://example.com/webhooks/skill-ledger"
    }
  }' | jq
```

### Payload schema

When an execution completes or fails, a POST request is sent to the `webhook_url` with the following JSON body:

```json
{
  "event": "execution.completed",
  "execution": {
    "id": 1,
    "skill_id": 1,
    "skill_name": "Data Analysis",
    "buyer_id": 2,
    "status": "completed",
    "result": null,
    "timestamp": "2026-05-29T12:00:00.000Z"
  },
  "skill": {
    "id": 1,
    "name": "Data Analysis",
    "author_id": 1
  }
}
```

The `event` field is either `execution.completed` or `execution.failed`.

### Retry behavior

| Scenario | Behavior |
|----------|----------|
| Timeout (5s connect + 5s read) | Retries up to 3 times with exponential backoff |
| 5xx Server Error | Retries up to 3 times with exponential backoff |
| 4xx Client Error | Discarded immediately — logged, not retried |
| 2xx Success | Acknowledged, no further action |

### Signature verification

Webhook consumers should verify that incoming requests originate from SkillLedger. Recommended approach:

1. Generate a shared secret (e.g., via `SecureRandom.hex(32)`).
2. Include it as a query parameter or custom header when setting `webhook_url`.
3. On the consumer side, validate the shared secret matches.

---

## Error Responses

All errors follow a consistent JSON shape:

```json
{
  "error": "Human-readable error message",
  "details": ["Optional array of detailed messages"]
}
```

| HTTP Status | When |
|-------------|------|
| `400 Bad Request` | Missing required parameters |
| `404 Not Found` | Resource not found |
| `422 Unprocessable Entity` | Validation failures, insufficient balance, business rule violations |

---

## Architecture

```
Accounts ──┬── author Skills ──┬── have Executions
            │                   │
            │                   └── buyer is an Account
            │
            └── send/receive Ledger Entries
```

### Data flow

1. An **Account** authors a **Skill** with a `stake_amount` (bond) and `price_per_call`. The stake is deducted and held in `locked_stake`.
2. Another **Account** (buyer) executes the skill via `POST /skills/:id/execute`.
3. On execution, `price_per_call` is transferred from buyer's `balance` to `escrow_balance` and marked as `pending`.
4. When execution completes, `price_per_call` transfers from the buyer's `escrow_balance` to the author.
5. If the execution fails (`PATCH /executions/:id/fail`):
   - Author's `locked_stake` is slashed and given to the buyer.
   - `price_per_call` is refunded from buyer's `escrow_balance` back to their `balance`.
   - Two ledger entries are created: `slash` and `refund`.

### Key design decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Rails mode | API-only | No views, purely JSON |
| Database | SQLite | Local, zero-config, race-safe via serialized transactions |
| Module structure | Namespaced models + service objects | Simple, no engine overhead |
| Stake handling | Deducted on creation and held in locked_stake | Ensures author cannot overcommit |
| Execution | Uses escrow_balance for pending executions | Protects buyer funds from immediate settlement |
| Authentication | API Key required (`X-API-Key`) | Secures endpoints to current account |

---

## Dependencies

| Gem | Purpose |
|-----|---------|
| rails ~> 8.1.3 | Web framework (API-only) |
| sqlite3 >= 2.1 | Database adapter |
| puma >= 5.0 | Application server |
| bootsnap | Boot time optimization |

Development/test gems: debug, rubocop-rails-omakase, brakeman, bundler-audit.

---

## Testing

```bash
bin/rails test
```

The test suite uses Minitest (Rails default) with fixtures and runs in parallel.

To run a specific test file:

```bash
bin/rails test test/controllers/skills_controller_test.rb
```

To check test coverage (if SimpleCov is configured):

```bash
COVERAGE=true bin/rails test
```

---

## Request Logging

The application logs one line per request in a lograge-style format:

```
[2026-05-29T11:30:00+02:00] GET /api/v1/skills -> 200 (12.3ms | db: 4.5ms | fmt: json | ip: 127.0.0.1)
```

Request logs are written to `log/development.log` (development) and `log/test.log` (test) via `Rails.logger`.
