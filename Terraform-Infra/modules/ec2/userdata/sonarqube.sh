#!/bin/bash

# Exit on any error
set -e

# Variables
SONAR_USER="sonar"
#SONAR_VERSION="10.5.1.90531"
SONAR_VERSION="25.6.0.109173"
SONAR_ZIP="sonarqube-${SONAR_VERSION}.zip"
SONAR_DIR="/opt/sonarqube"
DB_NAME="sonarqube"
DB_USER="sonar"
DB_PASSWORD="StrongSonarPass123"

# Update system
sudo apt update && sudo apt install -y openjdk-17-jdk unzip wget postgresql

# Create sonar user
sudo useradd -m -d /home/$SONAR_USER -s /bin/bash $SONAR_USER

# Configure PostgreSQL
sudo -u postgres psql <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
EOF

# Download and extract SonarQube
cd /opt
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/${SONAR_ZIP}
sudo unzip ${SONAR_ZIP}
sudo mv sonarqube-${SONAR_VERSION} sonarqube
sudo chown -R $SONAR_USER:$SONAR_USER $SONAR_DIR
sudo rm -f ${SONAR_ZIP}

# Configure SonarQube DB credentials
sudo sed -i "s|^#sonar.jdbc.username=.*|sonar.jdbc.username=${DB_USER}|" ${SONAR_DIR}/conf/sonar.properties
sudo sed -i "s|^#sonar.jdbc.password=.*|sonar.jdbc.password=${DB_PASSWORD}|" ${SONAR_DIR}/conf/sonar.properties
sudo sed -i "s|^#sonar.jdbc.url=.*|sonar.jdbc.url=jdbc:postgresql://localhost/${DB_NAME}|" ${SONAR_DIR}/conf/sonar.properties

# Create systemd service
sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOF
[Unit]
Description=SonarQube service
After=network.target postgresql.service

[Service]
Type=simple
User=${SONAR_USER}
Group=${SONAR_USER}
ExecStart=${SONAR_DIR}/bin/linux-x86-64/sonar.sh start
ExecStop=${SONAR_DIR}/bin/linux-x86-64/sonar.sh stop
RemainAfterExit=yes
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload and start service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

echo "🎉 SonarQube installation complete!"
PUBLIC_IP=$(curl -s ifconfig.me)
echo "🌍 Public access URL: http://${PUBLIC_IP}:9000"
