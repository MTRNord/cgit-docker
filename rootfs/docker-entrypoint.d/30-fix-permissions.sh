#!/bin/sh
# Script to fix file permissions. Loaded during Docker entrypoint.
set -eu

# Create fcgiwrap directory if it doesn't exist
mkdir -p /run/fcgiwrap/

# Fix cgit permissions - owned by gitolite3 user who also runs nginx/cgit
chown -R ${CGIT_APP_USER}:${CGIT_APP_USER} /opt/cgit/ \
                     /run/fcgiwrap/

chmod 770 /opt/cgit/ \
          /opt/cgit/filters/ \
          /opt/cgit/app/ \
          /opt/cgit/cache/

chmod u+x /opt/cgit/app/cgit.cgi


