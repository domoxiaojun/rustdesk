#!/usr/bin/env bash

set -euo pipefail

readonly force_build="${FORCE_BUILD:-false}"
readonly requested_tag="${REQUESTED_TAG:-}"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

resolve_remote_tag() {
  local candidate="$1"
  local object
  local peeled

  object="$(git ls-remote origin "refs/tags/$candidate" | awk 'NR == 1 { print $1 }')"
  [[ -n "$object" ]] || return 1
  peeled="$(git ls-remote origin "refs/tags/$candidate^{}" | awk 'NR == 1 { print $1 }')"
  printf '%s\n' "${peeled:-$object}"
}

version="$(sed -nE 's/^version = "([^"]+)"/\1/p' Cargo.toml | head -n 1)"
[[ -n "$version" ]] || die "cannot read Cargo version"
base_tag="v$version"
head_sha="$(git rev-parse HEAD)"
base_commit="$(resolve_remote_tag "$base_tag" || true)"
dispatch=false
created=false
reason=""

if [[ -n "$requested_tag" ]]; then
  tag="$requested_tag"
  dispatch=true
  reason="requested tag"
elif [[ -z "$base_commit" ]]; then
  tag="$base_tag"
  dispatch=true
  reason="new official version"
elif [[ "$base_commit" == "$head_sha" ]]; then
  tag="$base_tag"
  if [[ "$force_build" == "true" ]]; then
    dispatch=true
    reason="requested rebuild"
  else
    reason="version already built from current HEAD"
  fi
elif [[ "$force_build" == "true" ]]; then
  max_revision=0
  while IFS= read -r existing_tag; do
    revision="${existing_tag#"$base_tag-"}"
    if [[ "$revision" =~ ^[0-9]+$ ]] && ((revision > max_revision)); then
      max_revision="$revision"
    fi
  done < <(
    git ls-remote --tags --refs origin "refs/tags/$base_tag-*" \
      | awk -F/ '{ print $3 }'
  )
  tag="$base_tag-$((max_revision + 1))"
  dispatch=true
  reason="requested revision build"
else
  tag="$base_tag"
  reason="official version already has a release"
fi

[[ "$tag" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?$ ]] \
  || die "invalid release tag: $tag"

if [[ "$dispatch" == "true" ]]; then
  remote_commit="$(resolve_remote_tag "$tag" || true)"
  if [[ -n "$remote_commit" ]]; then
    [[ "$remote_commit" == "$head_sha" ]] || die "$tag already points to another commit"
  else
    git tag "$tag" "$head_sha"
    git push origin "refs/tags/$tag"
    created=true
  fi
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "tag=$tag"
    echo "created=$created"
    echo "dispatch=$dispatch"
    echo "reason=$reason"
  } >>"$GITHUB_OUTPUT"
fi

printf 'release decision: tag=%s created=%s dispatch=%s reason=%s\n' \
  "$tag" "$created" "$dispatch" "$reason"
