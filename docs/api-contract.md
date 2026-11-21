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

## Endpoints the student app calls (exams, privacy)

Other features list theirs in their own `README.md`.

| Method | Path | Used by | Notes |
|---|---|---|---|
| `GET` | `/papers?year=&type=&size=` | Past papers | `Page[PaperSummary]` (`items`, `total`) |
| `GET` | `/papers/{id}?hide_outdated=` | Exam mode | Questions without answers, `is_outdated` per question |
| `POST` | `/papers/generate` | Generate model paper | Blueprint body, **202** `{job_id, from_bank, to_generate}`; poll `GET /jobs/{job_id}`, `result.paper_id` |
| `POST` | `/papers/{id}/submit` | Exam mode | `answers[]` with `selected` (MCQ letter) or `answer_text`; `status` is `marking` while written answers are marked |
| `GET` | `/auth/me/export` | Data & privacy | **Download my data**: one JSON object with everything kept about the student. *Added in backend task B3.* |
| `DELETE` | `/auth/me` | Data & privacy | **204**. Deletes all student data and the Firebase login |

## Offline

`GET /learn/subjects`, `/learn/subjects/{id}/units`, `/learn/units/{id}`,
`/learn/topics/{id}` and `/learn/topics/{id}/notes?type=full|short` are kept
in the Hive box `offline_cache` (`features/offline/offline_cache.dart`).
When the phone is offline (`ApiException.isOffline`) the last saved answer is
used. Everything else shows the "You're offline" state of `ErrorBanner`.
The box is cleared on log out and on account delete.
