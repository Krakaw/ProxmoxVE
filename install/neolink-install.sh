#!/usr/bin/env bash

# Copyright (c) 2021-2025 Krakaw
# Author: Krakaw
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl sudo mc
$STD apt-get install -y libgstrtspserver-1.0-0 \
                          libgstreamer1.0-0 \
                          libgstreamer-plugins-bad1.0-0 \
                          gstreamer1.0-x \
                          gstreamer1.0-plugins-base \
                          gstreamer1.0-plugins-good \
                          gstreamer1.0-plugins-bad \
                          libssl3
msg_ok "Installed Dependencies"

msg_info "Downloading Neolink"
mkdir -p /opt/neolink
REPO_URL="https://api.github.com/repos/QuantumEntangledAndy/neolink/releases/latest"
DOWNLOAD_URL=$(curl -s ${REPO_URL} | grep -oP '"browser_download_url":\s*"\K[^"]+' | grep bullseye)
$STD curl -L -o /tmp/neolink.tar.gz "${DOWNLOAD_URL}"
$STD tar -xzf /tmp/neolink.tar.gz -C /opt/neolink --strip-components=1
$STD echo "${LATEST_VERSION}" > /opt/neolink/version
echo 'bind = "0.0.0.0"' > /opt/neolink/neolink.toml
msg_ok "Downloaded NeoLink"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/neolink.service
[Unit]
Description=Neolink
After=syslog.target network.target
[Service]
UMask=0002
Type=simple
ExecStart=/opt/neolink/neolink mqtt-rtsp --config=/opt/neolink/neolink.toml
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
systemctl -q daemon-reload
systemctl enable --now -q neolink
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
