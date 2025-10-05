#!/bin/sh
# Script to fix file permissions. Loaded during Docker entrypoint.
set -eu

GITOLITE_USER=gitolite3

chmod 770 /opt/cgit/ \
          /opt/cgit/filters/ \
          /opt/cgit/app/ \
          /opt/cgit/cache/

chmod u+x /opt/cgit/app/cgit.cgi

# Fix git/gitolite permissions
chown -R $GITOLITE_USER:$GITOLITE_USER /var/lib/git/

# Give nginx user read access to git repositories for cgit
# We do this by adding nginx to the gitolite3 group
if ! groups ${CGIT_APP_USER} | grep -q $GITOLITE_USER; then
    usermod -a -G $GITOLITE_USER ${CGIT_APP_USER}
    echo "Added ${CGIT_APP_USER} to $GITOLITE_USER group for repository access"
fi

# Ensure git home directory is accessible
chmod 755 /var/lib/git

# Ensure repositories are readable by the gitolite3 group
if [ -d /var/lib/git/repositories ]; then
    chown -R $GITOLITE_USER:$GITOLITE_USER /var/lib/git/repositories
    # Directories: owner can write, group can read/execute (traverse)
    find /var/lib/git/repositories -type d -exec chmod 750 {} \;
    # Files: owner can write, group can read
    find /var/lib/git/repositories -type f -exec chmod 640 {} \;
    echo "Set read permissions for ${CGIT_APP_USER} on repositories"
fi

# Ensure projects.list is readable
if [ -f /var/lib/git/projects.list ]; then
    chmod 644 /var/lib/git/projects.list
    echo "Made projects.list readable for cgit"
fi

