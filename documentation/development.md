# Development

## Local Workflow

Typical setup:

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

## Test And Quality Commands

Run tests:

```bash
bin/rails test
```

Run lint:

```bash
bin/rubocop
```

Run security checks:

```bash
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit
```

Run the local CI wrapper:

```bash
bin/ci
```

## Code Organization Expectations

- controllers should stay thin
- domain rules belong in service objects or models
- public response shapes should stay documented
- tests should accompany behavior changes

## Documentation Expectations

When changing user-facing behavior, update:

- [README.md](/Users/ghassan/my-projects/skill-ledger/README.md) for the top-level story
- the relevant detailed file in `documentation/`
- [openapi.yaml](/Users/ghassan/my-projects/skill-ledger/openapi.yaml) when the HTTP contract changes

## Fixtures And Seeds

- `db/seeds.rb` is the fastest path for local manual testing
- `test/fixtures/` is the stable baseline for automated tests

## Historical Design Material

The repository contains older planning and product documents under the numbered `docs/` subdirectories. Keep those intact unless you are intentionally cleaning up project history; use the `documentation/` files for current public guidance.
