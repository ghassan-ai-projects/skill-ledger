# Development

Concise local reference for working on SkillLedger.

## Setup

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

The app listens on `http://localhost:3000` by default.

## Local Validation

Recommended command: `bin/local-test` (added in T2).

Until that wrapper exists, run:

```bash
PATH="$HOME/.rbenv/shims:$PATH" PARALLEL_WORKERS=1 bin/rails test
```

## Troubleshooting

- `rbenv` not on `PATH`: prepend `PATH="$HOME/.rbenv/shims:$PATH"` before `bundle`, `ruby`, or `bin/rails` commands.
- SQLite locking: stop other Rails processes, then rerun the command against a single local server/test process.
- Sandbox parallel test failures: force serial execution with `PARALLEL_WORKERS=1`.
