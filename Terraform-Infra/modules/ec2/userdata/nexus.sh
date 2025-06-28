#!/bin/bash
set -e

# Variables
NEXUS_VERSION="3.80.0-06"
NEXUS_TAR="nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz"
NEXUS_URL="https://download.sonatype.com/nexus/3/${NEXUS_TAR}"
INSTALL_DIR="/opt/nexus"
DATA_DIR="/opt/sonatype-work"
NEXUS_USER="nexus"

# Install dependencies
sudo apt update
sudo apt install -y openjdk-17-jdk wget tar curl

# Create nexus user
sudo useradd -m -d /home/${NEXUS_USER} -s /bin/bash ${NEXUS_USER}

# Download and extract Nexus
cd /opt
sudo wget ${NEXUS_URL}
sudo tar -xvzf ${NEXUS_TAR}
sudo mv nexus-${NEXUS_VERSION} nexus
sudo rm -f ${NEXUS_TAR}
sudo chown -R ${NEXUS_USER}:${NEXUS_USER} nexus sonatype-work || true

# Configure Nexus to run as nexus user
echo "run_as_user=${NEXUS_USER}" | sudo tee ${INSTALL_DIR}/bin/nexus.rc

# Set permissions
sudo chown -R ${NEXUS_USER}:${NEXUS_USER} ${INSTALL_DIR} ${DATA_DIR}

# Create systemd service
sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=${NEXUS_USER}
Group=${NEXUS_USER}
ExecStart=${INSTALL_DIR}/bin/nexus start
ExecStop=${INSTALL_DIR}/bin/nexus stop
Restart=on-abort
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start Nexus
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

# Get IPs from AWS Metadata
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "NoPublicIP")
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 || echo "NoPrivateIP")

echo ""
echo "🎉 Nexus Repository installed successfully!"

PUBLIC_IP=$(curl -s ifconfig.me)
echo "🌍 Public access URL: http://${PUBLIC_IP}:8081"
echo ""
echo "⏳ Waiting for Nexus to generate the admin password..."

ADMIN_PASSWORD_FILE="/opt/sonatype-work/nexus3/admin.password"
TIMEOUT=120   # 2 minutes
WAIT=0

while [ ! -f "$ADMIN_PASSWORD_FILE" ] && [ $WAIT -lt $TIMEOUT ]; do
    sleep 5
    WAIT=$((WAIT + 5))
done

if [ -f "$ADMIN_PASSWORD_FILE" ]; then
    ADMIN_PASSWORD=$(sudo cat $ADMIN_PASSWORD_FILE)
else
    ADMIN_PASSWORD="(File not found after $TIMEOUT seconds - please check Nexus logs)"
fi

echo "🔑 Default credentials:"
echo "   Username: admin"
echo "   Password: $ADMIN_PASSWORD"
