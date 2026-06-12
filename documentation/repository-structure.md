# Repository Structure

## Top Level

- `app/`: Rails controllers, models, jobs, mailers, services, and views
- `bin/`: executable scripts for setup, test, CI, lint, and server tasks
- `config/`: Rails configuration, environments, deploy config, and initializers
- `db/`: schema, migrations, and seeds
- `documentation/`: public documentation set
- `docs/`: older historical planning and research material
- `lib/`: custom rake tasks and library code
- `swagger/`: rswag assets
- `test/`: Minitest suites and fixtures
- `openapi.yaml`: current OpenAPI description

## Application Code

### Controllers

`app/controllers/api/v1/` contains the public HTTP surface:

- `base_controller.rb`: auth, pagination, and sorting helpers
- `skills_controller.rb`: listing and version publication REST flows
- `favorites_controller.rb`: favorite CRUD
- `library_controller.rb`: account library aggregation
- `ledger_entries_controller.rb`: ledger inspection
- `reports_controller.rb`: global counters and summary stats
- `analytics_controller.rb`: author analytics and earnings
- `mcp_controller.rb`: JSON-RPC style MCP entrypoint

### Models

The core domain lives in:

- `account.rb`
- `skill.rb`
- `skill_version.rb`
- `skill_artifact.rb`
- `skill_verification.rb`
- `purchase.rb`
- `ledger_entry.rb`
- `favorite.rb`

### Services

Business logic is intentionally concentrated in service objects:

- `skill_creation_service.rb`
- `skill_version_registration_service.rb`
- `skill_artifact_verification_service.rb`
- `skill_listing_status_service.rb`
- `skill_purchase_service.rb`
- `skill_acquisition_service.rb`
- `library_service.rb`
- `analytics_service.rb`
- `favorite_service.rb`
- `mcp_service.rb`

## Tests

- `test/controllers/`: endpoint behavior
- `test/services/`: business logic coverage
- `test/models/`: model validation and association coverage
- `test/e2e/`: higher-level scenario tests
- `test/fixtures/`: seeded fixture state for tests

## Historical Docs

The numbered directories inside `docs/` capture previous planning and product iterations. Keep them for traceability, but treat the files in `documentation/` as the current public reference set.
