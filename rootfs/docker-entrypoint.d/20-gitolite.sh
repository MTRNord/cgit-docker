#!/bin/sh
# Script to initialize Gitolite. Loaded during Docker entrypoint.
set -eu

GITOLITE_HOME=/var/lib/git
GITOLITE_ADMIN_KEY=$GITOLITE_HOME/.ssh/admin.pub

echo "Initializing Gitolite..."

# Check if admin key exists, if not create a default one
if [ ! -f "$GITOLITE_ADMIN_KEY" ]; then
    echo "No admin SSH key found. Creating a default one..."
    echo "WARNING: Using default admin key. Please replace with your own key!"
    ssh-keygen -t rsa -b 4096 -f $GITOLITE_HOME/.ssh/admin -N "" -C "gitolite-admin@docker"
    chown git:git $GITOLITE_HOME/.ssh/admin*
    chmod 600 $GITOLITE_HOME/.ssh/admin
    chmod 644 $GITOLITE_HOME/.ssh/admin.pub
fi

# Initialize Gitolite if not already initialized
if [ ! -d "$GITOLITE_HOME/repositories" ]; then
    echo "Setting up Gitolite for the first time..."
    su git -c "gitolite setup -pk $GITOLITE_ADMIN_KEY"
    
    # Configure Gitolite to generate projects.list for cgit
    echo "Configuring Gitolite to generate projects.list for cgit..."
    su git -c "sed -i \"s|# GITWEB_PROJECTS_LIST.*|GITWEB_PROJECTS_LIST => '\\\$ENV{HOME}/projects.list',|\" $GITOLITE_HOME/.gitolite.rc"
    
    # Generate initial projects.list
    su git -c "gitolite trigger POST_COMPILE"
else
    echo "Gitolite already initialized."

    # Ensure projects.list configuration exists
    if ! grep -q "^[[:space:]]*GITWEB_PROJECTS_LIST" "$GITOLITE_HOME/.gitolite.rc" 2>/dev/null; then
        echo "Adding projects.list configuration to Gitolite..."
        su git -c "sed -i \"s|# GITWEB_PROJECTS_LIST.*|GITWEB_PROJECTS_LIST => '\\\$ENV{HOME}/projects.list',|\" $GITOLITE_HOME/.gitolite.rc"
        su git -c "gitolite trigger POST_COMPILE"
    fi
fi

# Ensure projects.list is readable by nginx (for cgit)
if [ -f "$GITOLITE_HOME/projects.list" ]; then
    chmod 644 "$GITOLITE_HOME/projects.list"
fi

# Fix permissions
chown -R git:git $GITOLITE_HOME

echo "Gitolite initialization complete."

exit 0
