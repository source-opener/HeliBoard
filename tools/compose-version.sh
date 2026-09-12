#!/bin/sh
# Composes the fork's published version from upstream's version and the fork revision.
#
#   upstream 4.1 (code 4101) + fork-version 1  ->  4.1.1, code 4101001
#
# Prints KEY=VALUE lines for $GITHUB_ENV. Requires published tags to be fetched.
#
# Usage: tools/compose-version.sh stable|beta

set -eu

channel="${1:-}"
case "$channel" in
    stable|beta) ;;
    *) echo "usage: $0 stable|beta" >&2; exit 2 ;;
esac

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
gradle_file="$root/app/build.gradle.kts"

upstream_name=$(sed -n 's/^[[:space:]]*versionName = "\(.*\)"$/\1/p' "$gradle_file")
upstream_code=$(sed -n 's/^[[:space:]]*versionCode = \([0-9][0-9]*\)$/\1/p' "$gradle_file")

if [ -z "$upstream_name" ] || [ -z "$upstream_code" ]; then
    echo "could not read versionName/versionCode from $gradle_file" >&2
    exit 1
fi

fork_rev=$(tr -d '[:space:]' < "$root/fork-version")
case "$fork_rev" in
    ''|*[!0-9]*) echo "fork-version must contain a number, got '$fork_rev'" >&2; exit 1 ;;
esac
if [ "$fork_rev" -lt 1 ] || [ "$fork_rev" -gt 999 ]; then
    echo "fork-version must be between 1 and 999, got $fork_rev" >&2
    echo "the composed version code is upstream_code * 1000 + fork-version, so it has no room for more" >&2
    exit 1
fi

tag_exists() {
    [ -n "$(git -C "$root" tag -l "$1")" ]
}

if [ "$channel" = stable ]; then
    if tag_exists "v$upstream_name.$fork_rev"; then
        echo "v$upstream_name.$fork_rev is already released" >&2
        echo "raise fork-version to $((fork_rev + 1)) to ship another stable release from upstream $upstream_name" >&2
        exit 1
    fi
    version="$upstream_name.$fork_rev"
else
    # a beta names the version it leads to, so step past every revision already released
    while tag_exists "v$upstream_name.$fork_rev"; do
        fork_rev=$((fork_rev + 1))
        if [ "$fork_rev" -gt 999 ]; then
            echo "no fork revision below 1000 left for upstream $upstream_name" >&2
            exit 1
        fi
    done
    base="$upstream_name.$fork_rev"
    highest=$(git -C "$root" tag -l "v$base-beta.*" \
        | sed "s/^v$base-beta\.//" \
        | grep '^[0-9][0-9]*$' \
        | sort -n | tail -1)
    version="$base-beta.$(( ${highest:-0} + 1 ))"
fi

echo "VERSION_NAME=$version"
echo "VERSION_CODE=$((upstream_code * 1000 + fork_rev))"
echo "TAG=v$version"
