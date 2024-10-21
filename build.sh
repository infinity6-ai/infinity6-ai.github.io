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



cd "$(dirname "$0")"; _cmd="${1?"cmd is required"}"; shift; "cmd_${_cmd}" "$@"

