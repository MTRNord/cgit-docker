#!/bin/sh
# Start git maintenance in repositories so git itself configures maintenance timers.
# This script should run after permissions have been fixed (i.e., after 30-fix-permissions.sh).
set -eu

REPO_PATHS="/var/lib/gitolite3/repositories"
GITUSER=gitolite3

if ! command -v git >/dev/null 2>&1; then
    echo "git not available; skipping git maintenance start"
    exit 0
fi

for base in $REPO_PATHS; do
    if [ -d "$base" ]; then
        for repo in "$base"/*; do
            [ -e "$repo" ] || continue
            # Run git maintenance start as gitolite3 so per-repo timers are created under the correct user
            echo "Starting git maintenance for: $repo"
            su -s /bin/sh $GITUSER -c "git -C '$repo' maintenance start --quiet" || \
                echo "git maintenance start failed for $repo"
        done
    fi
done

exit 0
