#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/fetch-artifacts.sh [--release <tag>] [--dest <dir>]
# Default: latest release, dest ./artifacts
RELEASE_TAG=""
DEST_DIR="./artifacts"
GITHUB_OWNER="tty-pt"   # update if repo owner differs
GITHUB_REPO="$(basename $(git rev-parse --show-toplevel))"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release) RELEASE_TAG="$2"; shift 2;;
    --dest) DEST_DIR="$2"; shift 2;;
    --help) echo "Usage: $0 [--release <tag>] [--dest <dir>]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

if [[ -z "$RELEASE_TAG" ]]; then
  API_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest"
else
  API_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/tags/${RELEASE_TAG}"
fi

AUTH_HDR=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HDR=(-H "Authorization: token ${GITHUB_TOKEN}")
fi

RELEASE_JSON=$(curl -s "${AUTH_HDR[@]}" "$API_URL")
if [[ -z "$RELEASE_JSON" ]]; then
  echo "Failed to fetch release metadata from $API_URL" >&2
  exit 1
fi

if [[ -f ../CHECKSUMS ]]; then
  while read -r checksum filename; do
    filename="${filename##*/}"
    echo "Fetching $filename ..."
    ASSET_URL=$(echo "$RELEASE_JSON" | jq -r --arg NAME "$filename" '.assets[] | select(.name==$NAME) | .browser_download_url')
    if [[ -z "$ASSET_URL" || "$ASSET_URL" == "null" ]]; then
      echo "Asset $filename not found in release" >&2
      exit 2
    fi
    curl -L -o "$filename" "${ASSET_URL}"
    echo "Verifying checksum for $filename ..."
    echo "$checksum  $filename" | sha256sum -c -
  done < ../CHECKSUMS
else
  echo "No CHECKSUMS file found; downloading all assets from release."
  ASSET_URLS=$(echo "$RELEASE_JSON" | jq -r '.assets[] | .browser_download_url')
  for u in $ASSET_URLS; do
    fname=$(basename "$u")
    curl -L -o "$fname" "${u}"
  done
fi

echo "All artifacts downloaded to $(pwd)"
