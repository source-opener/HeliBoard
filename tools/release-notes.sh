#!/bin/sh
# Builds the release body from commit subjects, which is why commit subjects are
# written as user-facing lines.
#
# Both channels list everything this fork adds on top of upstream, so every
# release states the complete difference rather than only what moved since the
# last one. A beta adds a second list of what it has that stable does not.
#
# Usage: tools/release-notes.sh stable|beta

set -eu

channel="${1:-}"
case "$channel" in
    stable|beta) ;;
    *) echo "usage: $0 stable|beta" >&2; exit 2 ;;
esac

upstream_ref="${UPSTREAM_REF:-upstream/main}"
stable_ref="${STABLE_REF:-origin/main}"

for ref in "$upstream_ref" $( [ "$channel" = beta ] && echo "$stable_ref" ); do
    git rev-parse --verify --quiet "$ref^{commit}" >/dev/null || {
        echo "ref '$ref' not found, fetch it first" >&2
        exit 1
    }
done

subjects() {
    git log --no-merges --reverse --format='- %s' "$@"
}

fork_changes=$(subjects HEAD "^$upstream_ref")

echo "## What this fork adds"
echo
if [ -n "$fork_changes" ]; then
    echo "$fork_changes"
else
    echo "_Nothing yet - identical to upstream HeliBoard._"
fi

if [ "$channel" = beta ]; then
    beta_changes=$(subjects HEAD "^$upstream_ref" "^$stable_ref")
    echo
    echo "## Not in the stable release yet"
    echo
    if [ -n "$beta_changes" ]; then
        echo "$beta_changes"
    else
        echo "_Nothing - same as the current stable release._"
    fi
    echo
    echo "Installs alongside stable as a separate keyboard, which has to be enabled and selected in the system input settings."
fi
