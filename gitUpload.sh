#!/bin/bash

target="${1:-}"
repo="${2:-}"
branch="${3:-main}"

[ -n "${target}" ] && [ -n "${repo}" ] || exit 1
[ -e "${target}" ] || exit 1
tmp=$(mktemp -d)
cd "$tmp"

git init
git checkout -b "$branch"
git remote rm origin >/dev/null 2>&1
git remote add origin "$repo"

git pull origin "$branch"
[ -f "${target}" ] && cp -rf "${target}" "${tmp}"
[ -d "${target}" ] && cp -rf "${target%/}/." "${tmp}"

git add .
git commit -m `date +'%Y%m%d%H%M%S'`

# git config http.postBuffer 524288000
git push origin "$branch" -f


