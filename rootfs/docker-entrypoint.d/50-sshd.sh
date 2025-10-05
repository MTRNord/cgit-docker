#!/bin/sh
# Script to start SSH daemon for Gitolite. Loaded during Docker entrypoint.
set -eu

echo "Starting SSH daemon for Gitolite..."

# Configure SSH for Gitolite
cat > /etc/ssh/sshd_config << 'EOF'
# SSH configuration for Gitolite
Port 22
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/ssh/sftp-server
EOF

# Start SSH daemon
/usr/sbin/sshd

echo "SSH daemon started."

exit 0
