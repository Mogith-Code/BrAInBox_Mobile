# Community (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Study groups, group feed, post detail and create post. |
| **Jira epic** | `BRN-??` *(TODO: add the epic key)* |
| **Git branch** | `feature/community` (tickets: `feature/community-BRN-xx-short-name`) |

## Screens

| Screen | File | Route |
|---|---|---|
| Community (my groups + groups to join) | `presentation/groups_screen.dart` | `/community` |
| Group feed (Latest / Unanswered / Top) | `presentation/group_feed_screen.dart` | `/community/groups/:groupId` |
| Post (replies, votes, best answer, report) | `presentation/post_detail_screen.dart` | `/community/posts/:postId` |
| Create post (AI topic tag) | `presentation/create_post_screen.dart` | `/community/create?groupId=` |

## API endpoints (backend `api/modules/community`)

| Method | Path | Used by |
|---|---|---|
| `GET` | `/groups` | Community tab; Create post without a group |
| `GET` | `/groups/{id}` | Feed header (name, membership) |
| `POST` / `DELETE` | `/groups/{id}/join` | Join / Leave |
| `GET` | `/groups/{id}/posts?sort=new\|top&page=&size=20` | Feed (Latest = `new`, Top = `top`) |
| `POST` | `/groups/{id}/posts` | Create post |
| `POST` | `/posts/suggest-topic` | AI topic tag while writing (debounced 800 ms) |
| `GET` | `/units/u{n}/topics` | Picking another topic tag (unit groups only) |
| `GET` / `PATCH` / `DELETE` | `/posts/{id}` | Post page; edit / delete my post |
| `POST` | `/posts/{id}/replies` | Reply |
| `PATCH` / `DELETE` | `/replies/{id}` | Edit / delete my reply |
| `POST` / `DELETE` | `/posts/{id}/accept[/{reply}]` | Mark / un-mark the best answer (post author) |
| `POST` | `/votes` | Up / down votes; Helpful / Not helpful on the AI answer |
| `POST` | `/posts/{id}/report`, `/replies/{id}/report` | Report with a reason |
| `GET` | `/insights/units` | Weak units first on the Community tab (insights repository) |

### Rules the screens follow

- **Weak units first:** unit groups ordered by my unit mastery (lowest first), then units not assessed yet, then groups without a unit (General). Weak / very weak units get a status chip. If `/insights/units` fails, the backend's order is kept and the groups still load.
- **Unanswered** is filtered in the app (`reply_count == 0` on the `new` feed); it reads up to 5 pages to find something to show.
- **Post page order:** the AI-suggested answer first (AiBadge + Helpful / Not helpful = votes 1 / -1), then the accepted answer, then the rest by score.
- Votes show at once and are undone if the backend refuses them (e.g. `NOT_A_MEMBER`). Vote buttons are disabled on my own content (`CANNOT_VOTE_OWN`).
- Only display names are shown (`author.name`), never emails. An AI answer has no author and shows "BrAInBox AI".
- My own `pending` / `flagged` content shows a note (icon + word + colour). A created post that comes back `flagged` gets a "Waiting for an admin" dialog.
- Pull-to-refresh everywhere; the AI answer to a question arrives a few seconds after posting.

## Not in this version

- **Images in posts:** the backend has no upload endpoint for community posts yet.
- **Tags** (`tags` on `PostCreate`): not edited in the app; only the topic tag.

## Folders

```
community/
├── domain/community_models.dart              plain models (fromJson), match the backend schemas
├── data/community_repository.dart            calls ApiClient (the only place that does)
├── application/community_controller.dart     Riverpod 3 providers / notifiers (no codegen)
└── presentation/                              4 screens + widgets/community_widgets.dart
```

**Flow:** screen → controller → repository → `ApiClient`. Screens never call
Dio or Firebase directly.

Tests live in `test/features/community/` (same structure as this folder).
