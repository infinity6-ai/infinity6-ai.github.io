#!/bin/bash -e

eval "$(i6dev meta debug i6githubio-build I6DEV_DEBUG)"

function cmd_tunnel() {
  gcloud compute ssh wordpress-tmp3 -- -L 8080:localhost:80 ping -i 30 localhost
}

function cmd_download_assets() {
  [ ! -d "target/assets" ] || rm -rf "target/assets"
  mkdir -p target/assets
  cd target/assets
  gcloud compute ssh wordpress-tmp3 -- \
    docker exec -w /var/www -i i6site-wordpress-1 \
      find html -type f | dos2unix > list.all.txt
  grep '\.css$' list.all.txt >> list.filtered.txt
  grep '\.json$' list.all.txt >> list.filtered.txt
  grep '\.js$' list.all.txt >> list.filtered.txt
  grep '\.woff$' list.all.txt >> list.filtered.txt
  grep '\.gif$' list.all.txt >> list.filtered.txt
  grep '\.png$' list.all.txt >> list.filtered.txt
  grep '\.svg$' list.all.txt >> list.filtered.txt
  grep '\.ttf$' list.all.txt >> list.filtered.txt
  grep '\.html$' list.all.txt >> list.filtered.txt
  grep '\.scss$' list.all.txt >> list.filtered.txt
  grep '\.webp$' list.all.txt >> list.filtered.txt
  grep '\.jpg$' list.all.txt >> list.filtered.txt
  grep '\.eot$' list.all.txt >> list.filtered.txt
  grep '\.txt$' list.all.txt >> list.filtered.txt
  grep '\.jpeg$' list.all.txt >> list.filtered.txt
  grep '\.mp4$' list.all.txt >> list.filtered.txt
  # gcloud compute copy-files list.filtered.txt wordpress-tmp3:/tmp/list.filtered.txt
  # gcloud compute ssh wordpress-tmp3 -- docker cp /tmp/list.filtered.txt i6site-wordpress-1:/tmp/list.filtered.txt
  cat list.filtered.txt | xargs gcloud compute ssh wordpress-tmp3 -- docker exec -w /var/www -i i6site-wordpress-1 tar czf - > export.assets.tar.gz
  tar xzf export.assets.tar.gz
  cd - 1>&2
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

