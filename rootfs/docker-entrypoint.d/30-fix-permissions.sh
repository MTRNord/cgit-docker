#!/bin/sh
# Script to fix file permissions. Loaded during Docker entrypoint.
set -eu

# Fix cgit permissions
chown -R ${CGIT_APP_USER}:${CGIT_APP_USER} /opt/cgit/ \
                     /run/fcgiwrap/

chmod 770 /opt/cgit/ \
          /opt/cgit/filters/ \
          /opt/cgit/app/ \
          /opt/cgit/cache/

chmod u+x /opt/cgit/app/cgit.cgi

# Fix git/gitolite permissions
chown -R git:git /var/lib/git/

# Give nginx user read access to git repositories for cgit
# We do this by adding nginx to the git group
if ! groups ${CGIT_APP_USER} | grep -q git; then
    addgroup ${CGIT_APP_USER} git
fi

# Ensure repositories are readable by the git group
if [ -d /var/lib/git/repositories ]; then
    chown -R git:git /var/lib/git/repositories
    find /var/lib/git/repositories -type d -exec chmod 750 {} \;
    find /var/lib/git/repositories -type f -exec chmod 640 {} \;
fi

