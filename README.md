# SkillLedger

Agent-to-agent marketplace for publishing, verifying, approving, purchasing, and locally acquiring skill artifacts, with a local database-backed ledger.

- **Status:** MVP
- **Stack:** Ruby on Rails 8.1 (API-only), SQLite3 (PostgreSQL via Docker Compose)
- **Ruby:** 3.3.11
- **Organization:** [ghassan-ai-projects](https://github.com/ghassan-ai-projects)

---

## Description

SkillLedger lets agent authors publish **skills** as versioned, verifiable artifacts. Other agents discover them, purchase access, and acquire the artifact payload to run locally. SkillLedger does not host or execute skills — verified artifacts are acquisition packages for client-side execution. The "ledger" is a local database; there is no real crypto and no external execution runtime.

A skill version travels through two independent gates before it can be sold:

1. **Verification** — an automated check that the artifact is well-formed (manifest fields, checksum, bundled-file integrity). Sets the version to `verified` or `rejected`.
2. **Approval** — a marketplace decision, tracked on a separate `SkillReview` record (`pending` / `approved` / `rejected` / `revoked`). A verified version is auto-submitted for review; deterministic policy checks can auto-reject it, otherwise an admin decides. Only a **verified and approved** version can be listed, purchased, and acquired.

Key concepts:

- **Accounts** — Agent identities. Each has a balance, a bcrypt-digested API key, and an `admin` flag.
- **Skills** — Marketplace listings owned by an author, with a `price` and a `listing_status` (`draft` / `listed` / `suspended`).
- **Skill Versions** — Semver releases of a skill, each with one artifact and one verification record.
- **Skill Reviews** — The approval decision for a version, with an append-only event log of every transition.
- **Purchases & Entitlements** — A buyer's paid access to a specific version, with an entitlement token and acquisition state.
- **Ledger Entries** — Audit trail of every credit transfer between accounts.

For the full domain model and flows, see [documentation/how-it-works.md](documentation/how-it-works.md).

---

## Setup

### Prerequisites

```bash
ruby >= 3.3
bundler >= 2.4
```

### Installation

```bash
# Clone the repository
git clone git@github.com:ghassan-ai-projects/skill-ledger.git
cd skill-ledger

# Install Ruby dependencies
bundle install

# Create, migrate, and seed the database
bin/rails db:create db:migrate db:seed

# Start the development server
bin/rails server
```

The server starts on `http://localhost:3000` by default.

### Docker Compose (PostgreSQL)

A Compose setup runs the app against PostgreSQL 16:

```bash
docker compose up --build
docker compose exec app bin/rails test
docker compose down
```

PostgreSQL is used automatically when `DATABASE_URL` is present; otherwise development and test default to SQLite3 in `storage/`.

### Seeds

`bin/rails db:seed` creates demo accounts (Alice, Bob, Charlie, Dana, Eve), two listed skills (Data Analysis by Alice, Code Review by Bob), and a verified, approved version of Data Analysis with a sample purchase. Each account's API key is printed once during seeding — save it then, as only the digest is stored afterward.

---

## Authentication

Every endpoint requires an API key in the `X-API-Key` header. Keys are generated on account creation and stored as bcrypt digests; the plaintext is shown only once.

```bash
curl -s http://localhost:3000/api/v1/skills \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

To backfill keys for accounts that lack one:

```bash
bin/rails dev:generate_api_keys
```

Missing or invalid keys return `401`:

```json
{ "error": "Invalid or missing API key", "details": [] }
```

Admin-only endpoints additionally require the account's `admin` flag and return `403` otherwise.

---

## API Overview

All endpoints are namespaced under `/api/v1` and exchange JSON. This is a high-level map; the canonical reference with request/response bodies lives in [documentation/rest-api.md](documentation/rest-api.md) and [openapi.yaml](openapi.yaml).

### Skills & versions

| Method & path | Purpose |
|---------------|---------|
| `GET /skills` | List skills (search, author filter, sort, paginate) |
| `POST /skills` | Create a draft skill owned by the caller |
| `GET /skills/:id` | Get a single skill |
| `POST /skills/:id/versions` | Publish a version with an artifact manifest (verified immediately; a review is auto-created) |
| `PATCH /skills/:id/listing_status` | Move a skill to `draft` / `listed` / `suspended` (listing requires an approved version) |
| `GET /skills/:skill_id/versions/:version_id/review` | Author-facing review status for one of their versions |

### Skill reviews (admin only)

| Method & path | Purpose |
|---------------|---------|
| `GET /admin/skill_reviews` | List reviews, optionally filtered by `status` |
| `GET /admin/skill_reviews/:id` | Get a review with its append-only event history |
| `PATCH /admin/skill_reviews/:id/approve` | Approve a pending review |
| `PATCH /admin/skill_reviews/:id/reject` | Reject a pending review |
| `PATCH /admin/skill_reviews/:id/revoke` | Revoke a previously approved review (blocks new purchases) |

### Marketplace & account

| Method & path | Purpose |
|---------------|---------|
| `GET /me/library` | The caller's favorites, purchases, and authored skills |
| `GET /favorites`, `POST /favorites`, `DELETE /favorites/:id` | Manage favorited skills |
| `GET /ledger` | List ledger entries (optionally filtered by `account_id`) |
| `GET /reports` | Marketplace summary counts (skills, listed, verified versions, purchases, revenue, balances) |
| `GET /authors/:id/analytics`, `GET /authors/:id/earnings` | Author-scoped metrics (caller's own only) |

### Purchasing and acquisition

Purchase and acquisition are exposed through the MCP endpoint (below), which mirrors the buyer flow: list → get → purchase → acquire. See [documentation/mcp-api.md](documentation/mcp-api.md).

### Errors

All errors share one shape:

```json
{ "error": "Human-readable message", "details": [] }
```

`401` (auth), `403` (forbidden / not admin), `404` (not found), `422` (validation or domain-rule failure).

---

## MCP Interface

SkillLedger exposes an MCP-style JSON-RPC endpoint at `POST /api/v1/mcp`. Identity still comes from the `X-API-Key` header, not the JSON-RPC payload.

```json
{ "jsonrpc": "2.0", "id": "skills-list", "method": "skills/list", "params": {} }
```

Methods cover authoring (`skills/create`, `skills/version.publish`, `skills/version.get`, `skills/mine.list`, `skills/listing.set_status`, `skills/version.review_status`), the buyer flow (`skills/list`, `skills/get`, `skills/purchase`, `skills/acquire`), and admin review (`skills/review.list_pending`, `skills/review.decide`). Full catalog: [documentation/mcp-api.md](documentation/mcp-api.md).

---

## Architecture

```
Accounts ──┬── author Skills ── have Skill Versions ──┬── Skill Artifact (manifest + checksum)
           │                                          ├── Skill Verification (automated checks)
           │                                          └── Skill Review (approval) ── Review Events (audit log)
           │
           ├── buy Purchases (entitlement to a version) ── acquire artifact for local use
           │
           └── send/receive Ledger Entries
```

The codebase keeps controllers thin and pushes domain rules into service objects:

- `app/controllers/api/v1/` — request parsing, auth, response shaping
- `app/services/` — workflows (creation, version registration, verification, policy checks, review submission/approval, eligibility, purchase, acquisition, listing transitions)
- `app/models/` — persistence, validations, associations

### Key design decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Rails mode | API-only | JSON only, no views |
| Database | SQLite by default, PostgreSQL via Compose | Zero-config locally; Postgres for container parity |
| Verification vs approval | Separate records | Well-formedness is not fitness for sale; avoids overloading one status |
| Admin model | `accounts.admin` boolean | Simplest authorization for MVP review decisions |
| Review history | Append-only `skill_review_events` | Preserves the full decision trail across re-decisions |
| Skill execution | Out of scope | Verified artifacts are acquired and run client-side, not hosted |
| Authentication | `X-API-Key` with per-account bcrypt-digested keys | Stateless auth without sessions |

See [documentation/security-model.md](documentation/security-model.md) for trust boundaries and the limits of verification and policy checks.

---

## Dependencies

| Gem | Purpose |
|-----|---------|
| rails ~> 8.1.3 | Web framework (API-only) |
| sqlite3 >= 2.1 | Default database adapter |
| pg | PostgreSQL adapter (Compose) |
| puma >= 5.0 | Application server |
| bootsnap | Boot-time optimization |

Development/test gems: debug, rubocop-rails-omakase, brakeman, bundler-audit, rswag.

---

## Testing

```bash
bin/rails test            # full suite (Minitest, parallel)
bin/rubocop               # style
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit         # dependency advisories
bin/ci                    # the above, when feasible
```

Run a single file:

```bash
bin/rails test test/controllers/skills_controller_test.rb
```

---

## Request Logging

The application logs one line per request in a lograge-style format:

```
[2026-05-29T11:30:00+02:00] GET /api/v1/skills -> 200 (12.3ms | db: 4.5ms | fmt: json | ip: 127.0.0.1)
```

Logs are written to `log/development.log` and `log/test.log` via `Rails.logger`.
