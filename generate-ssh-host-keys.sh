#!/bin/sh
# Script to generate SSH host keys for persistent use with cgit-gitolite container
set -eu

KEYS_DIR="./ssh-host-keys"

echo "Generating SSH host keys for cgit-gitolite container..."
echo

# Create directory if it doesn't exist
if [ -d "$KEYS_DIR" ]; then
    echo "Warning: Directory $KEYS_DIR already exists."
    echo "This will overwrite existing keys. Press Ctrl+C to cancel, or Enter to continue."
    read -r _
    echo
fi

mkdir -p "$KEYS_DIR"

# Generate host keys
echo "Generating RSA host key..."
ssh-keygen -t rsa -b 4096 -f "$KEYS_DIR/ssh_host_rsa_key" -N "" -C "cgit-gitolite-host-rsa"

echo "Generating ECDSA host key..."
ssh-keygen -t ecdsa -b 521 -f "$KEYS_DIR/ssh_host_ecdsa_key" -N "" -C "cgit-gitolite-host-ecdsa"

echo "Generating ED25519 host key..."
ssh-keygen -t ed25519 -f "$KEYS_DIR/ssh_host_ed25519_key" -N "" -C "cgit-gitolite-host-ed25519"

# Set proper permissions
chmod 600 "$KEYS_DIR"/ssh_host_*_key
chmod 644 "$KEYS_DIR"/ssh_host_*_key.pub

echo
echo "✓ SSH host keys generated successfully in $KEYS_DIR/"
echo
echo "Host key fingerprints:"
echo "====================="
ssh-keygen -lf "$KEYS_DIR/ssh_host_rsa_key.pub"
ssh-keygen -lf "$KEYS_DIR/ssh_host_ecdsa_key.pub"
ssh-keygen -lf "$KEYS_DIR/ssh_host_ed25519_key.pub"
echo
echo "To use these keys with your container, run:"
echo
echo "docker run -d \\"
echo "  --name cgit \\"
echo "  -p 8080:8080 \\"
echo "  -p 2222:22 \\"
echo "  -v gitolite-data:/var/lib/git \\"
echo "  -v \$(pwd)/ssh-host-keys/ssh_host_rsa_key:/etc/ssh/ssh_host_rsa_key:ro \\"
echo "  -v \$(pwd)/ssh-host-keys/ssh_host_rsa_key.pub:/etc/ssh/ssh_host_rsa_key.pub:ro \\"
echo "  -v \$(pwd)/ssh-host-keys/ssh_host_ecdsa_key:/etc/ssh/ssh_host_ecdsa_key:ro \\"
echo "  -v \$(pwd)/ssh-host-keys/ssh_host_ecdsa_key.pub:/etc/ssh/ssh_host_ecdsa_key.pub:ro \\"
echo "  -v \$(pwd)/ssh-host-keys/ssh_host_ed25519_key:/etc/ssh/ssh_host_ed25519_key:ro \\"
echo "  -v \$(pwd)/ssh-host-keys/ssh_host_ed25519_key.pub:/etc/ssh/ssh_host_ed25519_key.pub:ro \\"
echo "  cgit-gitolite"
echo
echo "⚠️  IMPORTANT: Keep these keys secure and backed up!"
