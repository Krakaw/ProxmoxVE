#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/Krakaw/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: Krakaw
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/QuantumEntangledAndy/neolink

APP="Neolink"
TAGS="dvr"
var_cpu="4"
var_ram="4096"
var_disk="6"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    APP="Neolink"
    REPO_URL="https://api.github.com/repos/QuantumEntangledAndy/neolink/releases/latest"

    # Check if installation is present | -f for file, -d for folder
    if [[ ! -d /opt/neolink ]]; then
        echo "No ${APP} Installation Found!"
        exit 1
    fi

    # Check if neolink command is available
    if ! command -v neolink &> /dev/null; then
        echo "Neolink command not found!"
        exit 1
    fi

    # Get installed version using neolink --version
    INSTALLED_VERSION=$(RUST_LOG=error neolink --version | awk '{print $2}')
    echo "Installed version: ${INSTALLED_VERSION}"

    # Get the latest version from GitHub API
    LATEST_VERSION=$(curl -s ${REPO_URL} | grep -oP '"tag_name":\s*"\K[^"]+')
    if [[ -z "${LATEST_VERSION}" ]]; then
        echo "Unable to fetch the latest version from GitHub."
        exit 1
    fi
    echo "Latest version: ${LATEST_VERSION}"

    # Compare versions
    if [[ "${INSTALLED_VERSION}" != "${LATEST_VERSION}" ]]; then
        echo "Update available: ${LATEST_VERSION}. Installed version: ${INSTALLED_VERSION}."
        # Prompt for update or automate
        read -p "Do you want to update to ${LATEST_VERSION}? (y/n): " CONFIRM
        if [[ "${CONFIRM}" == "y" ]]; then
            echo "Updating to ${LATEST_VERSION}..."
            # Add update commands here
            # Example: Download and extract the latest release
            DOWNLOAD_URL=$(curl -s ${REPO_URL} | grep -oP '"browser_download_url":\s*"\K[^"]+' | grep bullseye)
            curl -L -o /tmp/neolink.tar.gz "${DOWNLOAD_URL}"
            tar -xzf /tmp/neolink.tar.gz -C /opt/neolink --strip-components=1
            echo "${LATEST_VERSION}" > /opt/neolink/version
            rm /tmp/neolink.tar.gz
            echo "Update complete!"
        else
            echo "Update skipped."
        fi
    else
        echo "You are already running the latest version (${INSTALLED_VERSION})."
    fi

    exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8554${CL}"
