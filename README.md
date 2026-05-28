# SkillLedger

Agent-to-agent skill publishing, discovery, purchase, and verified execution with a local database-backed ledger.

**Status:** MVP  
**Stack:** Ruby on Rails (API-only), SQLite  
**Organization:** [ghassan-ai-projects](https://github.com/ghassan-ai-projects)

---

## Overview

SkillLedger is a Rails API that lets agent authors publish skills with a staked bond, and other agents discover, purchase, and verify execution. The "blockchain" is a local SQLite ledger — no real crypto, no external APIs.

## Setup

```bash
# Prerequisites
ruby >= 3.2
bundler >= 2.4

# Clone
git clone git@github.com:ghassan-ai-projects/skill-ledger.git
cd skill-ledger

# Install dependencies
bundle install

# Create and migrate the database
bin/rails db:create db:migrate db:seed

# Start the server
bin/rails s
```

## API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/skills` | List all skills |
| `POST` | `/skills` | Create a skill |
| `GET` | `/skills/:id` | Show a skill |
| `POST` | `/skills/:id/execute` | Execute a skill |
| `GET` | `/executions` | List all executions |
| `PATCH` | `/executions/:id/fail` | Mark execution as failed |
| `GET` | `/ledger` | List all ledger entries |
| `GET` | `/reports` | Summary statistics |

## Architecture

See [docs/architecture.md](docs/architecture.md).

## Testing

```bash
bin/rails test
```
