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

Note: trying to create a listed skill before a verified version exists is rejected by domain rules.

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

The artifact payload is verified immediately and the response includes the verification result.

### `skills/version.get`

Returns details for a specific owned version, or the latest version when no version is provided.

Params:

- `skill_id`
- optional `version`

### `skills/listing.set_status`

Changes listing status for an owned skill.

Params:

- `skill_id`
- `listing_status`

### `skills/list`

Lists publicly listed skills that currently have a verified version available for acquisition.

### `skills/get`

Returns details for a public verified skill, including:

- author summary
- manifest summary
- checksum
- verification data

Params:

- `skill_id`
- optional `version`

### `skills/purchase`

Purchases a specific verified version.

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

- public acquisition is limited to listed skills with verified versions
- authors cannot buy their own skills
- repeated paid purchases of the same version by the same buyer return the existing paid purchase
- acquisition marks `acquired_at` on first successful artifact retrieval
