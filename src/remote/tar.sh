#!/bin/bash -e

cat /tmp/list.filtered.txt | xargs tar czf /tmp/export.tar.gz
