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

  find -name '*\?*' | while read k; do 
    mv "$k" "$(echo "$k" | cut -d'?' -f1)" 
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

function cmd_export() {
  cmd_download_site
  cmd_download_videos
  cmd_publish
}

function cmd_publish() {
  rsync -av --delete target/exported/ docs/
}

function cmd_run() {
  python -m http.server 8000
}




cd "$(dirname "$0")"; _cmd="${1?"cmd is required"}"; shift; "cmd_${_cmd}" "$@"

