#!/bin/bash -e

eval "$(i6dev meta debug i6githubio-build I6DEV_DEBUG)"

function cmd_tunnel() {
  gcloud compute ssh wordpress-tmp3 -- -L 8080:localhost:80 ping -i 30 localhost
}

function cmd_download() {
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
  # http://localhost:8080/wp-content/uploads/2024/10/WhatsApp-Video-2024-10-14-at-19.24.27.mp4
  grep -nro '[^;]\+\.mp4\&' target/exported | cut -d':' -f3-
}

function cmd_run() {
  python -m http.server 8000
}




cd "$(dirname "$0")"; _cmd="${1?"cmd is required"}"; shift; "cmd_${_cmd}" "$@"

