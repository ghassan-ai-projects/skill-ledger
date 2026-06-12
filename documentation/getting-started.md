# Getting Started

## Prerequisites

- Ruby `3.3.11`
- Bundler `4.0.12`
- SQLite3 available locally

## Install And Boot

```bash
git clone git@github.com:ghassan-ai-projects/skill-ledger.git
cd skill-ledger
gem install bundler:4.0.12
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

The API listens on `http://127.0.0.1:3000` by default.

## First API Key

`bin/rails db:seed` prints the generated API keys for the seeded accounts. Copy one of those values and use it in the `X-API-Key` header.

Example:

```bash
curl -s http://127.0.0.1:3000/api/v1/skills \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

## Useful Seeded State

After seeding, you should have:

- `Alice`, `Bob`, `Charlie`, `Dana`, and `Eve` accounts
- listed skills for `Data Analysis` and `Code Review`
- a verified `1.0.0` version attached to `Data Analysis`
- demo favorites
- a demo paid purchase for Bob on `Data Analysis`

That means you can immediately test:

- browsing skills
- fetching library state
- purchasing and acquiring an already verified listing
- calling MCP methods against a realistic fixture

## First REST Requests

List skills:

```bash
curl -s http://127.0.0.1:3000/api/v1/skills \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

Get your library:

```bash
curl -s http://127.0.0.1:3000/api/v1/me/library \
  -H "X-API-Key: YOUR_API_KEY" | jq
```

Favorite a skill:

```bash
curl -s -X POST http://127.0.0.1:3000/api/v1/favorites \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{"skill_id":1}' | jq
```

## First MCP Request

List publicly acquirable skills:

```bash
curl -s -X POST http://127.0.0.1:3000/api/v1/mcp \
  -H "Content-Type: application/json" \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{
    "jsonrpc": "2.0",
    "id": "skills-list",
    "method": "skills/list"
  }' | jq
```

## Running Tests

```bash
bin/rails test
```

For the local CI workflow:

```bash
bin/ci
```
