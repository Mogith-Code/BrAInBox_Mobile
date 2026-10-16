## What changed

<!-- One or two sentences. What does this PR do and why? -->

## Jira ticket

BRN-xx <!-- e.g. BRN-12 -->

## Screenshots

<!-- Required for UI changes. Before / after, phone size (or desktop for admin). -->

| Before | After |
|---|---|
|  |  |

## How to test

<!-- Steps a reviewer can follow. Which route? Which test account / data? -->

1.
2.

## Checklist

- [ ] Tests added or updated, and `melos run test` passes
- [ ] `melos run analyze` shows no issues
- [ ] `melos run format` was run
- [ ] UI matches the Figma design
- [ ] AI-generated content shows the `AiBadge`
- [ ] Screens only talk to controllers (no Dio / Firebase in `presentation/`)
- [ ] No secrets, `google-services.json` or `firebase_options.dart` committed
- [ ] Branch is up to date with `develop`
