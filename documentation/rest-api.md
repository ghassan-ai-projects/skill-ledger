# REST API

All REST endpoints are namespaced under `/api/v1` and require `X-API-Key`.

## Authentication

Example:

```bash
curl -s http://127.0.0.1:3000/api/v1/skills \
  -H "X-API-Key: YOUR_API_KEY"
```

Common auth failure:

```json
{
  "error": "Invalid or missing API key",
  "details": []
}
```

## Skills

### `GET /api/v1/skills`

Returns paginated skills with:

- search via `q`
- author filter via `author_id`
- sorting via `sort` and `order`
- pagination via `page` and `per_page`

Returned skill objects include:

- author summary
- `latest_verified_version`
- `favorite_count`
- `is_favorited`

### `POST /api/v1/skills`

Creates a skill for the authenticated account.

Request body:

```json
{
  "skill": {
    "name": "Publisher Control Plane",
    "description": "Author-side MCP publishing helper",
    "price": 15.5
  }
}
```

The initial listing status is typically `draft`.

### `GET /api/v1/skills/:id`

Returns a single formatted skill record.

### `POST /api/v1/skills/:id/versions`

Registers a new version for an owned skill.

Request body:

```json
{
  "version": {
    "version": "1.0.0",
    "changelog": "Initial release",
    "artifact": {
      "artifact_type": "mcp_tool_manifest",
      "manifest": {
        "name": "publisher-control-plane",
        "description": "Author-side MCP publishing helper",
        "version": "1.0.0",
        "runtime": "client",
        "entrypoint": "publisher_control_plane.run",
        "input_schema": { "type": "object" },
        "output_schema": { "type": "object" },
        "files": [
          {
            "path": "skill/SKILL.md",
            "media_type": "text/markdown",
            "content": "# Publisher Control Plane"
          }
        ]
      }
    }
  }
}
```

The response includes:

- version metadata
- stored artifact metadata
- verification status and check results

### `PATCH /api/v1/skills/:id/listing_status`

Changes a skill to `draft`, `listed`, or `suspended`.

Moving to `listed` requires at least one approved version (verified and approved by an admin — see Skill Reviews below).

### `GET /api/v1/skills/:skill_id/versions/:version_id/review`

Author-facing review status for one of the caller's own versions. Returns:

```json
{
  "skill_id": 1,
  "version": "1.0.0",
  "status": "pending",
  "review_type": "automated",
  "decision_reason": null,
  "submitted_at": "2026-06-28T21:00:00Z",
  "decided_at": null
}
```

Fields are `null` if no review exists yet (e.g. the version is not yet verified).

## Skill Reviews (Admin)

Admin-only endpoints (`accounts.admin: true`), returning `403` for non-admin accounts.

### `GET /api/v1/admin/skill_reviews`

Lists skill reviews. Optional `status` query param (`pending`, `approved`, `rejected`, `revoked`).

### `GET /api/v1/admin/skill_reviews/:id`

Returns a single skill review with its nested skill version summary and an `events` array — the append-only decision history (`event_type`, `from_status`, `to_status`, `actor_account_id`, `reason`, `created_at`), ordered chronologically.

### `PATCH /api/v1/admin/skill_reviews/:id/approve`

### `PATCH /api/v1/admin/skill_reviews/:id/reject`

### `PATCH /api/v1/admin/skill_reviews/:id/revoke`

All three accept an optional `reason` body param, stored as `decision_reason`. Each returns the updated review:

```json
{
  "id": 1,
  "status": "approved",
  "review_type": "manual",
  "policy_checks": { "no_path_traversal": true },
  "decision_reason": "Looks good",
  "reviewer_account_id": 7,
  "submitted_at": "2026-06-28T21:00:00Z",
  "decided_at": "2026-06-28T21:05:00Z",
  "skill_version": { "id": 12, "skill_id": 4, "version": "1.0.0", "status": "verified" }
}
```

`revoke` is also valid on a previously `approved` review and immediately blocks new purchases of that version.

## Favorites

### `GET /api/v1/favorites`

Returns paginated favorited skills.

### `POST /api/v1/favorites`

Request body:

```json
{
  "skill_id": 1
}
```

### `DELETE /api/v1/favorites/:id`

Deletes the favorite for the given skill id.

## Library

### `GET /api/v1/me/library`

Returns:

- `favorites`
- `purchased`
- `my_skills`

Purchased entries include:

- `purchased_version`
- `purchase_status`
- `purchased_at`
- `acquired_at`

## Ledger

### `GET /api/v1/ledger`

Returns paginated ledger entries. Optional query:

- `account_id`: filters entries where the account is either sender or receiver

## Reports

### `GET /api/v1/reports`

Returns global summary counts:

- `total_skills`
- `listed_skills`
- `verified_skill_versions`
- `total_purchases`
- `total_revenue`
- `total_ledger_balance`

## Analytics

### `GET /api/v1/authors/:id/analytics`

Returns author-scoped marketplace metrics for the authenticated author only.

Supported `period` values:

- `last_7_days`
- `last_30_days`
- `last_90_days`
- `this_year`
- omitted for all-time

### `GET /api/v1/authors/:id/earnings`

Returns:

- daily earnings points
- total earnings
- average per day
- best skill by revenue

This endpoint is also author-scoped to the authenticated account.

## Error Patterns

Common shapes used by REST controllers:

```json
{
  "error": "Message",
  "details": []
}
```

Validation or authorization failures usually return:

- `401` for missing or invalid API key
- `403` for author-only actions
- `404` for missing records
- `422` for invalid user input or domain rule failures
