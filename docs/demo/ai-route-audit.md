# Student app AI route audit (demo mode)

Base: frontend `origin/fix/app/e2e-issues` (b2a8256), backend `origin/fix/app/e2e-issues` (b1553e8).
Paths are relative to `/api/v1`. Backend evidence is `BrAInBox_Backend/api/modules/...`;
frontend evidence is `apps/mobile/lib/features/...`.

**Reaches AI:** `none`, `sync` (the request waits for the ai_service), `background`
(the request queues an AI job that runs after the reply).
**Demo action:** `serve locally` (answered by `DemoAiInterceptor`, never sent),
`merge` (sent to the real backend, demo items added to the reply, with a local
fallback where safe), `rewrite` (sent, but the body is changed so no AI work starts),
`pass through` (sent unchanged).

Every id the demo makes starts with `demo-`. Any request whose path or JSON body holds a
`demo-` id is answered locally (404 if the item no longer exists) and never sent
(`app/demo/demo_engine.dart`, end of `handle`).

## AI routes

| Method | Path | Screen | Reaches AI? | Writes DB? | Demo action | Evidence |
|---|---|---|---|---|---|---|
| POST | `/learn/ask` | Ask BrAInBox | sync (`ask-tutor`) | no | serve locally | learn/router.py:82, learn/service.py:289; tutor/data/tutor_repository.dart:57 |
| POST | `/learn/topics/{id}/notes/generate` | Topic notes, short notes | background (`GENERATE_NOTES` / `GENERATE_SHORT_NOTES`) | yes (ai_jobs, notes) | serve locally (202 + `demo-job-*`) | learn/router.py:172, learn/service.py:430; syllabus/data/api_learn_repository.dart:81 |
| GET | `/learn/jobs/{id}` | Notes generation, uploads | none | no | serve locally for `demo-` ids, else pass through | learn/router.py:194 |
| GET | `/learn/topics/{id}/notes?type=` | Topic notes, short notes | none | no | serve locally when this session generated a demo note for that topic and type, else pass through. Never stored in OfflineCache | learn/router.py:124; api_learn_repository.dart:55 |
| GET | `/learn/topics/{id}` | Topic screen | none | no | merge (`has_full_notes` / `has_short_notes` set after a demo note). Merged reply is not cached | learn/router.py:117 |
| POST | `/learn/uploads` | Upload sheet | background (`LEARN_UPLOAD_SUMMARY`) | yes (uploads, ai_jobs, file in storage) | serve locally. The file is not sent | learn/router.py:269, learn/service.py:846; api_learn_repository.dart:144 |
| GET | `/learn/uploads` | My uploads | none | no | merge (demo uploads first); demo list alone if the real list fails | learn/router.py:294 |
| GET | `/learn/uploads/{id}` | Upload detail | none | no | serve locally for `demo-` ids | learn/router.py:302 |
| POST | `/learn/uploads/{id}/save-to-short-notes` | Upload detail | none | yes (notes) | serve locally for `demo-` ids (the short note lives in memory) | learn/router.py:311 |
| DELETE | `/learn/uploads/{id}` | My uploads | none | yes | serve locally for `demo-` ids | learn/router.py:330 |
| POST | `/visuals/generate` | Generate a visual | background (`GENERATE_VISUAL`) | yes (visuals, ai_jobs) | serve locally (202). Non-Biology prompt: job fails with `NOT_BIOLOGY` | visuals/router.py:50, visuals/service.py:211; visuals/data/visuals_repository.dart:55 |
| GET | `/jobs/{id}` | Visuals, model paper, evaluation, OCR (JobPoller) | none | no | serve locally for `demo-` ids | jobs/router.py:28; brainbox_core/lib/api/job_poller.dart |
| GET | `/visuals/{id}` | Diagram viewer, My visuals | none | no | serve locally for `demo-` ids | visuals/router.py:72 |
| POST | `/visuals/{id}/report` | Diagram viewer | none | yes | serve locally for `demo-` ids | visuals/router.py:81 |
| GET | `/topics/{id}/visuals` | Topic diagrams gallery | none | no | merge (demo visuals for that topic first); demo-only fallback | visuals/router.py:36 |
| POST | `/papers/generate` | Generate paper | background (`BUILD_PAPER`) | yes (ai_jobs, papers, questions) | serve locally: questions from seed, by unit and count | exams/router.py:65, exams/service.py:788; exams/data/exams_repository.dart:44 |
| GET | `/papers/{id}` | Exam attempt | none | no | serve locally for `demo-` ids | exams/router.py:105 |
| POST | `/papers/{demo-id}/submit` | Exam attempt, results | sync (`explain-mcq`) + background (`EVALUATE_ANSWER` per written answer) | yes | serve locally: MCQs from the answer key, written answers by seed rubric, `status: graded` | exams/router.py:119, exams/service.py:408, :451, :555 |
| POST | `/papers/{real-id}/submit` | Past paper attempt | sync + background (as above) | yes (attempts, responses, mastery) | **rewrite**: `explain: false`, written `answer_text: null`. MCQs are still marked and stored by the backend. See tradeoff 2 | exams/service.py:407-408, :451 |
| GET | `/evaluations/questions` | Written questions list | none | no | merge (3 viva questions `demo-viva-*` first); demo-only fallback | evaluation/router.py:42 |
| GET | `/questions/{id}` | Typed / handwritten answer header | none | no | serve locally for `demo-` ids | questions/router.py:45; evaluation_repository.dart:41 |
| POST | `/evaluations` | Typed answer, OCR check | background (`EVALUATE_ANSWER`) | yes (evaluations, ai_jobs) | serve locally: keyword and concept coverage against the seed rubric. A real question is matched to the closest saved rubric by its text (read from the non-AI `GET /questions/{id}`) and the feedback says "Showing the closest saved example." | evaluation/router.py:105, evaluation/service.py:297 |
| GET | `/evaluations/{id}` | Evaluation feedback | none | no | serve locally for `demo-` ids | evaluation/router.py:136 |
| POST | `/evaluations/pages` | Handwritten upload | none (stores files) | yes (storage) | serve locally (photos are not sent) | evaluation/router.py:71 |
| POST | `/evaluations/ocr` | Handwritten upload | background (`OCR_ANSWER`) | yes | serve locally: always the prepared sample text (`assets/demo/viva.json` → `ocr`). Does not read the photo | evaluation/router.py:86, evaluation/service.py:252 |
| POST | `/posts/suggest-topic` | Create post | sync (`tag-post`) | no | serve locally: topic matched from the seed, real topic id read from the non-AI `GET /learn/topics/{code}` | community/router.py:121, community/service.py:625; community_repository.dart:83 |

