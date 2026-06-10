# SkillLedger — Phase 6: Functional Features

## Issue #19: Skill Reviews & Ratings (6.1)

**Why (user story):** As a buyer, I want to rate and review a skill after I've purchased an execution, so other buyers can trust quality before buying. As an author, I want to see my average rating so I can improve my skill.

**Functional requirements:**

1. New `reviews` table: `id`, `execution_id` (FK→executions, unique), `rating` (integer 1-5), `review_text` (text, optional), `created_at`, `updated_at`
2. `GET /api/v1/skills/:id` now includes `average_rating` and `review_count` in the response
3. `POST /api/v1/executions/:id/review` — Create a review on a completed execution. Only the buyer can review. Only one review per execution. Requires `rating` (1-5), optionally `review_text`.
4. `GET /api/v1/skills/:id/reviews` — List all reviews for a skill, newest first, with pagination. Includes buyer name and rating.
5. `GET /api/v1/authors/:id/reviews` — List all reviews across all skills owned by an author. Shows average rating per skill.
6. Validation: rating must be 1-5 integer. Review text max 1000 characters.
7. Author cannot review their own skill.
8. Execution must have status "completed" to be reviewed.

**Edge cases:**
- Review on non-existent execution → 404
- Review by non-buyer → 403
- Review on execution that isn't "completed" → 422
- Duplicate review on same execution → 422
- Author trying to review their own skill → 422

---

## Issue #20: Author Analytics Dashboard (6.2)

**Why (user story):** As a skill author, I want to see how my skills are performing so I can understand my earnings, popularity, and quality.

**Functional requirements:**

1. `GET /api/v1/authors/:id/analytics` — Returns a dashboard with:
   ```json
   {
     "author": { "id": 1, "name": "Alice" },
     "total_skills": 5,
     "total_executions": 47,
     "total_earnings": 2350.00,
     "total_slashed": 200.00,
     "average_rating": 4.2,
     "execution_breakdown": {
       "completed": 40,
       "failed": 5,
       "pending": 2
     },
     "top_skills": [
       {
         "id": 1,
         "name": "Data Analysis",
         "execution_count": 20,
         "total_revenue": 1000.00,
         "average_rating": 4.5
       }
     ],
     "recent_executions": [
       {
         "id": 42,
         "skill_name": "Code Review",
         "buyer_name": "Charlie",
         "status": "completed",
         "amount": 35.0,
         "timestamp": "2026-05-29T12:00:00Z"
       }
     ]
   }
   ```
2. `GET /api/v1/authors/:id/analytics?period=last_30_days` — Filter analytics to a time window. Supports: `all`, `last_7_days`, `last_30_days`, `last_90_days`, `this_year`.
3. `GET /api/v1/authors/:id/earnings` — Daily/weekly/monthly breakdown of earnings. Returns:
   ```json
   {
     "earnings_over_time": [
       { "date": "2026-05-01", "amount": 150.00, "execution_count": 3 },
       { "date": "2026-05-02", "amount": 85.00, "execution_count": 2 }
     ],
     "total_earnings": 2350.00,
     "average_per_day": 78.33,
     "best_skill": { "name": "Data Analysis", "revenue": 1000.00 }
   }
   ```
4. Authentication: only the author (or admin via API key) can access their own analytics.
5. README update with analytics endpoint docs.

**Edge cases:**
- Author has no executions → all zeros, not an error
- Non-existent author → 404
- Wrong API key trying to view another author's analytics → 403
- period parameter invalid → default to "all"
- Author has no reviews → average_rating is null, not 0

---

## Issue #21: Favorites & Personal Library (6.3)

**Why (user story):** As a buyer, I want to bookmark skills I'm interested in so I can find them later. I want a personal library of my purchased skills so I can re-execute them easily.

**Functional requirements:**

1. New `favorites` join table: `id`, `account_id` (FK→accounts), `skill_id` (FK→skills), unique constraint on [account_id, skill_id], `created_at`
2. `POST /api/v1/favorites?skill_id=5` — Add skill to my favorites
3. `DELETE /api/v1/favorites/:skill_id` — Remove skill from my favorites
4. `GET /api/v1/favorites` — List my favorited skills with full skill details + author name. Paginated.
5. `GET /api/v1/skills/:id` now includes `favorite_count` and `is_favorited` (boolean, requires auth, false for unauthenticated)
6. `GET /api/v1/me/library` — My personal library showing:
   - My favorited skills (with unfavorite action)
   - My purchased skills (skills I've executed at least once, with last execution timestamp)
   - My authored skills (if any)
   Grouped into sections: "Favorites", "Purchased", "My Skills"
7. Account model augmentations: `has_many :favorited_skills, through: :favorites, source: :skill`
8. README update with favorite and library endpoint docs.
9. Add `favorite_count` to seed data by creating some favorites for demo.

**Edge cases:**
- Favorite the same skill twice → 422 (already favorited)
- Remove favorite that doesn't exist → 404
- Favorite non-existent skill → 404
- Unauthenticated → 401
- Library for account with no activity → empty sections, not an error
- Skill deleted while in favorites → cascade nullify or preload check
