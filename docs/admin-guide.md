# BrAInBox – admin portal guide

The admin portal is a website where teachers and content staff manage what
students see in the BrAInBox app: the syllabus, notes, questions, past papers,
marking keys and the community. It is also where you **review everything the
AI produces** before students rely on it.

Open it in Chrome or Edge on a computer (screens 1280 px wide or more work
best). The address is in `handover.md`.

---

## Contents

1. [Signing in](#1-signing-in)
2. [Finding your way around](#2-finding-your-way-around)
3. [Every page and what it is for](#3-every-page-and-what-it-is-for)
4. [How to add content](#4-how-to-add-content)
5. [How to review AI content](#5-how-to-review-ai-content)
6. [How to manage users and the community](#6-how-to-manage-users-and-the-community)
7. [Content statuses](#7-content-statuses)
8. [Good practice](#8-good-practice)

---

## 1. Signing in

1. Open the admin portal address and enter your **email** and **password**,
   then **Sign in to console**. Tick **Keep me signed in** on your own
   computer only.
2. Only accounts with the **admin** role get in. Anyone else sees a
   "not an admin" page.
3. **Forgot password?** sends a reset code to your email.

**Getting admin access.** The role is given on the server by the person who
runs the backend (`python scripts/make_admin.py name@school.lk`). The person
must have signed in once (in the app or the portal) first, then sign out and
in again after the role is given. See `handover.md` → *Accounts*.

## 2. Finding your way around

- The **sidebar** on the left lists every page. On a narrow window it
  collapses to icons; hover an icon to see its name.
- Each page has **loading**, **empty** ("Nothing here yet") and **error**
  states. If a page says *"The backend for this page is not built yet"*, that
  part of the server is not available in this version (see `handover.md` →
  *Known limitations*).
- Anything produced by AI carries an **AI** badge.
- **Log out** is at the bottom of the sidebar.

## 3. Every page and what it is for

| Page | What it is for | Typical tasks |
|---|---|---|
| **Dashboard** | A daily overview: key numbers (active students, AI items to review, evaluation accuracy), activity over the last 14 days, most-missed topics this week, recent reports | Spot what needs attention; **Open queue →** jumps to a review queue |
| **Syllabus manager** | The curriculum tree **Unit → Topic → Concept** for Biological Science · Biology. Everything else (questions, notes, insights) hangs off this tree | Add or rename units, topics and concepts; **Flag as outdated** for content no longer in the syllabus |
| **Content review** | The **content library** of AI notes, short notes and images, filtered by unit and status | **Approve**, **Edit**, **Reject** with a reviewer note; **Generate** new notes for a topic |
| **Question bank** | Every MCQ, structured and essay question, with filters for unit, type, difficulty and status | **New question**, edit, **Publish** or **Save draft**, delete several at once |
| **MCQ mapping** | For each MCQ, the **misconception** behind each wrong option. This is what lets the app tell a student *why* they were wrong | Accept or dismiss **AI misconception suggestions**, write your own, **Preview as student** |
| **Quality review** | A queue of automatic checks on AI-generated questions, marked **Pass**, **Review** or **Fail** | **Approve**, **Edit**, **Reject**; **Approve all passing** |
| **Past papers** | Real A/L papers and their marking schemes. The AI extracts the questions | Upload a paper, **+ Link scheme**, check each extracted question and its model answer and keywords, **Save & next question**, mark *Outdated syllabus* |
| **Knowledge base** | **Model answers** and **marking points** (with keywords and marks) for structured and essay questions. The AI marks students' written answers against these | **Add model answer**, **Add point**, **Edit keywords**, **Save draft** / **Save and approve**; choose whether *Students can practise* it |
| **RAG sources** | The approved documents the AI is allowed to use when it writes notes and answers (syllabus, teacher guides, approved notes). Each shows its ingestion status | **Upload source**, filter by unit, **Re-index all** after big changes |
| **Moderation** | Community posts and visuals reported by students or flagged by the AI; the list of **study groups** | **Keep**, **Warn** or **Remove**; **New group**, set a moderator |
| **Users** | The list of students: school, district, exam year, average mastery, status, last active. Search by name or email, filter, page through, export | **View profile**, **Suspend** / unsuspend a student |
| **Analytics** | Average mastery by unit, common misconceptions, AI feature usage, daily active students, and **evaluation accuracy** (AI marks vs teacher marks) | Enter **teacher marks** for sample answers to measure how well the AI marks |

## 4. How to add content

Content always flows in this order, because each step depends on the one before:

```
Syllabus  →  RAG sources  →  Notes (Content review)  →  Questions  →  MCQ mapping
                                                     →  Past papers  →  Knowledge base
```

### 4.1 Syllabus

1. **Syllabus manager** → pick a node in the **Curriculum tree**.
2. **Add unit / topic / concept**, type the name, **Add**.
3. To change a node, select it and edit it in **Edit node**, then **Save changes**.
4. Don't delete a topic that has questions or notes; **Flag as outdated** instead.
   Students then see those items marked *Outdated syllabus*.

### 4.2 Source documents for the AI (RAG sources)

1. **RAG sources** → **Upload source**.
2. Give a **Title**, the **Type** (syllabus, teacher guide, approved note…), and
   optionally the **Unit** and **Year**. Choose the PDF and **Upload**.
3. Wait until its status shows it has been ingested. Only then can the AI use it.
4. After uploading or replacing many documents, use **Re-index all**.

Only upload material you have the right to use and that you trust: the AI
treats it as correct.

### 4.3 Questions

**One at a time:** **Question bank** → **New question** → choose type, unit and
difficulty → write the stem, the options (mark the correct one), the
explanation shown after answering, and a misconception for each wrong option
→ **Preview as student** → **Publish** (or **Save draft**).

**Many at once:** the **Import CSV** button is not available in this version.
Bulk questions are loaded on the server with
`python scripts/seed_customer.py --only question-bank`, from
`data/questions/question_bank.json` (format in `data/questions/README.md` of
the backend). Ask whoever runs the backend.

### 4.4 Past papers and marking schemes

1. **Past papers** → choose the **Year** and **Paper type** → upload the paper.
2. **+ Link scheme** to attach its marking scheme.
3. **Open** the paper and go through each extracted question: check the text,
   marks, **Model answer** and keywords (**+ add keyword**). Use
   **Save & next question**, or **Skip**.
4. Mark questions that are no longer in the syllabus as **Outdated syllabus**.

Large sets of papers can also be loaded on the server
(`seed_customer.py --only past-papers`).

### 4.5 Model answers for written questions (Knowledge base)

1. **Knowledge base** → **Add model answer**.
2. Enter the question, the full **Model answer** and the **Source**.
3. Split the answer into **marking points** (**Add point**); give each its
   **Marks** and **Keywords** (comma separated). These are what the AI looks
   for in a student's answer.
4. **Save draft** while working; **Save and approve** when it is final. Turn on
   **Students can practise** to show the question in the app.

## 5. How to review AI content

Students only see AI content that is **approved**. Work through these queues
regularly (the Dashboard shows how many items are waiting).

### Notes, short notes and images – *Content review*

1. Filter by **Unit** and **Status** = pending review.
2. Open an item and read it against the syllabus.
3. Either **Approve**, **Edit** (fix it, then **Save**), or **Reject** with a
   **Reviewer note** saying why. Rejected items are not shown to students.

### AI-generated questions – *Quality review*

1. Each question has automatic checks: **Pass**, **Review** or **Fail**.
2. Look at every **Review** and **Fail** item: **Edit** and approve it, or
   **Reject** it.
3. When you trust the **Pass** items, **Approve all passing** clears them in
   one step.

### Misconceptions – *MCQ mapping*

1. **Pick an MCQ**. Under **AI suggestions · check each one**, read the
   suggested misconception for each wrong option.
2. **Accept**, **Dismiss**, or type your own (**New misconception**), then
   **Save**.
3. **Preview as student** to see exactly what the student will read.

### AI marking – *Analytics → Evaluation accuracy*

Enter teacher marks for a sample of students' written answers. The page
compares them with the AI's marks (average gap, share within 1 mark,
correlation). If the AI marks badly for a question, improve its marking points
in the **Knowledge base**.

## 6. How to manage users and the community

### Students – *Users*

- Search by **name or email**, filter by **District**, **Exam year** or
  **Status**.
- **View profile** shows a student's details and progress.
- **Suspend** stops a student from using the app (for example after repeated
  abuse in the community). You are asked to confirm. Suspend again to undo it.
- Admin rights are not given here; see section 1.
- Deleting an account is done by the student in the app
  (*Settings → Data & privacy → Delete my account*).

### Community – *Moderation*

- Reports from students and items the AI flags land in one list, with the
  number of reports and the AI's reason.
- **Keep** closes the report and leaves the post. **Warn** keeps it and
  warns the author. **Remove** takes the post down.
- **Study groups**: **New group** creates a group (for example
  "Unit 7 · Molecular"); give each group a moderator.

## 7. Content statuses

| Status | Meaning | Students see it? |
|---|---|---|
| Draft | Being written, not finished | No |
| Pending review | Made by AI or submitted, waiting for an admin | No |
| Approved / Published | Checked and live | **Yes** |
| Rejected | Not suitable; kept for the record with a reviewer note | No |
| Outdated syllabus | No longer in the current syllabus | Yes, with a warning (students can hide it) |

## 8. Good practice

- Review the queues at least **twice a week**, more often near exams.
- Always leave a **reviewer note** when you reject something, so the next
  reviewer knows why.
- Change the syllabus tree carefully: renaming a topic changes it everywhere.
- Never share your admin password; each admin should have their own account.
- Sign out on shared computers.
