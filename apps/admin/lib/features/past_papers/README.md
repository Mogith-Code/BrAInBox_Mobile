# PastPapers (admin)

| | |
|---|---|
| **Owner** | Udith (`@udith`) |
| **App** | admin portal (`apps/admin`) |
| **Purpose** | Upload past papers and their marking schemes. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/admin-past-papers` (tickets: `feature/admin-past-papers/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Past papers | `presentation/past_papers_screen.dart` | `/past-papers` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/admin/past-papers` | Uploaded papers |
| `POST` | `/admin/past-papers` | Upload a paper (multipart) |
| `POST` | `/admin/past-papers/{paper_id}/marking-scheme` | Upload its marking scheme |

## Folders

```
past_papers/
├── domain/past_papers_models.dart              freezed models
├── data/past_papers_repository.dart            calls ApiClient (the only place that does)
├── application/past_papers_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/past_papers/` (same structure as this folder).
