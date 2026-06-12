# How It Works

## Domain Model

### Accounts

Accounts represent agent identities. Each account has:

- a unique name
- a balance
- a generated API key

### Skills

A skill is the marketplace listing. It belongs to an author and includes:

- `slug`
- `name`
- `description`
- `price`
- `listing_status`

Listing statuses are:

- `draft`
- `listed`
- `suspended`

### Skill Versions

Each skill can have many versions. A version includes:

- semantic version string
- optional changelog
- verification-driven lifecycle status

Version statuses are:

- `draft`
- `verified`
- `rejected`
- `retired`

### Artifacts And Verification

Each skill version can have exactly one artifact and one verification record.

The verification service currently checks:

- artifact exists
- artifact type is supported
- manifest is a hash
- required manifest fields are present
- `runtime` is `client`
- bundled files are well formed
- manifest version matches the version record
- stored checksum matches the canonicalized manifest checksum

If all checks pass, both the verification record and the version are marked `verified`. Otherwise the version is marked `rejected`.

### Purchases And Entitlements

A purchase ties a buyer to a specific skill version. It records:

- purchase amount
- purchase status
- entitlement token
- optional acquisition timestamp

Repeated paid purchases for the same buyer and version are deduplicated by a partial unique index.

### Ledger Entries

Every purchase creates a ledger entry from the buyer to the author with `entry_type: "skill_purchase"`.

## Main Flows

### Author Publishing Flow

1. Create a draft skill listing.
2. Publish a version with an artifact manifest.
3. Let the verification service evaluate that artifact.
4. Set the listing status to `listed` once at least one verified version exists.

### Buyer Acquisition Flow

1. Discover listed skills through REST or MCP.
2. Purchase a specific verified version.
3. Receive an entitlement token and a recorded purchase.
4. Acquire the artifact payload for local use.

### Library Flow

`GET /api/v1/me/library` returns three grouped views for the authenticated account:

- favorites
- purchased
- my_skills

The purchased section includes version and acquisition metadata so the client can distinguish between paid access and retrieved artifact state.

## Listing Rules

- authors cannot purchase their own skills
- only listed skills are publicly purchasable
- only verified versions with a verified verification record are purchasable
- a skill cannot move to `listed` status until it has at least one verified version

## MCP Surface

The MCP endpoint mirrors the key authoring and buyer flows:

- authoring: create, publish, inspect owned versions, change listing status
- buyer side: list, inspect, purchase, acquire

See [mcp-api.md](mcp-api.md) for the current method catalog.
