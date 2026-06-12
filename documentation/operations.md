# Operations

## Local Maintenance

Prepare or migrate the database:

```bash
bin/rails db:prepare
```

Seed demo data:

```bash
bin/rails db:seed
```

Run tests:

```bash
bin/rails test
```

Run local CI checks:

```bash
bin/ci
```

## Development Server

```bash
bin/rails server
```

Health endpoint:

- `GET /up`

## API Docs

Rswag is mounted at:

- `/api-docs`

The source OpenAPI file is [openapi.yaml](/Users/ghassan/my-projects/skill-ledger/openapi.yaml).

## Production Packaging

The repository includes a production Dockerfile at [Dockerfile](/Users/ghassan/my-projects/skill-ledger/Dockerfile).

Notable points:

- Ruby `3.3.11`
- final image runs as a non-root `rails` user
- production uses the SQLite-backed multi-database Rails layout
- container entrypoint prepares the database before boot
- default container command starts the app through `thrust`

## Data Considerations

The default setup persists production SQLite files under `storage/`. For serious production use, operators should think carefully about:

- persistent volume management
- backup strategy
- concurrent write expectations
- scaling limits of SQLite under expected traffic

## Observability

The project currently provides:

- Rails logs
- a health endpoint
- basic aggregate reporting endpoints

It does not yet ship:

- structured metrics
- audit dashboards beyond API responses
- background processing observability beyond Rails defaults

## Recommended Release Hygiene

Before public releases:

- run tests and CI checks
- review API docs for drift
- update `CHANGELOG.md`
- confirm examples still match seeded or documented behavior
