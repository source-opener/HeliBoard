# Working in this repository

This file is guidance for Claude Code sessions. It is not part of the app.

**It lives only on `feature/ai-dev`.** A session loads `CLAUDE.md` from the
branch it checks out, so start the session with `feature/ai-dev` as its
source or none of this applies. Once loaded it stays in context for the
whole session, including after you switch branches to work.

**Never merge this file into `dev` or `main`.** If you branched work off
`feature/ai-dev`, delete `CLAUDE.md` in your first commit on that branch.

## What this is

A fork of [HeliBoard](https://github.com/HeliBorg/HeliBoard), an Android
keyboard. Upstream keeps releasing; this fork adds its own features on top
and publishes its own signed builds. Read `docs/RELEASING.md` for the full
release setup.

Upstream asks that AI generated contributions are not sent to it, see
`AI_USAGE.md`. Nothing from here is proposed upstream.

## Branches

| Branch | Role |
| --- | --- |
| `main` | stable channel, and the default branch here and upstream |
| `dev` | beta channel, features land here first |
| `feature/*`, `fix/*`, `ci/*` | work branches, one merge request each |

Work goes to a branch, then a merge request into `dev`. `dev` merges into
`main` for a stable release.

## Releases

Both channels publish as **drafts**. Nothing is live until a human presses
Publish. Do not change that.

Versions are composed in CI from upstream's untouched `versionCode` and
`versionName` plus `fork-version`, so pulling upstream never conflicts on
those lines. Leave upstream's values alone. A stable release without an
upstream version change needs `fork-version` bumped first, or the workflow
finds the existing tag and silently publishes nothing.

Release notes are built from **commit subjects**, so a commit subject is
user-facing text. Write it as a line someone would want to read in a
release.

## Working style

- Commit messages: a few words, imperative.
- No AI or assistant attribution anywhere: not in commits, branch names,
  merge request bodies, code, or comments. The README section about the
  fork is the one place it is stated, deliberately.
- Comments only where the code cannot say it itself. No comment restating
  the next line. Keep diffs minimal.
- Open merge requests. Never merge them. Never enable auto-merge.
- If a branch collects commits that cancel out, squash before it merges, or
  both subjects appear in a release describing work that no longer exists.
- State in every merge request what you actually verified and what you did
  not.

## This project specifically

- **Build files are Kotlin DSL** (`build.gradle.kts`). Snippets written for
  Groovy build files, including any `sed` reading `versionCode` or
  `versionName`, match nothing here. Run them against the real file.
- **The default branch is `main`**, here and upstream. Anything copied from
  a project that uses `master` needs every occurrence changed, including
  the refs a workflow fetches.
- **`.github/workflows/build-test-auto.yml` is upstream's.** Its
  `paths: app/src/main/java**` filter and the `runTests` build type, which
  skips tests known to fail, are deliberate. Do not widen the filter, do
  not delete the workflow, do not touch the tests. If a change would fail
  because of an existing test, say so and stop.
- **Translations go through Weblate** (`translate.codeberg.org`, see
  `tools/release.py`), so add English strings only, never a translated
  copy. `app/lint.xml` makes `MissingTranslation` informational because of
  that; `android.lint.abortOnError` is true, so anything else lint reports
  fails CI.
- **A new variant needs its own content provider authorities.** The app
  registers providers through `@string/clipboard_provider_authority` and
  `@string/gesture_data_provider_authority`; a duplicate authority makes
  Android refuse the install with `INSTALL_FAILED_CONFLICTING_PROVIDER`.
  `app/src/debug` and `app/src/beta` show the pattern.
- **`.gitignore` ignores `*.sh`**, negated by `!tools/*.sh`. Check with
  `git check-ignore -v` before assuming a new script was committed.
- Settings backup and restore already exists (**Settings > Backup and
  restore**). Do not add one.

## Verification

This is where it goes wrong. Most of these are mistakes already made here.

- When editing files programmatically, **assert that every intended change
  matched**. A replacement that silently matches nothing leaves the file
  stale while the script reports success.
- Do not assume a helper exists. Grep for it.
- Do not assume an API is available: check it against `minSdk`, which is 21.
- Execute logic rather than reasoning about it: run the string transform on
  real input, run the shell snippet against real history, extract a
  workflow step from the YAML and run it.
- **Never edit or disable a test to make CI pass.** If a test fails,
  either the change is wrong or the test does not belong in that pipeline.
  Say which.
- When adapting existing CI, keep its triggers. Upstream may run a job only
  for certain paths on purpose; widening that inherits failures that were
  never meant to gate the change.
- **Gradle cannot run in the Claude Code sandbox.** There is no Android
  SDK, and `dl.google.com` and `services.gradle.org` are blocked by the
  network policy, so nothing downloads. Anything about the build itself is
  unverified until CI runs it. Say so plainly rather than implying
  otherwise.

## Ask before

- Anything that deletes or rewrites published history, releases or tags.
- Generating a signing key. It is the app's permanent identity and must
  only exist on the user's machine. Give the commands; never run them or
  ask for the key.
- Widening scope beyond what was asked.
