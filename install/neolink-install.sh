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
$STD apt-get install -y curl sudo git mc
$STD apt-get install -y libgstrtspserver-1.0-0 \
                          libgstreamer1.0-0 \
                          libgstreamer-plugins-bad1.0-0 \
                          gstreamer1.0-x \
                          gstreamer1.0-plugins-base \
                          gstreamer1.0-plugins-good \
                          gstreamer1.0-plugins-bad \
                          libssl
msg_ok "Installed Dependencies"

msg_info "Cloning Neolink"
cd /opt
$STD git clone https://github.com/QuantumEntangledAndy/neolink.git -b master neolink
cd neolink
echo 'bind = "0.0.0.0"' > neolink.toml
msg_ok "Cloned NeoLink"

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
