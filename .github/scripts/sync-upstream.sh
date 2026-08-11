#!/usr/bin/env bash

set -euo pipefail

readonly upstream_url="${UPSTREAM_URL:-https://github.com/rustdesk/rustdesk.git}"
readonly upstream_branch="${UPSTREAM_BRANCH:-master}"
readonly upstream_remote="${UPSTREAM_REMOTE:-upstream-sync}"
readonly hbb_branch="${HBB_BRANCH:-main}"
readonly submodule_path="libs/hbb_common"
readonly api_file="src/common.rs"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

extract_api_fallback() {
  local matches
  local count

  matches="$(
    sed -n '/^fn get_api_server_(/,/^}/p' "$api_file" \
      | grep -E '^[[:space:]]*"https?://[^"]+"\.to_owned\(\)$' \
      || true
  )"
  count="$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l | tr -d ' ')"
  [[ "$count" == "1" ]] || die "expected one API fallback line in $api_file, found $count"
  printf '%s\n' "$matches"
}

read_hbb_url() {
  local url

  url="$(git config -f .gitmodules --get submodule.libs/hbb_common.url || true)"
  [[ -n "$url" ]] || die "missing hbb_common URL in .gitmodules"
  printf '%s\n' "$url"
}

abort_merge_on_error() {
  local status=$?

  if [[ "$status" -ne 0 ]] && git rev-parse --verify -q MERGE_HEAD >/dev/null; then
    git merge --abort || true
  fi
  exit "$status"
}

trap abort_merge_on_error EXIT

[[ -z "$(git status --porcelain)" ]] || die "worktree must be clean before syncing"

before_api="$(extract_api_fallback)"
before_hbb_url="$(read_hbb_url)"
before_sha="$(git rev-parse HEAD)"

if git remote get-url "$upstream_remote" >/dev/null 2>&1; then
  git remote set-url "$upstream_remote" "$upstream_url"
else
  git remote add "$upstream_remote" "$upstream_url"
fi

git fetch --no-tags "$upstream_remote" \
  "+refs/heads/$upstream_branch:refs/remotes/$upstream_remote/$upstream_branch"
upstream_ref="$upstream_remote/$upstream_branch"

upstream_hbb_sha="$(git ls-tree "$upstream_ref" "$submodule_path" | awk '$1 == "160000" { print $3 }')"
[[ "$upstream_hbb_sha" =~ ^[0-9a-f]{40}$ ]] || die "invalid upstream hbb_common gitlink"

custom_hbb_sha="$(git ls-remote "$before_hbb_url" "refs/heads/$hbb_branch" | awk 'NR == 1 { print $1 }')"
[[ "$custom_hbb_sha" =~ ^[0-9a-f]{40}$ ]] || die "cannot resolve custom hbb_common $hbb_branch"

temp_hbb_repo="$(mktemp -d)"
git -C "$temp_hbb_repo" init --bare --quiet
git -C "$temp_hbb_repo" fetch --no-tags "$before_hbb_url" \
  "+refs/heads/$hbb_branch:refs/heads/custom-main" >/dev/null
git -C "$temp_hbb_repo" cat-file -e "$upstream_hbb_sha^{commit}" \
  || die "custom hbb_common is missing upstream commit $upstream_hbb_sha"
git -C "$temp_hbb_repo" merge-base --is-ancestor "$upstream_hbb_sha" "$custom_hbb_sha" \
  || die "custom hbb_common must be synchronized before RustDesk"

merge_started=false
if ! git merge-base --is-ancestor "$upstream_ref" HEAD; then
  merge_started=true
  set +e
  git merge --no-commit --no-ff "$upstream_ref"
  merge_status=$?
  set -e

  if [[ "$merge_status" -ne 0 ]]; then
    conflicts="$(git diff --name-only --diff-filter=U)"
    [[ "$conflicts" == "$submodule_path" ]] \
      || die "unexpected merge conflicts: ${conflicts:-none}"
  fi
fi

git update-index --add --cacheinfo "160000,$custom_hbb_sha,$submodule_path"
[[ -z "$(git diff --name-only --diff-filter=U)" ]] || die "unresolved merge conflicts remain"

after_api="$(extract_api_fallback)"
after_hbb_url="$(read_hbb_url)"
[[ "$after_api" == "$before_api" ]] || die "custom API server changed during sync"
[[ "$after_hbb_url" == "$before_hbb_url" ]] || die "custom hbb_common URL changed during sync"
git diff --cached "$upstream_ref" --check

if [[ "$merge_started" == "true" ]]; then
  git commit -m "Merge upstream RustDesk master"
elif ! git diff --cached --quiet; then
  git commit -m "Update custom hbb_common submodule"
fi

git merge-base --is-ancestor "$upstream_ref" HEAD || die "upstream commit is not an ancestor of HEAD"
recorded_hbb_sha="$(git ls-tree HEAD "$submodule_path" | awk '$1 == "160000" { print $3 }')"
[[ "$recorded_hbb_sha" == "$custom_hbb_sha" ]] || die "recorded hbb_common gitlink is incorrect"
git diff --check "$upstream_ref"..HEAD

after_sha="$(git rev-parse HEAD)"
changed=false
if [[ "$after_sha" != "$before_sha" ]]; then
  changed=true
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'changed=%s\nhead=%s\nhbb=%s\n' \
    "$changed" "$after_sha" "$custom_hbb_sha" >>"$GITHUB_OUTPUT"
fi

printf 'sync complete: changed=%s head=%s hbb=%s\n' \
  "$changed" "$after_sha" "$custom_hbb_sha"
