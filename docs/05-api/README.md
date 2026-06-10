# API Reference

## Canonical Documents

Read these first:

- [Future API Direction](./future-api-direction.md)
- [Vision Correction Decision](../03-research/vision-correction-decision-2026-06-10.md)

## Status Note

The current API surface in the repo still includes hosted-execution endpoints.

Those endpoints describe the current implementation history, not the preferred long-term product model. The target direction is skill verification, purchase, and acquisition for client-side execution.

The SkillLedger API is fully documented in the project root:

- **OpenAPI 3.0 Spec:** [`openapi.yaml`](../../openapi.yaml) (900+ lines, comprehensive)
- **Swagger UI:** Served via `rswag-ui` gem at `/api-docs` when running

---

## Quick Reference

**Base URL:** `http://localhost:3000/api/v1`  
**Auth:** `X-API-Key` header (see [Authentication](../../README.md#authentication))  
**Content-Type:** `application/json`

### Endpoint Summary

| Method | Path | Description |
|--------|------|-------------|
| GET | `/skills` | List skills (search, filter, sort, paginated) |
| POST | `/skills` | Create a skill |
| GET | `/skills/:id` | Get skill details (incl. ratings, favorites) |
| POST | `/skills/:id/execute` | Execute a skill |
| GET | `/executions` | List executions |
| PATCH | `/executions/:id/fail` | Fail an execution (slash + refund) |
| POST | `/executions/:id/review` | Review a completed execution |
| GET | `/skills/:id/reviews` | List reviews for a skill |
| GET | `/ledger` | List all ledger entries |
| GET | `/reports` | Summary statistics |
| GET | `/favorites` | List favorited skills |
| POST | `/favorites` | Add skill to favorites |
| DELETE | `/favorites/:skill_id` | Remove from favorites |
| GET | `/me/library` | Personal library |
| GET | `/authors/:id/analytics` | Author analytics dashboard |
| GET | `/authors/:id/earnings` | Earnings breakdown |

---

## Detailed Documentation

See the project README for full curl examples, request/response schemas, and error shapes:

```bash
# Open in browser
open README.md
```

Or view the OpenAPI spec:

```bash
# Parse with any OpenAPI tool
openapi.yaml
```
