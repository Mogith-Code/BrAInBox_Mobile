# Contributing to BrAInBox (frontend)

## Branches

| Branch | Purpose |
|---|---|
| `main` | Released, demo-ready code. Only `develop` is merged into it. |
| `develop` | Integration branch. All feature work is merged here first. |
| `feature/<module>` | Long-running branch for one module, e.g. `feature/practice`. Admin modules use `feature/admin-<module>`. |
| `feature/<module>/BRN-xx-short-name` | One Jira ticket, e.g. `feature/practice/BRN-31-mcq-screen`. |

Flow:

```
feature/practice/BRN-31-mcq-screen  ->  feature/practice  ->  develop  ->  main
```

- Branch from `develop` (or from your `feature/<module>` branch).
- **Merge `develop` into your branch at least twice a week** so conflicts stay small:
  ```bash
  git checkout feature/practice
  git fetch origin
  git merge origin/develop
  ```
- Never push directly to `main` or `develop`.

## Commit messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <what changed> BRN-xx
```

Examples:

```
feat(auth): add login screen BRN-12
fix(practice): stop timer when the quiz ends BRN-40
refactor(core): move MasteryRing colors into AppColors BRN-55
test(insights): add heatmap controller tests BRN-61
docs(readme): explain flutterfire configure
chore: create project folder structure
```

| Type | Use for |
|---|---|
| `feat` | A new feature or screen |
| `fix` | A bug fix |
| `refactor` | Code change that is not a fix or a feature |
| `test` | Adding or fixing tests |
| `docs` | Documentation only |
| `style` | Formatting only |
| `chore` | Tooling, CI, dependencies |

The scope is the feature folder (`auth`, `practice`, `admin-users`...) or
`core` / `app` / `ci`.

## Pull requests

1. Run these before opening a PR:
   ```bash
   melos run gen
   melos run format
   melos run analyze   # must show no issues
   melos run test
   ```
2. Open the PR into `feature/<module>` or `develop` and fill in the template.
3. **One reviewer approves every PR.** CODEOWNERS adds the owner of the
   folders you touched automatically.
4. CI must be green before merging.
5. Use **Squash and merge** for ticket branches, so each ticket becomes one
   commit with a Conventional Commit title.

## Definition of Done

A ticket is done when:

- [ ] It does what the Jira ticket asks, and the UI matches the Figma design.
- [ ] It follows the layering rule: screen → controller → repository → `ApiClient`.
- [ ] It handles the loading, error and empty states.
- [ ] AI-generated content shows the `AiBadge`.
- [ ] It uses theme tokens and `brainbox_core` widgets (no hard-coded colors or sizes).
- [ ] New logic has tests: a controller or repository unit test, plus a widget test for each new screen.
- [ ] `melos run analyze` shows no issues and `melos run test` passes.
- [ ] Code is formatted (`melos run format`).
- [ ] No secrets or Firebase config files are committed.
- [ ] The feature's `README.md` is updated (screens, endpoints).
- [ ] The PR is approved by one reviewer and merged into `develop`.
- [ ] The Jira ticket is moved to *Done*, with the PR linked.

## Code style

- Keep code simple and commented. Others will maintain it.
- Use `// TODO(<handle>): ...` for unfinished work, with your own handle.
- Put new reusable widgets in `packages/brainbox_core/lib/widgets/` (ask Samni first).
- Put widgets used by only one feature in `<feature>/presentation/widgets/`.
