#!/bin/sh
# Script to start SSH daemon for Gitolite. Loaded during Docker entrypoint.
set -eu

echo "Starting SSH daemon for Gitolite..."

# Configure SSH for Gitolite
cat > /etc/ssh/sshd_config << 'EOF'
LogLevel INFO

# SSH configuration for Gitolite
Port 2222
Protocol 2

# Restrict key exchange, cipher, and MAC algorithms, as per sshaudit.com
# hardening guide.
KexAlgorithms sntrup761x25519-sha512,sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-gcm@openssh.com,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
HostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
RequiredRSASize 3072
CASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256
GSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-
HostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256
PubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256

UsePAM no
PermitRootLogin no
AllowUsers gitolite3 git
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
StrictModes no

DisableForwarding yes
AllowAgentForwarding no
AllowStreamLocalForwarding no
AllowTcpForwarding no
PermitTunnel no
X11Forwarding no
PermitUserEnvironment no
PrintMotd no
PermitTTY no
EOF

# Start SSH daemon
/usr/sbin/sshd

echo "SSH daemon started."

exit 0
