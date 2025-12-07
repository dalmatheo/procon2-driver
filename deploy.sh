#!/bin/bash

# --- Configuration ---
SERVICE_NAME="procon2-driver"
EXECUTABLE_NAME="procon2-driver"
SERVICE_FILE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
INSTALL_PATH="/usr/local/bin/${EXECUTABLE_NAME}"
PROJECT_ROOT=$(pwd)

# --- 1. Compile the Project ---
echo "⚙️  1. Compiling Go project..."
go build -o "${EXECUTABLE_NAME}"
if [ $? -ne 0 ]; then
    echo "❌ Compilation failed. Aborting."
    exit 1
fi
echo "✅ Compilation successful. Binary: ${EXECUTABLE_NAME}"

# --- 2. Move the Executable ---
echo "📦 2. Moving executable to ${INSTALL_PATH}..."
# This step was correct and needs sudo
sudo mv "${EXECUTABLE_NAME}" "${INSTALL_PATH}"
if [ $? -ne 0 ]; then
    echo "❌ Failed to move executable. Aborting."
    exit 1
fi
echo "✅ Executable moved and ready."

# --- 3. Create the systemd Service File (FIXED) ---
echo "📝 3. Creating systemd service file at ${SERVICE_FILE_PATH}..."

# We pipe the output of cat to 'sudo tee' which handles the permission.
cat << EOF | sudo tee "${SERVICE_FILE_PATH}" > /dev/null
[Unit]
Description=Nintendo Pro Controller 2 Driver
After=network.target

[Service]
# Execute the installed binary with the --daemon flag
ExecStart=${INSTALL_PATH} --daemon
# Restart automatically if it crashes
Restart=always
RestartSec=5
# Run as root to access /dev/hidraw* and /dev/uinput
User=root
Group=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

if [ $? -ne 0 ]; then
    echo "❌ Failed to create service file. Aborting."
    exit 1
fi
echo "✅ Service file created."

# --- 4. Enable and Start the Service ---
echo "🚀 4. Reloading systemd, enabling, and starting service..."

# Reload the systemd daemon to pick up the new service file
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable "${SERVICE_NAME}.service"

# Start the service immediately
sudo systemctl start "${SERVICE_NAME}.service"

# Check the status
echo "--------------------------------------------------------"
sudo systemctl status "${SERVICE_NAME}.service" --no-pager
echo "--------------------------------------------------------"
echo "🎉 Deployment complete. Check live logs with: journalctl -u ${SERVICE_NAME}.service -f"