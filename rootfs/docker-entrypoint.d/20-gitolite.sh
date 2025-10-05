#!/bin/sh
# Script to initialize Gitolite. Loaded during Docker entrypoint.
set -eu

GITOLITE_HOME=/var/lib/git
GITOLITE_ADMIN_KEY=/var/lib/git/.ssh/admin.pub

echo "Initializing Gitolite..."

# Check if admin key exists, if not create a default one
if [ ! -f "$GITOLITE_ADMIN_KEY" ]; then
    echo "No admin SSH key found. Creating a default one..."
    echo "WARNING: Using default admin key. Please replace with your own key!"
    ssh-keygen -t rsa -b 4096 -f /var/lib/git/.ssh/admin -N "" -C "gitolite-admin@docker"
    cp /var/lib/git/.ssh/admin.pub "$GITOLITE_ADMIN_KEY"
    chown git:git /var/lib/git/.ssh/admin*
    chmod 600 /var/lib/git/.ssh/admin
    chmod 644 /var/lib/git/.ssh/admin.pub
fi

# Initialize Gitolite if not already initialized
if [ ! -d "$GITOLITE_HOME/repositories" ]; then
    echo "Setting up Gitolite for the first time..."
    su git -c "gitolite setup -pk $GITOLITE_ADMIN_KEY"
    
    # Create symlink from repositories to /opt/git for cgit
    if [ ! -L "/opt/git" ]; then
        rm -rf /opt/git
        ln -sf $GITOLITE_HOME/repositories /opt/git
    fi
else
    echo "Gitolite already initialized."
    # Ensure symlink exists
    if [ ! -L "/opt/git" ]; then
        rm -rf /opt/git
        ln -sf $GITOLITE_HOME/repositories /opt/git
    fi
fi

# Fix permissions
chown -R git:git $GITOLITE_HOME

echo "Gitolite initialization complete."

exit 0
