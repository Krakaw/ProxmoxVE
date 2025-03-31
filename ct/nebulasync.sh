#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/Krakaw/ProxmoxVE/refs/heads/nebula-sync/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Krakaw
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lovelaze/nebula-sync

# App Default Values
APP="Nebula Sync"
var_tags="dns;pihole"
var_cpu="1"
var_ram="512"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -s https://api.github.com/repos/lovelaze/nebula-sync/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_info "Stopping Service"
        systemctl stop ${APP,,}
        msg_ok "Stopped Service"

        msg_info "Updating ${APP} to v${RELEASE}"
        wget -q "https://github.com/lovelaze/nebula-sync/releases/download/v${RELEASE}/nebula-sync_${RELEASE}_linux_amd64.tar.gz" -O "/tmp/nebula-sync_${RELEASE}_linux_amd64.tar.gz"
        $STD tar -C /tmp -xzvf "/tmp/nebula-sync_${RELEASE}_linux_amd64.tar.gz" 
        $STD mv /tmp/nebula-sync "/usr/bin/${APPLICATION,,}"
        rm -f "/tmp/nebula-sync_${RELEASE}_linux_amd64.tar.gz"
        echo "${RELEASE}" >"/opt/${APP}_version.txt"
        msg_ok "Updated ${APP} to v${RELEASE}"

        msg_info "Starting Service"
        systemctl start ${APP,,}
        msg_ok "Started Service"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
