# API contract

**The backend's `/docs` page (OpenAPI / Swagger UI) is the contract.**

The FastAPI backend lives in the `brainbox-backend` repo. When it is running
locally, open:

- Swagger UI: <http://localhost:8000/docs>
- Raw OpenAPI JSON: <http://localhost:8000/openapi.json>

All app endpoints are under `/api/v1` (for example `GET /api/v1/units`).

## Rules

1. **The OpenAPI spec wins.** The endpoint tables in each feature's
   `README.md` are *plans*. When the backend publishes an endpoint, update
   the README and the repository code to match `/docs`.
2. **Models follow the spec.** Field names in `freezed` models are camelCase
   in Dart and snake_case in JSON (`topicId` <-> `topic_id`). This is set in
   `build.yaml`, so you don't need `@JsonKey(name: ...)` for it.
3. **Errors** come back in one shape. `ApiException` reads it:
   ```json
   { "error": { "code": "topic_not_found", "message": "Topic not found." } }
   ```
4. **Auth:** every request carries `Authorization: Bearer <Firebase ID token>`.
   `AuthInterceptor` adds it. If the backend answers 401, the app refreshes
   the token once and retries.
5. **Slow AI work** returns a job. Poll `GET /jobs/{job_id}` with `JobPoller`
   until `status` is `succeeded` or `failed`.
6. **Changing the contract:** if you need a new endpoint or field, open an
   issue or PR in `brainbox-backend` first. Don't invent fields in the app.

## Assumptions to confirm with the backend

| Topic | Current assumption | Where in the code |
|---|---|---|
| Base path | `/api/v1` | `brainbox_core/lib/config/env.dart` |
| JSON naming | snake_case | `build.yaml` in each package |
| Error body | `{"error": {"code", "message"}}` | `api/api_exception.dart` |
| User role | `GET /auth/me` → `role` (`student` / `admin`) | `auth/current_user_provider.dart` |
| Job polling | `GET /jobs/{id}` → `{id, status, progress, result, error}` | `api/job_poller.dart`, `models/ai_job.dart` |
