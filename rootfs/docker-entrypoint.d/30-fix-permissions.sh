#!/bin/sh
# Script to fix file permissions. Loaded during Docker entrypoint.
set -eu

# Create cgit socket directory
mkdir -p /run/cgit/

# Fix cgit permissions - owned by gitolite3 user who also runs nginx/cgit
chown -R ${CGIT_APP_USER}:${CGIT_APP_USER} /opt/cgit/ \
                     /run/cgit/

chmod -R 770 /opt/cgit/

chmod u+x /opt/cgit/bin/cgit


