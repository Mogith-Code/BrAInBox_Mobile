# Community (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Study groups, group feed, post detail and create post. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/community` (tickets: `feature/community/BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Community | `presentation/groups_screen.dart` | `/community` |
| Group feed | `presentation/group_feed_screen.dart` | `/community/groups/:groupId` |
| Post | `presentation/post_detail_screen.dart` | `/community/posts/:postId` |
| Create post | `presentation/create_post_screen.dart` | `/community/create` |

## API endpoints it will use

> Planned paths only. The backend's `/docs` (OpenAPI) is the real contract -
> update this table when the backend publishes the endpoints.

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/groups` | Groups |
| `GET` | `/groups/{group_id}/posts` | Posts in a group |
| `GET` | `/posts/{post_id}` | One post with comments |
| `POST` | `/groups/{group_id}/posts` | Create a post |
| `POST` | `/posts/{post_id}/report` | Report a post to moderators |

Shared models used: `CommunityPost` (from `brainbox_core`, re-exported in `domain/`).

## Folders

```
community/
├── domain/community_models.dart              freezed models
├── data/community_repository.dart            calls ApiClient (the only place that does)
├── application/community_controller.dart     Riverpod controller (loading / error / data)
└── presentation/                       screens + widgets/ (UI only)
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/community/` (same structure as this folder).
