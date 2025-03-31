#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Krakaw
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pyload/pyload

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    curl \
    sudo \
    mc
msg_ok "Installed Dependencies"

msg_info "Installing ${APPLICATION}"
RELEASE=$(curl -s https://api.github.com/repos/pyload/pyload/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
pip install --pre pyload-ng[all]
msg_ok "Install ${APPLICATION} completed"

msg_info "Creating Service"
cat <<EOT >/etc/systemd/system/${APPLICATION,,}.service
[Unit]
Description=${APPLICATION} Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/pyload --daemon --storagedir=/mnt/pyload
Restart=always

[Install]
WantedBy=multi-user.target
EOT
systemctl enable -q --now ${APPLICATION,,}
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "/${RELEASE}}"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
