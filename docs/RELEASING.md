# Releasing this fork

Two channels, both built and signed by GitHub Actions, both published as drafts
that a human presses Publish on.

| Branch | Channel | Workflow | Release |
| --- | --- | --- | --- |
| `main` | stable | `.github/workflows/release.yml` | draft, normal release |
| `dev` | beta | same | draft, pre-release |

Work happens on `feature/*`, `fix/*` or `ci/*` branches, one pull request each,
merged into `dev`. Merging `dev` into `main` ships a stable release.

`.github/workflows/ci.yml` runs on pull requests and on manual dispatch, never on
push - the pull request already builds those commits. It lints, runs the tests,
builds the debug APK and merges the beta variant's resources.

## Publishing

Every push to `main` or `dev` builds, signs and uploads into a **draft** release.
Nothing is public and no tag exists until you press Publish, so nothing can reach
a phone unapproved.

Because a draft has no tag, every push to `dev` keeps updating the *same* draft:
the APK is replaced, the notes are regenerated, and one draft collects the whole
feature set. Publishing claims the tag, and the next push starts a fresh draft
with the next beta number.

**Edit the release notes last.** The notes are generated from commit subjects and
include infrastructure commits nobody wants to read, so trimming them before
publishing is expected - but a further push to the branch regenerates the body
and overwrites whatever you wrote. Edit, then publish, in that order.

After you publish, the next run deletes published pre-releases older than the
newest `KEEP_PRERELEASES` (3, set in `release.yml`). Stable releases are never
pruned, the open draft is never touched, and the tags are kept so beta numbering
never walks backwards.

## Versions

Upstream's `versionCode` and `versionName` stay in `app/build.gradle.kts` exactly
as upstream writes them, so pulling upstream never conflicts on those lines. The
fork's own revision lives in `fork-version`, a file upstream will never have, and
the workflow composes the published version from the two:

    upstream 4.1 (code 4101) + fork-version 1  ->  4.1.1, code 4101001

The upstream code is multiplied by 1000 to leave room for the fork revision, so
the composed code stays monotonic when upstream bumps: upstream 4.2 gives
4102001, above 4101999. Keep `fork-version` below 1000; `tools/compose-version.sh`
fails the build if it is not.

The composed values reach the build through the `FORK_VERSION_NAME` and
`FORK_VERSION_CODE` environment variables, which `app/build.gradle.kts` honours as
overrides. A local build sets neither and produces upstream's own version.

**After merging an upstream release, do nothing** - the upstream version changed,
so the composed version is new. Raise `fork-version` only to ship a stable release
when the upstream version did *not* change. The workflow fails with that message
if you push to `main` while the composed version is already released.

A beta names the version it leads **to**, not the one it was built from, because
`-beta` sorts before the version it names. With 4.1.1 released, betas are
`4.1.2-beta.1`, `4.1.2-beta.2` and so on, and publishing 4.1.2 moves the betas on
to 4.1.3.

## Release notes

Both channels list everything this fork adds on top of upstream, taken from
`git log HEAD ^upstream/main`, so upstream's own commits never appear and merging
an upstream release does not flood the notes with dozens of theirs. That list
grows with every change, so each release states the complete difference from the
original rather than only what moved since the last one.

A beta carries that same list plus a second one, `origin/main..HEAD`, holding what
the beta has that the current stable release does not.

Commit subjects are therefore user-facing text. Write them as lines someone would
want to read in a release.

## Signing

One key signs both channels. Generate it on your own machine:

    tools/generate-keystore.sh

It writes `~/heliboard-release-key.jks` and prints four values. Set each under
**Settings -> Secrets and variables -> Actions -> New repository secret**:

    KEYSTORE_BASE64
    KEYSTORE_PASSWORD
    KEY_ALIAS
    KEY_PASSWORD

Back the keystore up somewhere private. It is the app's permanent identity: lose
it and every user has to uninstall and reinstall to move to a replacement, and
anyone who gets a copy can ship an update that installs over yours. It must never
be committed - `.gitignore` covers `*.jks` and `*.keystore` as a safety net.

The workflow checks all four secrets exist and fails before building if any is
missing, and verifies the finished APK's signature with `apksigner`, so nothing
can publish unsigned.

`KEYSTORE_PASSWORD` and `KEY_PASSWORD` hold the same value: a PKCS12 keystore
cannot hold a key password different from the store password.

**A build signed with this key will not install over a copy from Google Play or
F-Droid.** Same applicationId, different signature - Android refuses the update.
Uninstalling first is the only way across, and that loses the app's data.

## The beta is a separate app

The beta build type carries a `.beta` applicationId suffix, its own app name
("HeliBoard Beta"), its own content provider authorities and a teal-green launcher
icon instead of the crimson-indigo one, so it installs **alongside** stable rather
than replacing it. Trying a beta never risks the stable install or its data.

Being a separate application has a consequence specific to a keyboard:

- **The beta is a separate input method.** You have to enable it and then select
  it in the system input settings before it does anything. Installing it is not
  enough.
- **It does not inherit the stable build's settings or learned dictionary.** It
  starts empty. Its settings, custom layouts, colours and learned words are its
  own, and stay its own.

The launcher icon differs on Android 8 and newer, which use the adaptive icon.
Below that the older bitmap icon is shared, so only the app name distinguishes
them.

## Obtainium

Obtainium keys apps by package name, not by URL, so the **same repository URL is
added twice** and the two entries track different packages.

**Stable** - add `https://github.com/source-opener/HeliBoard` with default
settings, "Include prereleases" off.

**Beta** - add the same URL again, then set:

- **Include prereleases**: on
- **Filter release titles by regular expression**: `-beta\.`

Both are needed. "Include prereleases" means include, not only, so without the
title filter the beta entry would pick up a stable release as soon as one is
newer and then fail to install it over the beta with a package-ID mismatch.

Use the release title filter, not the APK filter: the filter has to stop the
whole stable *release* from being considered, not just pick a file out of it.
