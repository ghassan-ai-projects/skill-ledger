# SkillLedger — Phase 5 Issues

## Issue #14: API Key Authentication (5.1)

**Why:** The API currently has no authentication. Anyone can execute skills on any account, check any ledger, impersonate any user. For a production marketplace, every request must be tied to a verified account.

**Requirements:**

1. Add `api_key` column to accounts (string, unique, not null). Generate a secure random hex key (e.g. `SecureRandom.hex(32)`) on create.
2. Clients authenticate via `X-API-Key` header. Add a `before_action :authenticate!` in `Api::V1::BaseController` (create this as a parent controller).
3. Move all existing `Api::V1::*Controller`s to inherit from `Api::V1::BaseController` instead of `ApplicationController`.
4. `authenticate!` should:
   - Read `request.headers["X-API-Key"]`
   - Find account by api_key → `@current_account`
   - Return 401 with `{ "error": "Unauthorized", "details": ["Invalid or missing API key"] }` if not found
5. Update seeds to generate API keys for all existing accounts. Print the keys during seeding so they can be used for testing.
6. Update README with authentication section explaining how to get and use API keys.
7. Update all existing controller tests to include `X-API-Key` header. The test helper should provide a helper method like `headers_with_auth(account)`.
8. Add a migration for the new column. Create a rake task `rake dev:generate_api_keys` that backfills keys for existing accounts.

**Edge cases:**
- Missing header → 401
- Invalid key → 401
- Key that was valid but account was deleted → 401
- Key with leading/trailing whitespace → strip before lookup

**Verification:** All 78+ existing tests pass with auth headers added. New tests for auth failures pass.

---

## Issue #15: Skill Search, Filter & Pagination (5.2)

**Why:** The current `GET /api/v1/skills` returns ALL skills with no way to find specific ones. As the marketplace grows, users need to search, filter by author, sort, and paginate.

**Requirements:**

1. **Search:** `GET /api/v1/skills?q=data` — searches `name` and `description` fields (case-insensitive LIKE/ILIKE)
2. **Filter by author:** `GET /api/v1/skills?author_id=1` — filter by author account ID
3. **Sort:** `GET /api/v1/skills?sort=price&order=asc` — sort by `price_per_call`, `stake_amount`, `name`, `created_at`. Default: `created_at` desc.
4. **Pagination:** `GET /api/v1/skills?page=1&per_page=10` — page-based pagination. Default per_page=20, max per_page=100.
5. **Response format** should include pagination metadata:
   ```json
   {
     "skills": [...],
     "meta": {
       "current_page": 1,
       "total_pages": 5,
       "total_count": 48,
       "per_page": 10
     }
   }
   ```
6. Apply the same pagination to `GET /api/v1/executions` and `GET /api/v1/ledger` endpoints (they also return lists).
7. Param validation: invalid sort field → 422 with valid options listed. Invalid page/per_page → clamp to defaults.

**Edge cases:**
- Empty search query → return all (no filter)
- Page beyond total → return empty list, not error
- per_page > 100 → clamp to 100
- sort with invalid field → 422 error with message listing valid fields
- SQL injection protection — use Arel or whitelist for sort column

**Verification:** Search returns matching results. Filters work in combination. Pagination metadata is correct. Invalid params return proper errors.

---

## Issue #16: Execution Webhooks (5.3)

**Why:** The skill marketplace needs to notify external systems when executions complete or fail. This enables integration with CI/CD pipelines, notification systems, and external logging.

**Requirements:**

1. Add `webhook_url` column to skills (string, nullable). Validated as a proper URL format if present.
2. After an execution is created with status "completed" or updated to "failed", POST to the skill's `webhook_url` (if set) with:
   ```json
   {
     "event": "execution.completed",
     "execution_id": 42,
     "skill_id": 7,
     "skill_name": "Code Review",
     "buyer_id": 3,
     "buyer_name": "Charlie",
     "author_id": 2,
     "author_name": "Bob",
     "amount": 35.0,
     "status": "completed",
     "timestamp": "2026-05-29T12:00:00Z"
   }
   ```
3. Use ActiveJob (`ExecutionWebhookJob`) to send the webhook asynchronously. Never block the API response.
4. The webhook POST should have a 5-second timeout. On failure (timeout, non-2xx response), log the error and retry up to 3 times with exponential backoff (10s, 30s, 60s).
5. Do not retry on 4xx responses (client error — invalid webhook URL). Log and discard.
6. Update seeds to optionally set webhook_url on skills (via environment variable or nil for dev).
7. Update README with webhook documentation: payload schema, retry behavior, security (recommend verifying signatures).

**Edge cases:**
- Skill has no webhook_url set → skip silently (no-op)
- Webhook server returns 4xx → log + discard (invalid URL, don't retry)
- Webhook server times out → retry up to 3 times
- Webhook server returns 5xx → retry up to 3 times
- Job fails completely after retries → log to Rails.logger.warn, do not crash the app
- Execution created without webhook_url → no job enqueued
- URL format validation → must start with https://

**Verification:** Webhook is called on execution completion. Webhook is called on execution failure. No webhook when URL is nil. Retries on 5xx. Stops on 4xx. Tests use WebMock or a test HTTP stub.
