#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Krakaw
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lovelaze/nebula-sync

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
    wget \
    sudo \
    mc
msg_ok "Installed Dependencies"

msg_info "Installing ${APPLICATION}"
RELEASE=$(curl -s https://api.github.com/repos/lovelaze/nebula-sync/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')

wget -q "https://github.com/lovelaze/nebula-sync/releases/download/v${RELEASE}/nebula-sync_${RELEASE}_linux_amd64.tar.gz" -O "/tmp/nebula-sync_${RELEASE}_linux_amd64.tar.gz"
$STD tar -C /tmp -xzvf "/tmp/nebula-sync_${RELEASE}_linux_amd64.tar.gz" 
$STD mv /tmp/nebula-sync "/usr/bin/"
msg_ok "Install ${APPLICATION} completed"

msg_info "Creating Service"
cat <<EOT >"/etc/systemd/system/nebula-sync.service"
[Unit]
Description=${APPLICATION} Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/nebula-sync run --env-file /etc/nebula-sync.env
Restart=always

[Install]
WantedBy=multi-user.target
EOT
systemctl enable -q --now nebula-sync
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "/tmp/nebula-sync_${RELEASE}_linux_amd64.tar.gz"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

msg_info "Generating ${APPLICATION} Configuration"
cat <<EOT >"/etc/nebula-sync.env"
PRIMARY=http://ph1.example.com|password
REPLICAS=http://ph2.example.com|password
FULL_SYNC=false
RUN_GRAVITY=true
CRON=0 * * * *

SYNC_CONFIG_DNS=true
SYNC_CONFIG_DHCP=true
SYNC_CONFIG_NTP=true
SYNC_CONFIG_RESOLVER=true
SYNC_CONFIG_DATABASE=true
SYNC_CONFIG_MISC=true
SYNC_CONFIG_DEBUG=true

SYNC_GRAVITY_DHCP_LEASES=true
SYNC_GRAVITY_GROUP=true
SYNC_GRAVITY_AD_LIST=true
SYNC_GRAVITY_AD_LIST_BY_GROUP=true
SYNC_GRAVITY_DOMAIN_LIST=true
SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP=true
SYNC_GRAVITY_CLIENT=true
SYNC_GRAVITY_CLIENT_BY_GROUP=true
EOT
msg_ok "Generated ${APPLICATION} Configuration ${GREEN} /etc/nebula-sync.env ${CL}"

