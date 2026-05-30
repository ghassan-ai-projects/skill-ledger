
# SkillLedger — Phase 7: Product Roadmap (5 Features)

## Feature 1: Skill Versions & Changelog

**Why:** Skills evolve. Authors need to update pricing, stake, descriptions without breaking existing executions. Buyers need to know what version they're buying and what changed.

**How it works:**
- Add `version` column to skills (integer, default 1).
- Before updating a skill, save the current state to a new `skill_versions` table (snapshot of name, description, price_per_call, stake_amount).
- Executions reference the `skill_version_id` they were executed against, not the latest skill state.
- `GET /api/v1/skills/:id/versions` — list version history with changelog notes.
- `GET /api/v1/executions/:id` — includes `version_number` the execution used.
- Authors can add a changelog message per version: "Updated pricing to reflect improved accuracy."

**Data model:**
```
skill_versions: id, skill_id (FK), version (int), name, description,
               price_per_call (decimal), stake_amount (decimal),
               changelog (text), created_at
executions: ... + skill_version_id (FK→skill_versions)
```

---

## Feature 2: Escrow & Dispute Resolution

**Why:** When a buyer marks an execution as failed, the stake goes into escrow — not to the author, not back to the buyer. Either party can raise a dispute with evidence. This prevents abuse from both sides (authors publishing bad skills, buyers falsely claiming failure).

**How it works:**
- Add `status` options to executions: `pending`, `completed`, `failed`, `disputed`, `resolved_refund`, `resolved_author`.
- Add `escrow_held` decimal to executions (amount held in escrow).
- On `fail`: stake goes to escrow (not back to buyer, not to author). Execution status: `failed_escrow`.
- `POST /api/v1/executions/:id/dispute` — raise dispute with evidence text + optional attachment reference. Status → `disputed`.
- `POST /api/v1/executions/:id/resolve` — resolve dispute. Parameters: `resolution` (refund_buyer, pay_author, split), `admin_notes`. Only callable via admin API key.
- `GET /api/v1/executions/disputed` — list all disputed executions (admin only).
- Ledger entries for escrow holds, refunds, and author payouts after resolution.

**Data model additions:**
```
executions: + escrow_held (decimal, default 0), disputed_at (datetime)
disputes: id, execution_id (FK), raised_by_id (FK→accounts), reason (text),
          evidence (text), admin_notes (text), resolved_at, resolution (string)
```

---

## Feature 3: Referral & Bonus Credits

**Why:** The best way to grow a marketplace is word-of-mouth. Users get rewarded for bringing new users. Bonus credits for first-time buyers incentivize trial.

**How it works:**
- Add `referral_code` to accounts (string, unique, auto-generated 8-char alphanumeric on create).
- Add `referred_by_id` to accounts (FK→accounts, nullable, set on signup if referral code used).
- `GET /api/v1/me/referral` — returns my referral code, my referral link, total referred count, bonus credits earned.
- When a new account is created with a `?ref=CODE` or via header:
  - The referrer gets 50 bonus credits.
  - The new user gets 25 bonus credits (welcome bonus).
- Bonus credits are tracked in ledger with `entry_type: "referral_bonus"` or `entry_type: "welcome_bonus"`.
- Prevent self-referral (can't use your own code).
- Max 10 referrals per day per account (anti-gaming).
- `GET /api/v1/leaderboard/referrals` — top referrers this month.

**Data model additions:**
```
accounts: + referral_code (string, unique), + referred_by_id (FK→accounts, nullable)
```

---

## Feature 4: Activity Feed

**Why:** A marketplace needs to feel alive. New users, new skills, top reviews — surfaced as a live feed. Also serves as the homepage/"discover" view.

**How it works:**
- No new table. The feed is a composite query across existing tables:
  - New skills created (past 7 days)
  - Skills with recent reviews (past 48 hours)
  - Top-rated skills this week
  - Trending skills (most executions in past 24 hours)
  - New users (recently created accounts)
- `GET /api/v1/feed` — returns:
  ```json
  {
    "new_skills": [ { "id": 5, "name": "...", "author": {...}, "created_at": "..." } ],
    "trending": [ { "id": 3, "name": "...", "executions_24h": 12, "author": {...} } ],
    "top_rated": [ { "id": 1, "name": "...", "average_rating": 4.8, "review_count": 15 } ],
    "recent_reviews": [ { "skill_name": "...", "rating": 5, "buyer_name": "...", "timestamp": "..." } ],
    "new_authors": [ { "id": 7, "name": "...", "skills_count": 2 } ]
  }
  ```
- Each section has configurable limits (default 5 items per section).
- `GET /api/v1/feed?section=trending` — single section with more results (paginated, 20 per page).
- Cache the feed response for 60 seconds (Redis or in-memory). With 16+ executions, recalculating on every request is wasteful.
- README with feed endpoint docs.

---

## Feature 5: Scheduled & Recurring Executions

**Why:** Buyers want to run skills on a schedule — daily data analysis, weekly code review, monthly reporting. This turns one-off purchases into recurring value.

**How it works:**
- New `schedules` table: `id`, `buyer_id` (FK→accounts), `skill_id` (FK→skills), `cron_expression` (string), `enabled` (bool), `next_run_at` (datetime), `last_run_at` (datetime), timestamps.
- `POST /api/v1/schedules` — create a schedule with `skill_id` and `cron_expression` (standard 5-field cron). Validates cron syntax.
- `GET /api/v1/schedules` — list my schedules.
- `PATCH /api/v1/schedules/:id/toggle` — enable/disable without deleting.
- `DELETE /api/v1/schedules/:id` — remove schedule.
- `GET /api/v1/me/scheduled_executions` — upcoming executions for my schedules.
- A rake task `scheduler:tick` runs every minute (via cron or Solid Queue recurring schedule). It:
  - Finds all enabled schedules where `next_run_at` ≤ now
  - Creates an execution for each (same logic as manual execute)
  - Deducts credits from buyer
  - Updates `last_run_at` and computes `next_run_at` from cron expression
- If buyer has insufficient credits when the scheduled execution fires → skip and log warning (don't disable the schedule, it might work next time).
- If schedule fails 3 consecutive times → auto-disable and log.
- `cron_expression` examples: `"0 9 * * 1-5"` (weekdays 9am), `"0 0 * * 0"` (weekly Sunday), `"0 0 1 * *"` (monthly 1st).
- Validated against a cron parsing gem (e.g., `fugit`) or manual 5-field parser.
- README with schedule endpoints and cron syntax guide.

**Data model:**
```
schedules: id, buyer_id (FK), skill_id (FK), cron_expression (string),
           enabled (bool, default true), next_run_at (datetime),
           last_run_at (datetime), consecutive_failures (int, default 0),
           timestamps
```
