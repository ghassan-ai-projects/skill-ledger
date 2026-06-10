# SkillLedger — Rails API Architecture Plan
**Status:** Complete

## Stack
- **Rails 7+ API mode** — no views, no cookies/sessions
- **SQLite** (dev) / **PostgreSQL** (prod)
- **RSpec** + **FactoryBot** + **SimpleCov** — testing
- **rswag** — OpenAPI/Swagger documentation
- **rubocop** — linting
- **GitHub Actions** — CI pipeline

## Architecture
```
app/
├── controllers/api/v1/   # Thin — parse input, call services, return response
├── services/             # ALL business logic
├── models/               # Active Record
├── repositories/         # Complex query abstraction (optional)
└── middleware/           # Auth, error handling
```

## Issues (Project #5)
- #4: Layered architecture
- #3: OpenAPI docs via rswag
- #2: RSpec test suite (80% coverage)
- #1: GitHub Actions CI

## Repo
`gh-assan/skillledger` — public


## Notes
skill-ledger Rails project built and deployed
