#!/bin/bash -xe


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

#find -name '*\?*' | while read k; do mv "$k" "$(echo "$k" | cut -d'?' -f1)"; done
