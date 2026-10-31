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
| Generate a visual (B10) | `presentation/generate_visual_screen.dart` | `/visuals/generate?topicId=...` |

The topic page's **Diagrams** tab can reuse the grid without the header:
`DiagramGallery(topicId: topicId, showHeader: false)`.

## How visuals are drawn

| Kind | Made by | Shown by |
|---|---|---|
| `diagram`, `flowchart`, `table` | The LLM writes **Mermaid** text (labels always spelled right) | `image_url` if the backend rendered it, else the app renders `mermaid_code` with **Kroki** (`data/diagram_renderer.dart`) |
| `illustration` | An image model (no text inside the picture) | `image_url` (PNG) |

Labels are never drawn into the picture. They come as a list
(`labels: [{number, name, description, x, y}]`); the app puts numbered
markers at `x, y` (0-1 of the image size) and shows the name and
description in the bottom panel. Labels without `x, y` are listed only.

Kroki is free and open source. Use your own server with
`--dart-define=DIAGRAM_RENDER_URL=http://10.0.2.2:8001`.

## API endpoints

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/topics/{topic_id}/visuals` | `{topic_id, topic_title, unit_code, unit_title, visuals: [VisualOut]}` |
| `GET` | `/visuals/{visual_id}` | One `VisualOut` |
| `POST` | `/visuals/generate` | `{prompt, visual_type, style, topic_id?}` -> `{job_id}` (GENERATE_VISUAL) |
| `GET` | `/jobs/{job_id}` | Poll; on success `result` = `{visual_id}` or `{visual: VisualOut}` |
| `POST` | `/visuals/{visual_id}/report` | `{reason, details?}` (reason = `VisualReportReason`) |

`VisualOut`: `id, title, topic_id, concept_id, kind, image_url, mermaid_code,
alt_text, labels, style, width, height, is_ai_generated, is_verified,
created_at`. Shared model: `Visual` in `brainbox_core`.

`visual_type`: `process` | `structure` | `comparison`.
`style`: `flat_colour` | `textbook_line` | `cross_section`.

## Fake API

`--dart-define=USE_FAKE_API=true` uses `data/fake_visuals_repository.dart`
(the Figma "Mendelian inheritance" topic). A prompt containing **fail**
makes the job fail, to try the error state.

Tests: `test/features/visuals/`.
