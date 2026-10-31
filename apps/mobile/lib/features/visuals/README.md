# Visuals (mobile)

| | |
|---|---|
| **Owner** | Mogith (`@mogith`) |
| **App** | student app (`apps/mobile`) |
| **Purpose** | Diagram gallery, zoomable viewer with numbered labels, and the generate-visual flow. |
| **Jira epic** | `BRN-E05` Visual Learning *(placeholder key)* |
| **Git branch** | `feature/visuals-generation` |

## Screens (Figma B8 - B10)

| Screen | File | Route |
|---|---|---|
| Diagrams gallery (B8) | `presentation/diagram_gallery_screen.dart` | `/visuals/topics/:topicId` |
| Diagram viewer (B9) | `presentation/diagram_viewer_screen.dart` | `/visuals/view/:visualId` |
| Generate a visual (B10) | `presentation/generate_visual_screen.dart` | `/visuals/generate?topicId=...` (topic optional) |

### How to reach them (real ids only)

The backend has no `/units` or `/topics` list yet, so real topic ids come
from `GET /home/summary`:

- **Gallery:** Home -> a *Continue learning* card (or the *Next best action*)
  -> topic page -> **Open diagrams**. The topic page's Diagrams tab can later
  show `DiagramGallery(topicId: topicId, showHeader: false)`.
- **Viewer:** tap a diagram in the gallery, or it opens by itself after
  generating.
- **Generate:** the gallery's last card / the viewer's **New visual** (with
  the topic), or Dev menu -> *Generate a visual* (no topic, `topic_id: null`).

## How visuals are drawn (backend)

Gemini plans the visual. Diagrams, flowcharts and tables are **Mermaid** text
drawn by **Kroki**; pictures (illustrations) are drawn by Cloudflare's image
model with no text in them. The app shows `image_url` (it loads without an
auth header). If `image_url` is null it renders `mermaid_code` itself with
Kroki (`data/diagram_renderer.dart`; your own server:
`--dart-define=DIAGRAM_RENDER_URL=http://10.0.2.2:8001`).

Labels come as a list `[{number, name, description, x, y}]`:

- illustration: `x, y` are 0-1 fractions -> numbered markers on the picture
  (4:3 is used when `width` / `height` are null);
- diagram / flowchart / table: `x, y` are null -> listed under the visual only.

## API endpoints

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/topics/{topic_id}/visuals` | `{topic_id, topic_title, unit_code ("6"), unit_title, visuals}`: approved visuals + my drafts, newest first. `topic_id` must be a real UUID. |
| `GET` | `/visuals/{visual_id}` | One `VisualOut` |
| `POST` | `/visuals/generate` | `{prompt (5-300 chars), visual_type, style, topic_id \| null}` -> `202 {job_id}` |
| `GET` | `/jobs/{job_id}` | `{id, job_type, status, progress, result, error, error_code, ...}` |
| `POST` | `/visuals/{visual_id}/report` | `{reason, details? (<= 500)}` -> 201 |

`visual_type`: `process` | `structure` | `comparison`.
`style`: `flat_colour` | `textbook_line` | `cross_section`.
`reason`: `wrong_label` | `inaccurate` | `unclear` | `offensive` | `other`.

### Generating, step by step

1. `POST /visuals/generate` -> `job_id`.
2. `JobPoller` asks `GET /jobs/{job_id}` every 2 s (gives up after 3 min).
   A real visual takes about 10-60 s. The backend only sends progress 0 and
   then 1, so the screen shows a **moving** loader ("Drawing your visual...").
3. `succeeded`: `result = {"visual_id": ...}` -> `GET /visuals/{id}` -> the
   viewer opens and the topic gallery refreshes.
4. `failed`: `error` is already a sentence for the student and is shown as
   it is (e.g. "I can only draw Biology visuals."). Without it, `error_code`
   picks the text in `ErrorMessages`. `cancelled` says the request was
   cancelled.

### Error codes (`ErrorMessages.fromCode` in brainbox_core)

`VISUAL_NOT_FOUND`, `TOPIC_NOT_FOUND`, `JOB_NOT_FOUND`, `ALREADY_REPORTED`
(the report sheet treats it as sent), `VISUAL_LIMIT_REACHED` ("Try again in
2 hours" from `retry_after`), `NOT_BIOLOGY`, `AI_DAILY_LIMIT`,
`AI_SERVICE_UNAVAILABLE`, `FILE_NOT_FOUND`.

## Fakes

The real app always uses `ApiVisualsRepository`. `FakeVisualsRepository`
runs only with `--dart-define=USE_FAKE_API=true` (debug) and in tests. It
behaves like the backend (queued -> running -> succeeded); a prompt with
**fail** is refused with `NOT_BIOLOGY`.

Tests: `test/features/visuals/` (+ `brainbox_core/test/utils/` for the
messages and `Formatters.unitLabel` / `waitTime`).