## Routes that reach AI but are passed through (tradeoffs)

These do real, non-AI work (score, mastery, posts) that the demo cannot copy without
changing the backend. The AI part has a template fallback on the backend.

| Method | Path | Screen | Reaches AI? | Writes DB? | Demo action | Evidence |
|---|---|---|---|---|---|---|
| POST | `/diagnostic/{id}/submit` | Diagnostic | sync (`diagnostic-summary`), template fallback on error | yes (attempt, mastery, achievements) | pass through | quizzes/router.py:86, quizzes/service.py:306, :336 |
| GET | `/home/summary` | Home | sync (`next-action`) when the diagnostic is done, template fallback | no | pass through | home/router.py:24, home/service.py:120, :157 |
| GET | `/recommendations` | Next steps | sync (`rank-resources`) only when YouTube returns videos (needs `YOUTUBE_API_KEY`); never raises | yes (resources cache) | pass through | recommendations/router.py:42, recommendations/service.py:377, :431, :592 |
| GET | `/study-plan` | Study plan | same as above (calls `refresh`) | yes | pass through | recommendations/router.py:75, recommendations/service.py:778 |
| POST | `/groups/{id}/posts` | Create post | sync (`moderate`); background `SUGGEST_ANSWER` only if the post is a question **and** moderation approved it | yes (posts) | pass through | community/router.py:100, community/service.py:305, :314 |
| POST | `/posts/{id}/replies` | Post detail | sync (`moderate`) | yes (replies) | pass through | community/router.py:157, community/service.py:421 |

**Tradeoff 1 (sync AI with a fallback).** When the ai_service cannot be reached, the
backend's `AIClient` raises `ServiceUnavailableError` at once (connection refused) and each
of these routes uses its template or "held for review" path, with no AI rows. If the
ai_service is **up but Gemini is slow**, these routes can wait up to the backend AI timeout
(60 s, `api/core/ai_client.py:52`) while the app gives up at 30 s. Without a backend change
the frontend cannot stop these calls, so the runbook says to run the viva backend with the
AI service unreachable (`AI_SERVICE_URL` pointing at a closed port, set only in the shell
that starts the API). In that set-up community posts are saved as "pending" (only the
author sees them) because moderation is unavailable; that is the backend's normal
behaviour and starts no AI job.

**Tradeoff 2 (real past paper submit).** The MCQ marking of a real past paper is real data
(attempts, mastery, mistakes) and must stay on the backend, but the same request asks for
AI explanations and queues AI marking for written answers. Demo mode sends
`explain: false` and drops written `answer_text`, so the backend marks the MCQs only and
starts no AI work. Written answers on real past papers therefore score 0 in demo mode.
In the viva, show written marking with the generated model paper or the written questions
screen instead.

## Non-AI routes (pass through unchanged)

All with the normal Firebase token and the normal offline banner.

