#!/bin/sh
# Script to initialize Gitolite. Loaded during Docker entrypoint.
set -eu

GITOLITE_HOME=/var/lib/gitolite3
GITOLITE_ADMIN_KEY=$GITOLITE_HOME/.ssh/admin.pub
GITOLITE_USER=gitolite3
GITOLITE_RC=/etc/gitolite3/gitolite.rc

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
    echo "Configuring Gitolite to generate projects.list for cgit..."
    sed -i '/^%RC = (/a\    GITWEB_PROJECTS_LIST => "$ENV{HOME}/projects.list",' "$GITOLITE_RC"
    
    # Generate initial projects.list (run as gitolite3 user)
    su -s /bin/sh $GITOLITE_USER -c "gitolite setup"
else
    echo "Gitolite already initialized."

    # Ensure projects.list configuration exists (run as root since file is owned by root)
    if ! grep -q "^[[:space:]]*GITWEB_PROJECTS_LIST" "$GITOLITE_RC" 2>/dev/null; then
        echo "Adding projects.list configuration to Gitolite..."
        sed -i '/^%RC = (/a\    GITWEB_PROJECTS_LIST => "$ENV{HOME}/projects.list",' "$GITOLITE_HOME/.gitolite.rc"
        su -s /bin/sh $GITOLITE_USER -c "gitolite setup"
    fi
fi

# Ensure projects.list is readable by nginx (for cgit)
if [ -f "$GITOLITE_HOME/projects.list" ]; then
    chmod 644 "$GITOLITE_HOME/projects.list"
fi

# Fix permissions
chown -R $GITOLITE_USER:$GITOLITE_USER $GITOLITE_HOME

echo "Gitolite initialization complete."

exit 0
