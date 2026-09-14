# Releasing

## Branches

| Branch | Channel | App on the phone | Published as |
| --- | --- | --- | --- |
| `main` | stable | HeliBoard | release, tagged `v<upstream>.<fork>` |
| `dev` | beta | HeliBoard Beta | pre-release, tagged `v<upstream>.<fork>-beta.<build>` |
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

`release.yml` builds a signed APK and publishes it as a GitHub release.

On `main` it publishes only if the composed version (see
[Versioning](#versioning)) has no tag yet, so ordinary commits never
create a release.

On `dev` it publishes every push, appending `-beta.<n>` to the same
version.

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

Betas append `-beta.<n>`, and use the workflow run number alone as their
`versionCode`, since the beta is a separate app with its own ladder.

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
current release does not.

Notes are built from commit subjects, so a commit subject is user-facing
text.

## Drafts

Both channels publish as **drafts**. The workflow builds, signs and
uploads, then stops. Nothing is live until you press Publish in the
release editor, and Obtainium never sees a draft.

A beta draft is tagged `v<version>-beta.<n>`, where `n` steps past the
beta tags already taken for that version. An unpublished draft has no
tag, so `n` does not move and every push to `dev` updates that one draft
rather than leaving a release behind per feature: the APK is replaced,
the notes are regenerated, and the release collects the whole set of
changes until you publish it. Publishing takes the tag, so the next push
starts a fresh draft at the next number.

Notes are pre-filled and meant to be edited. Edit them last, once the
features are in, because the next push regenerates the body and
overwrites what you wrote. A draft is never pruned, only published
pre-releases are, keeping the number set by `KEEP` in the workflow.
Stable releases are never pruned.

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

A beta: push to `dev`.

A stable version:

1. Bump `fork-version`, unless this carries a new upstream release.
2. Merge `dev` into `main`.

To rebuild an existing release, run the workflow from the **Actions** tab
with **force** enabled.

## Installing

Add the repository URL in [Obtainium](https://github.com/ImranR98/Obtainium).
For the beta, add the same URL again with **Include prereleases** on and
**Filter APKs by regular expression** set to `Beta`; Obtainium keys apps
by package name, so both entries coexist.

Each release lists its signing certificate SHA-256, which Obtainium can
pin.

The stable build keeps upstream's application ID but is signed with a
different key, so it will not install over a copy from F-Droid or
IzzyOnDroid; uninstall that one first, after taking a backup. The beta
build has its own application ID and is unaffected.
