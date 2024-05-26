#!/bin/bash

echo "Unattended Minecraft Java Installer"
sleep 2
# Change Mirror to MY for faster apt install
echo "Changing the default mirror from ru.archive.ubuntu.com to my.archive.ubuntu.com for faster apt download"
sleep 5
sed -i -e 's/ru.archive.ubuntu.com/my.archive.ubuntu.com/g' /etc/apt/sources.list
echo "running apt update"
sleep 5
apt-get update
sleep 5
# Install necessary tools
echo "installing necessary tools which is curl wget screen bash nano iftop iotop atop net-tools openjdk-21-jdk-headless required to run Minecraft java server 12.06"
apt-get install -y curl wget screen bash nano iftop iotop atop net-tools openjdk-21-jdk-headless
sleep 5
# Install OpenJDK 21
#curl -O https://download.oracle.com/java/21/archive/jdk-21.0.3_linux-x64_bin.tar.gz
#tar xzvf jdk-21.0.3_linux-x64_bin.tar.gz
#mv jdk-21.0.3 /opt/
#echo "export JAVA_HOME=/opt/jdk-21.0.3" >> /etc/profile.d/jdk21.sh
#echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile.d/jdk21.sh
#source /etc/profile.d/jdk21.sh

# Create Minecraft server user with bash as the default shell
echo "Create user mcserver"
useradd -m -s /bin/bash mcserver

# Set up Minecraft server version 1.20.6
echo "Create Minecraft data directory"
su -l mcserver -c "mkdir /home/mcserver/minecraft"
sleep 2
echo "Downloading Minecraft server from mojang"
su -l mcserver -c "cd /home/mcserver/minecraft && wget https://piston-data.mojang.com/v1/objects/145ff0858209bcfc164859ba735d4199aafa1eea/server.jar -O minecraft_server.jar"
echo "Minecraft Java Server downloaded to : /home/mcserver/minecraft/minecraft_server.jar"
sleep 2

echo "Create systemd server for the Minecraft server"
# Create the server start script
cat <<EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Server
After=network.target

[Service]
WorkingDirectory=/home/mcserver/minecraft

User=mcserver
Group=mcserver

Restart=always

ExecStart=/usr/bin/screen -DmS mc /usr/bin/java -Xmx2G -jar minecraft_server.jar nogui

ExecStop=/usr/bin/screen -p 0 -S mc -X eval 'stuff "say SERVER SHUTTING DOWN IN 15 SECONDS..."\015'
ExecStop=/bin/sleep 5
ExecStop=/usr/bin/screen -p 0 -S mc -X eval 'stuff "say SERVER SHUTTING DOWN IN 10 SECONDS..."\015'
ExecStop=/bin/sleep 5
ExecStop=/usr/bin/screen -p 0 -S mc -X eval 'stuff "say SERVER SHUTTING DOWN IN 5 SECONDS..."\015'
ExecStop=/bin/sleep 5
ExecStop=/usr/bin/screen -p 0 -S mc -X eval 'stuff "save-all"\015'
ExecStop=/usr/bin/screen -p 0 -S mc -X eval 'stuff "stop"\015'

[Install]
WantedBy=multi-user.target
EOF

echo "systemd service installed to : /etc/systemd/system/minecraft.service"
sleep 2

echo "Adjust and accept EULA inside eula.txt"

su -l mcserver -c "echo 'eula=true' > /home/mcserver/minecraft/eula.txt"

# Reload systemd manager configuration (reload all unit files so the new minecraft.service get recoginized by system)
echo "Reloading systemd.."
systemctl daemon-reload

echo "Enable minecraft.service, without starting it. It will start automatically at the next system restart, or it can be started manually, or as a dependency of another service."

systemctl enable minecraft.service

echo "Start minecraft.service"
systemctl start minecraft.service
sleep 2

# Setup Done
echo "Minecraft server setup completed."
sleep 2

echo "Reboot the server and login again by running : systemctl reboot"
