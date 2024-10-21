#!/bin/bash -xe

# cat /tmp/list.filtered.txt | xargs tar czf /tmp/export.tar.gz
# tar czf /tmp/export.tar.gz html

rm -rf /tmp/html/ || true
rsync -a --files-from=/tmp/list.filtered.txt ./ /tmp/html/
cd /tmp/html
tar czf /tmp/export.tar.gz html