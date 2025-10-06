#!/bin/sh
# Script to initialize Gitolite. Loaded during Docker entrypoint.
set -eu

GITOLITE_HOME=/var/lib/gitolite3
GITOLITE_ADMIN_KEY=$GITOLITE_HOME/.ssh/admin.pub
GITOLITE_USER=gitolite3

# Ensure /tmp exists and is writable
mkdir -p /tmp
chmod 1777 /tmp

echo "Initializing Gitolite..."

# Initialize Gitolite if not already initialized
# Check for gitolite-admin.git as the definitive indicator of setup completion
if [ ! -d "$GITOLITE_HOME/repositories/gitolite-admin.git" ]; then
    echo "Setting up Gitolite for the first time..."
    
    # Check if admin key exists, if not create a default one
    if [ ! -f "$GITOLITE_ADMIN_KEY" ]; then
        echo "No admin SSH key found. Creating a default one..."
        echo "WARNING: Using default admin key. Please replace with your own key!"
        mkdir -p $GITOLITE_HOME/.ssh
        chown $GITOLITE_USER:$GITOLITE_USER $GITOLITE_HOME/.ssh/
        ssh-keygen -t rsa -b 4096 -f $GITOLITE_HOME/.ssh/admin -N "" -C "gitolite-admin@docker"
        chown $GITOLITE_USER:$GITOLITE_USER $GITOLITE_HOME/.ssh/admin*
        chmod 600 $GITOLITE_HOME/.ssh/admin
        chmod 644 $GITOLITE_HOME/.ssh/admin.pub
    fi
    
    su -s /bin/sh $GITOLITE_USER -c "gitolite setup -pk '$GITOLITE_ADMIN_KEY'"
    
    # Configure Gitolite to generate projects.list for cgit (run as root since file is owned by root)
    # Only add if not already present
    if ! grep -q "^[[:space:]]*GITWEB_PROJECTS_LIST" "$GITOLITE_HOME/.gitolite.rc" 2>/dev/null; then
        echo "Configuring Gitolite to generate projects.list for cgit..."
        sed -i '/^%RC = (/a\    GITWEB_PROJECTS_LIST => "$ENV{HOME}/projects.list",' "$GITOLITE_HOME/.gitolite.rc"
    fi

    # Configure GIT_CONFIG_KEYS to allow setting git config values
    if ! grep -q "^[[:space:]]*GIT_CONFIG_KEYS.*core\.\*" "$GITOLITE_HOME/.gitolite.rc" 2>/dev/null; then
        echo "Configuring GIT_CONFIG_KEYS for Gitolite..."
        sed -i "s/^\([[:space:]]*\)GIT_CONFIG_KEYS[[:space:]]*=>[[:space:]]*'',/\1GIT_CONFIG_KEYS => 'gitweb\..*',/" "$GITOLITE_HOME/.gitolite.rc"
    fi
    
    # Generate initial projects.list (run as gitolite3 user)
    su -s /bin/sh $GITOLITE_USER -c "gitolite setup"
else
    echo "Gitolite already initialized."
fi

# Ensure projects.list is readable by nginx (for cgit)
if [ -f "$GITOLITE_HOME/projects.list" ]; then
    chmod 644 "$GITOLITE_HOME/projects.list"
fi

# Fix permissions
chown -R $GITOLITE_USER:$GITOLITE_USER $GITOLITE_HOME
# Ensure home directory is traversable by group members (nginx needs to access repositories)
chmod 755 $GITOLITE_HOME
# Ensure repositories directory is traversable
if [ -d "$GITOLITE_HOME/repositories" ]; then
    chmod 755 "$GITOLITE_HOME/repositories"
fi

echo "Gitolite initialization complete."

exit 0
