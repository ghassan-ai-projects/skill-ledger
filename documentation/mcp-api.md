# MCP API

SkillLedger exposes an MCP-style JSON-RPC endpoint at `POST /api/v1/mcp`.

Every request still requires the `X-API-Key` header because account identity is provided by HTTP auth, not by the JSON-RPC payload.

## Envelope

Example request:

```json
{
  "jsonrpc": "2.0",
  "id": "skills-list",
  "method": "skills/list",
  "params": {}
}
```

Example success:

```json
{
  "jsonrpc": "2.0",
  "id": "skills-list",
  "result": {}
}
```

Example error:

```json
{
  "jsonrpc": "2.0",
  "id": "skills-list",
  "error": {
    "code": -32601,
    "message": "Method not found: skills/unknown"
  }
}
```

## Current Methods

### `skills/create`

Creates a draft skill owned by the authenticated account.

Params:

- `name`
- `description`
- `price`
- optional `listing_status`

Note: trying to create a listed skill before an approved version exists is rejected by domain rules.

### `skills/mine.list`

Returns only the authenticated author's skills, including:

- versions
- purchase summary
- latest version summary

### `skills/version.publish`

Publishes a version for an owned skill.

Params:

- `skill_id`
- `version`
- optional `changelog`
- `artifact`

The artifact payload is verified immediately and the response includes the verification result. If verification succeeds, a skill review is automatically created (`pending`, or `rejected` if a hard-fail policy check trips); the response includes the review's `status`.

### `skills/version.get`

Returns details for a specific owned version, or the latest version when no version is provided.

Params:

- `skill_id`
- optional `version`

### `skills/listing.set_status`

Changes listing status for an owned skill. Moving to `listed` requires at least one approved version.

Params:

- `skill_id`
- `listing_status`

### `skills/version.review_status`

Returns the skill review status for one of the caller's own versions.

Params:

- `skill_id`
- `version`

Response (`result.review`):

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

### `skills/review.list_pending` (admin only)

Lists all `pending` skill reviews across the marketplace. Requires `accounts.admin: true`; otherwise returns a `-32001` authorization error.

### `skills/review.decide` (admin only)

Approves, rejects, or revokes a skill review. Requires `accounts.admin: true`.

Params:

- `review_id`
- `decision` (`approve`, `reject`, or `revoke`)
- optional `reason`

### `skills/list`

Lists publicly listed skills that currently have an approved version available for acquisition.

### `skills/get`

Returns details for a public, approved skill version, including:

- author summary
- manifest summary
- checksum
- verification data
- approval data (`status`, `decided_at`)

Params:

- `skill_id`
- optional `version`

### `skills/purchase`

Purchases a specific verified, approved version. Rejected if the version was later `revoked`.

Params:

- `skill_id`
- `version`

Response includes:

- purchase id
- amount
- status
- entitlement token

### `skills/acquire`

Returns the purchased artifact payload and entitlement metadata for the authenticated buyer.

Params:

- `purchase_id`

## Error Codes

The controller currently uses JSON-RPC style codes including:

- `-32601`: method not found
- `-32602`: invalid params or lookup failure
- `-32000`: domain failure, such as purchase constraints
- `-32001`: authorization error for author-only ownership actions

## Practical Notes

- public acquisition is limited to listed skills with verified, approved versions
- authors cannot buy their own skills
- repeated paid purchases of the same version by the same buyer return the existing paid purchase
- acquisition marks `acquired_at` on first successful artifact retrieval
- a verified version is not enough to be listed or purchased — it must also have an `approved` skill review; see [security-model.md](security-model.md) for the approval workflow
