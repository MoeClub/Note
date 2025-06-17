#!/bin/bash

target="${1:-}"
repo="${2:-}"
branch="${3:-main}"
clone="${4:-}"

[ -n "${target}" ] && [ -n "${repo}" ] || exit 1
# [ -e "${target}" ] || exit 1
tmp=$(mktemp -d)
trap "rm -rf ${tmp}" EXIT
cd "$tmp"

function createRepo(){
  rn="${1:-}"
  [ -n "$rn" ] || return 0
  resp=`curl -X POST -sSL "${rn%github.com*}api.github.com/user/repos" -d "{\"name\":\"${rn##*/}\"}"`
  echo "$resp" |grep '"status":' && return 1 || return 0
}

# init
git config --global init.defaultBranch "$branch"
git config --global pull.rebase true
git config --global user.name "remote"
git config --global user.email "remote@user"

git init
git checkout -b "$branch"
git remote rm origin >/dev/null 2>&1
git remote rm clone >/dev/null 2>&1
git remote add origin "$repo"

git pull origin "$branch"
[ -n "${target}" ] && [ "${target}" != "-" ] && {
  [ -f "${target}" ] && cp -rf "${target}" "${tmp}"
  [ -d "${target}" ] && cp -rf "${target%/}/." "${tmp}"
}

[ -n "$clone" ] && {
  rm -rf .git
  git init
  git checkout -b "$branch"
  git remote add clone "$clone"
  createRepo "$clone"
}

[ "${target}" == "-" ] && read -p "Pause <${tmp}> ..."

git add .
git commit -m `date +'%Y%m%d%H%M%S'`

# git config http.postBuffer 524288000
[ -n "$clone" ] && git push clone "$branch" -f || git push origin "$branch" -f


