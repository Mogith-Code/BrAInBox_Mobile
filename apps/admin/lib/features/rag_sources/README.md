# RagSources (admin)

| | |
|---|---|
| **Owner** | Samni (`@samni`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Upload syllabus, teacher guides and approved notes for RAG; ingestion status; re-index. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-rag-sources` (tickets: `feature/admin-rag-sources/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| RAG sources | `presentation/rag_sources_screen.dart` | `/rag-sources` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/rag/sources` | Sources with ingestion status |
| `POST` | `/admin/rag/sources` | Upload a source (multipart, returns a job id) |
| `POST` | `/admin/rag/reindex` | Re-index everything (job id) |

Shared models used: `AiJob` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
rag_sources/
├── domain/rag_sources_models.dart              freezed models
├── data/rag_sources_repository.dart            calls ApiClient (the only place that does)
├── application/rag_sources_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/rag_sources/` (same structure as this folder).
