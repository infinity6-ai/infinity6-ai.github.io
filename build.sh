#!/bin/bash -e

eval "$(i6dev meta debug i6githubio-build I6DEV_DEBUG)"

function cmd_tunnel() {
  gcloud compute ssh wordpress-tmp3 -- -L 8080:localhost:80 ping -i 30 localhost
}

function cmd_download_site() {
  [ ! -d "target/exported" ] || rm -rf "target/exported"
  mkdir -p target/exported
  cd target/exported
  wget \
    --convert-links \
    -R "*?p=*" \
    -r \
    --content-disposition \
    --mirror \
    --page-requisites \
    --no-parent \
    --span-hosts \
    --domains=localhost \
    http://localhost:8080

  cd - 1>&2
}

function cmd_fix_filenames() {
  cd target/exported

  local _k=""
  find -name '*\?*' | while read _k; do 
    mv "$_k" "$(echo "$_k" | cut -d'?' -f1)" 
  done

  cd - 1>&2
}

function cmd_download_videos() {
  [ ! -d "target/videos" ] || rm -rf "target/videos"
  mkdir -p target/videos
  cd target/videos
  grep -nro '[^;]\+\.mp4\&quot;' ../exported | \
    cut -d':' -f4- | \
    cut -d'&' -f1 | \
    sed 's/[\\\/]\+/\//g' | \
    sed 's/^/http:\/\/localhost:8080/g' | \
    sort | uniq | \
    xargs wget -c --force-directories
  cd - 1>&2
}

function cmd_fix_localhost() {
  local _k=""
  grep -nro 'http:[/\\]\+localhost:8080' target/exported | cut -d':' -f1,2 | sort | uniq | while read _k; do
    sed -i 's/http:[\\\/]\+localhost:8080/https:\/\/www-staging.infinity6.ai/g' "$_k"
  done
}

function cmd_export() {
  cmd_download_site
  cmd_fix_filenames
  cmd_download_videos
  cmd_fix_localhost
  cmd_publish
}

function cmd_publish() {
  rsync -av --delete target/exported/localhost:8080/ docs/
  rsync -av src/docs/ docs/
  rsync -av target/videos/localhost:8080/ docs/
}

function cmd_run() {
  cd docs
  python -m http.server 8000
  cd - 1>&2
}

cd "$(dirname "$0")"; _cmd="${1?"cmd is required"}"; shift; "cmd_${_cmd}" "$@"

