#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/Krakaw/ProxmoxVE/refs/heads/pyload/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Krakaw
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/pyload/pyload

# App Default Values
APP="pyload"
var_tags="download;remote download"
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

    RELEASE=$(curl -s https://api.github.com/repos/pyload/pyload/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
        msg_info "Stopping Service"
        systemctl stop ${APP,,}
        msg_ok "Stopped Service"

        msg_info "Updating ${APP} to v${RELEASE}"
        $STD pip install --upgrade pip
        $STD pip install --pre pyload-ng[all]
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
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
