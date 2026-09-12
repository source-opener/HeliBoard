#!/bin/sh
# Creates the signing key for the fork's releases and prints the four repository
# secrets to set. Run this on your own machine.
#
# The key is the app's permanent identity: anyone holding it can ship an update
# that installs over yours. It must never be committed, pasted into a chat, or
# stored anywhere but your machine and the repository secrets. Losing it means
# every user has to uninstall and reinstall to move to a new key.
#
# Usage: tools/generate-keystore.sh [output.jks]

set -eu

keystore="${1:-$HOME/heliboard-release-key.jks}"
alias_name=heliboard

case "$keystore" in
    /*) ;;
    *) keystore="$PWD/$keystore" ;;
esac

if [ -e "$keystore" ]; then
    echo "$keystore already exists, refusing to overwrite it" >&2
    exit 1
fi

repo_root=$(git -C "$(dirname -- "$0")" rev-parse --show-toplevel 2>/dev/null || true)
case "${repo_root:+$keystore}" in
    "$repo_root"/*)
        echo "$keystore is inside the repository, pick a path outside it" >&2
        exit 1 ;;
esac

password() {
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | dd bs=1 count=32 2>/dev/null
}

# a PKCS12 keystore cannot hold a key password different from the store password,
# so both secrets carry the same value
store_password=$(password)

KEYSTORE_PASSWORD="$store_password" keytool -genkeypair \
    -keystore "$keystore" \
    -storetype PKCS12 \
    -alias "$alias_name" \
    -keyalg RSA \
    -keysize 4096 \
    -validity 10950 \
    -dname "CN=HeliBoard, OU=fork, O=HeliBoard" \
    -storepass:env KEYSTORE_PASSWORD \
    -keypass:env KEYSTORE_PASSWORD

chmod 600 "$keystore"

cat <<TEXT

Keystore written to $keystore - back it up somewhere safe and private.

Set these four repository secrets under
  Settings -> Secrets and variables -> Actions -> New repository secret

KEYSTORE_BASE64
$(base64 < "$keystore" | tr -d '\n')

KEYSTORE_PASSWORD
$store_password

KEY_ALIAS
$alias_name

KEY_PASSWORD
$store_password

TEXT
