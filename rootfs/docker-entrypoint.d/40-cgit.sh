#!/bin/sh
# Script to start cgit as a native FastCGI application. Loaded during Docker entrypoint.
SOCKET_PATH=/run/cgit/cgit.sock
SOCKET_DIR=/run/cgit

echo "Starting cgit FastCGI daemon..."

# Create socket directory
mkdir -p "$SOCKET_DIR"
chown ${CGIT_APP_USER}:${CGIT_APP_USER} "$SOCKET_DIR"

echo "Starting cgit with socket at $SOCKET_PATH..."
# Start cgit as native FastCGI daemon
su ${CGIT_APP_USER} -s /bin/sh -c "/opt/cgit/bin/cgit &"

# Wait for socket to be created
echo "Waiting for cgit to create socket..."
while [ ! -e "$SOCKET_PATH" ]; do
    sleep 1
done

echo "cgit FastCGI daemon started successfully"
exit 0
