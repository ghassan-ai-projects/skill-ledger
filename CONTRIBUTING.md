# Contributing

Thanks for helping improve SkillLedger.

## Before You Start

- read [README.md](/Users/ghassan/my-projects/skill-ledger/README.md)
- skim [documentation/README.md](/Users/ghassan/my-projects/skill-ledger/documentation/README.md)
- open an issue before large changes so we can align on direction

## Development Setup

```bash
gem install bundler:4.0.12
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails test
```

## Project Conventions

- use Ruby `3.3.11`
- keep the app API-only and service-oriented
- prefer small, explicit service objects for business logic
- add or update tests for behavior changes
- update documentation when the public API, workflows, or repository expectations change

## Pull Requests

Please aim for:

- a clear problem statement
- focused changes
- tests for new behavior or bug fixes
- documentation updates when applicable

Include in the PR description:

- what changed
- why it changed
- how you verified it
- any follow-up work or known gaps

## Suggested Validation

Run the relevant subset locally before opening a PR:

```bash
bin/rails test
bin/rubocop
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit
```

Or run the full local CI wrapper:

```bash
bin/ci
```

## Documentation Expectations

This repository treats the root README as the primary document and `documentation/` as the detailed reference set. If your change affects user behavior, contributor workflow, deployment, security assumptions, or API behavior, please update the relevant docs in the same PR.

## Conduct

By participating in this repository, you agree to follow the standards in [CODE_OF_CONDUCT.md](/Users/ghassan/my-projects/skill-ledger/CODE_OF_CONDUCT.md).
