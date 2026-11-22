# RagSources (admin)

| | |
|---|---|
| **Owner** | Samni (`@samni`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Upload syllabus, teacher guides and approved notes for RAG; ingestion status; re-index. |
| **Jira epic** | `BRN-??` *(TODO(samni): add the epic key)* |
| **Git branch** | `feature/admin-rag-sources` (tickets: `feature/admin-rag-sources/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| RAG sources | `presentation/rag_sources_screen.dart` | `/rag-sources` |

## API endpoints it uses

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/rag/sources` | Sources with status (pending / ingesting / ready / failed) and chunk count |
| `POST` | `/admin/rag/sources` | Upload (multipart: file, title, source_type, unit_number?, year?) -> 202 job |
| `POST` | `/admin/rag/reindex` | Re-index one (`{document_id}`) or all (no body) -> 202 job |
| `GET` | `/jobs/{job_id}` | Wait for the job (`JobPoller`), then the list reloads |

File picking goes through `pickUploadProvider` (`lib/widgets/pick_upload.dart`)
so tests can hand in a file.

## Folders

```
rag_sources/
├── domain/rag_sources_models.dart              plain classes with fromJson
├── data/rag_sources_repository.dart            calls ApiClient (the only place that does)
├── application/rag_sources_controller.dart     plain Riverpod 3 providers
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/rag_sources/` (same structure as this folder).
