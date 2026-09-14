# Releasing

## Branches

| Branch | Channel | App on the phone | Published as |
| --- | --- | --- | --- |
| `main` | stable | HeliBoard | release, tagged `v<upstream>.<fork>` |
| `dev` | beta | HeliBoard Beta | workflow artifact, named `v<upstream>.<fork>-beta.<run>` |
| `feature/*`, `fix/*`, `ci/*` | none | - | nothing, CI on their pull request |

The beta build carries the `.beta` application ID suffix, its own name and
its own content provider authorities, so it installs next to the stable
build instead of replacing it.

Because it is a separate application it is also a separate **input
method**: after installing a beta, enable and select *HeliBoard Beta* in
the system keyboard settings. It starts empty, sharing neither the
settings nor the learned words of the stable build. Use **Settings >
Backup and restore** to carry a setup across.

## Workflows

`ci.yml` runs `lintDebug`, builds the debug APK and checks that the beta
variant's resources merge, on every pull request. Pushes are not built, so
a branch is verified once, when it is proposed for merge.

Unit tests stay with upstream's `build-test-auto.yml`, which runs them on
pull requests touching `app/src/main/java`.

`release.yml` builds a signed APK.

On `main` it publishes it as a GitHub release, only if the composed
version (see [Versioning](#versioning)) has no tag yet, so ordinary
commits never create a release.

On `dev` it builds every push, appending `-beta.<run>` to the same
version, and attaches the APK to the workflow run instead of making a
release. No tag, no release, nothing for Obtainium to see.

## Versioning

`app/build.gradle.kts` keeps upstream's `versionCode` and `versionName`
untouched, so merging upstream never conflicts on them. The fork's own
revision lives in [`fork-version`](../fork-version), a file upstream will
never have, and the workflow composes the published version from both:

    upstream 4.1 (code 4101) + fork-version 1  ->  4.1.1, code 4101001

So a release of this repository is always visibly distinct from the
upstream release it is built from, and it is clear which upstream version
it carries.

The composed values reach Gradle as `ANDROID_VERSION_CODE` and
`ANDROID_VERSION_NAME`, which `app/build.gradle.kts` honours as
overrides. A build without them produces upstream's own version, so
nothing changes for a local build.

Bump `fork-version` to publish a stable release without an upstream
version change. After merging an upstream release there is nothing to do:
its higher `versionCode` already raises the composed one, so `4.2.1`
follows `4.1.1` on its own.

Keep `fork-version` below 1000, which is the room the composed
`versionCode` leaves for it.

Betas append `-beta.<run>`, the workflow run number, and use it alone as
their `versionCode`, since the beta is a separate app with its own
ladder.

A beta names the version it leads *to*, not the one it was built from. It
sits ahead of stable, so if the composed version is already released the
workflow takes the next fork revision: with `4.1.1` out, betas are
`4.1.2-beta.<n>`. Their notes list everything that differs from the last
stable release rather than only what changed since the previous beta, so
any single beta describes itself in full.

## Notes

Release notes list only what this fork adds. They come from
`git log HEAD ^upstream/main`, so merging an upstream release never
floods them with upstream's own commits.

Stable releases carry that one list, which grows with every change and
always states the complete difference from the original.

Betas carry it too, above a second list of what the beta has that the
current release does not. A beta's notes are shown on its workflow run's
summary page and packed into its artifact as `release-notes.md`.

Notes are built from commit subjects, so a commit subject is user-facing
text.

## Drafts

Stable releases publish as **drafts**. The workflow builds, signs and
uploads, then stops. Nothing is live until you press Publish in the
release editor, and Obtainium never sees a draft.

Notes are pre-filled and meant to be edited. Stable releases are never
pruned.

## Betas

Every push to `dev` leaves one beta on its workflow run, under
**Actions > Release > the run > Artifacts**, as a zip with the APK, its
SHA-256 and the notes. Artifacts expire after the repository's retention
period, 90 days unless changed under **Settings > Actions > General**.

Betas are signed with the same key as stable releases, so each one
installs as an update over the previous beta.

## Setup

Every release has to be signed with the same key or Android refuses to
install the update.

```sh
sh tools/create-keystore.sh
```

Keep `release.jks` and its password backed up, and do not commit them
(`.gitignore` covers `*.jks` and `*.keystore`). Then add these under
**Settings > Secrets and variables > Actions**:

| Secret | Value |
| --- | --- |
| `KEYSTORE_BASE64` | the base64 line printed by the script |
| `KEYSTORE_PASSWORD` | the keystore password |
| `KEY_ALIAS` | `heliboard`, unless you changed `ALIAS` |
| `KEY_PASSWORD` | the key password |

The release workflow fails before building if any are missing.

## Publishing

A beta: push to `dev`, then download it from the run.

A stable version:

1. Bump `fork-version`, unless this carries a new upstream release.
2. Merge `dev` into `main`.

To rebuild an existing release, run the workflow from the **Actions** tab
with **force** enabled.

## Installing

Add the repository URL in [Obtainium](https://github.com/ImranR98/Obtainium)
for the stable build. Betas are not releases, so they are installed by
hand from the downloaded artifact.

Each release and each beta lists its signing certificate SHA-256, which
Obtainium can pin.

The stable build keeps upstream's application ID but is signed with a
different key, so it will not install over a copy from F-Droid or
IzzyOnDroid; uninstall that one first, after taking a backup. The beta
build has its own application ID and is unaffected.
