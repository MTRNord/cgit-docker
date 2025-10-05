#!/bin/sh
# Script to initialize Gitolite. Loaded during Docker entrypoint.
set -eu

GITOLITE_HOME=/var/lib/git
GITOLITE_ADMIN_KEY=$GITOLITE_HOME/.ssh/admin.pub
GITOLITE_USER=gitolite3

# Ensure /tmp exists and is writable
mkdir -p /tmp
chmod 1777 /tmp

echo "Initializing Gitolite..."

# Check if admin key exists, if not create a default one
if [ ! -f "$GITOLITE_ADMIN_KEY" ]; then
    echo "No admin SSH key found. Creating a default one..."
    echo "WARNING: Using default admin key. Please replace with your own key!"
    ssh-keygen -t rsa -b 4096 -f $GITOLITE_HOME/.ssh/admin -N "" -C "gitolite-admin@docker"
    chown $GITOLITE_USER:$GITOLITE_USER $GITOLITE_HOME/.ssh/admin*
    chmod 600 $GITOLITE_HOME/.ssh/admin
    chmod 644 $GITOLITE_HOME/.ssh/admin.pub
fi

# Initialize Gitolite if not already initialized
if [ ! -d "$GITOLITE_HOME/repositories" ]; then
    echo "Setting up Gitolite for the first time..."
    su -s /bin/sh $GITOLITE_USER -c "gitolite setup -pk '$GITOLITE_ADMIN_KEY'"
    
    # Configure Gitolite to generate projects.list for cgit
    echo "Configuring Gitolite to generate projects.list for cgit..."
    su -s /bin/sh $GITOLITE_USER -c "sed -i '/^%RC = (/a\\    GITWEB_PROJECTS_LIST => '\''\$ENV{HOME}/projects.list'\'',' $GITOLITE_HOME/.gitolite.rc"
    
    # Generate initial projects.list
    su -s /bin/sh $GITOLITE_USER -c "gitolite trigger POST_COMPILE"
else
    echo "Gitolite already initialized."

    # Ensure projects.list configuration exists
    if ! grep -q "^[[:space:]]*GITWEB_PROJECTS_LIST" "$GITOLITE_HOME/.gitolite.rc" 2>/dev/null; then
        echo "Adding projects.list configuration to Gitolite..."
        su -s /bin/sh $GITOLITE_USER -c "sed -i '/^%RC = (/a\\    GITWEB_PROJECTS_LIST => '\''\$ENV{HOME}/projects.list'\'',' $GITOLITE_HOME/.gitolite.rc"
        su -s /bin/sh $GITOLITE_USER -c "gitolite trigger POST_COMPILE"
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