| Method | Path | Screen | Reaches AI? | Writes DB? | Demo action | Evidence |
|---|---|---|---|---|---|---|
| POST | `/auth/register` | Sign up | none | yes | pass through | auth/router.py:47 |
| GET/PATCH/DELETE | `/auth/me` | Session, settings, delete account | none | PATCH/DELETE yes | pass through | auth/router.py:62, :67, :83 |
| GET | `/auth/me/export` | Data export | none | no | pass through | auth/router.py:74 |
| POST | `/auth/email-code/send`, `/auth/email-code/verify` | Check inbox (email OTP) | none | yes | pass through | auth/router.py:96, :108 |
| POST | `/auth/password-reset/send`, `/verify`, `/complete` | Forgot password | none | yes | pass through | auth/router.py:120, :132, :141 |
| GET/PATCH/POST | `/profile`, `/profile/options`, `/profile/complete`, `/profile/details`, `/profile/avatar`, `/profile/overview`, `/achievements/{id}/seen` | Profile setup, profile | none | yes | pass through | profiles/router.py:48-120 |
| PATCH | `/home/plan/{id}` | Home | none | yes | pass through | home/router.py:29 |
| GET | `/learn/subjects`, `/learn/subjects/{id}/units`, `/learn/units/{id}` | Syllabus | none | no | pass through (cached offline as before) | learn/router.py:89, :95, :110 |
| GET | `/learn/topics/{id}/official-notes`, `/learn/official-notes/{doc}/pages/{n}` | Official notes | none | no | pass through | learn/router.py:137, :150 |
| GET | `/learn/topics/{id}/diagrams`, `/videos`, `/practice-summary` | Topic tabs | none | no | pass through | learn/router.py:202, :210, :216 |
| POST | `/learn/topics/{id}/progress` | Topic | none | yes | pass through | learn/router.py:228 |
| GET/POST/DELETE | `/learn/bookmarks`, `/learn/bookmarks/{id}` | Library | none | yes | pass through | learn/router.py:239-250 |
| GET | `/learn/search` | Syllabus search | none | no | pass through | learn/router.py:258 |
| POST/GET/POST | `/diagnostic/start`, `/diagnostic/{id}/answer`, `/diagnostic/skip`, `/diagnostic/result` | Diagnostic | none | yes | pass through | quizzes/router.py:55-86 |
| GET/POST | `/practice/hub`, `/units`, `/quizzes`, `/quizzes/{id}`, `/quizzes/{id}/responses`, `/flag`, `/submit`, `/result`, `/questions/{id}/report` | Practice | none (explanations come from stored data) | yes | pass through | quizzes/router.py:99-157, quality/router.py:22 |
| GET | `/papers` | Past papers | none | no | pass through | exams/router.py:50 |
| GET/PATCH | `/insights/*`, `/mistakes`, `/mistakes/recurring`, `/mistakes/{id}` | Insights, mistake journal | none | PATCH yes | pass through | performance/router.py:44-152 |
| PATCH/POST/PUT | `/recommendations/{id}`, `/recommendations/{id}/outcome`, `/study-plan/regenerate`, `/study-plan/items/{id}`, `/study-plan/order` | Next steps, study plan | none | yes | pass through | recommendations/router.py:49-97 |
| GET/POST/DELETE | `/groups`, `/groups/{id}`, `/groups/{id}/join`, `/groups/{id}/posts` (GET), `/posts/{id}`, `/replies/{id}`, `/posts/{id}/accept/...`, `/votes`, `/posts/{id}/report`, `/replies/{id}/report`, `/units/u{n}/topics` | Community | none | yes | pass through | community/router.py:58-237, syllabus/router.py:35 |
| GET/PATCH/POST | `/notifications`, `/notifications/{id}`, `/notifications/read-all` | Notifications | none | yes | pass through | notifications/router.py:29-48 |
| GET/PATCH | `/settings`, `/privacy` | Settings | none | yes | pass through | profiles/router.py:109-120 |

Kroki: demo visuals carry `image_url: asset://demo/visuals/*.png` and no `mermaid_code`, so
`DiagramRenderer.imageUrlOf` never builds a Kroki URL and `VisualImage` loads the bundled
asset (`visuals/presentation/widgets/visual_widgets.dart`). Real visuals with only Mermaid
code still use Kroki, as before.

## Not covered: admin portal AI routes

Admin AI is out of scope. These admin routes start AI work and are **not** changed by demo
mode (the admin app does not use the demo layer):

| Method | Path | AI work | Evidence |
|---|---|---|---|
| POST | `/admin/rag/sources` | `RAG_INGEST` (chunk + embed) | admin/rag_admin.py:34 |
| POST | `/admin/rag/reindex` | `RAG_INGEST` | admin/rag_admin.py:70 |
| POST | `/admin/questions/past-papers` | `EXTRACT_PAST_PAPER` (OCR + split) | admin/questions_admin.py:168, questions/service.py:606 |
| POST | `/admin/questions/{id}/review` | question review | admin/questions_admin.py:110 |
| POST | `/admin/questions/{id}/misconception-suggestions` | `MAP_MISCONCEPTIONS` | admin/questions_admin.py:127, questions/service.py:774 |
| POST | `/uploads/text`, `/uploads/pdf` (content module) | `SUMMARIZE_UPLOAD` | content/router.py:35, :56, content/service.py:142 |
| POST | `/questions/{id}/explain` | sync `explain-mcq` (not called by the student app) | questions/router.py:60, questions/service.py:184 |
