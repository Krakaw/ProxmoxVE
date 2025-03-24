#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Generated by template generator
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

# Set up colors and formatting
YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
BGN=$(echo "\033[4;92m")
GN=$(echo "\033[1;92m")
DGN=$(echo "\033[32m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"

function msg_info() {
    local msg="$1"
    echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

# Header
clear
cat <<"EOF"
   ____                           __            
  / ___| ___ _ __   ___ _ __ __ _| |_ ___  _ __ 
 | |  _ / _ \ '_ \ / _ \ '__/ _` | __/ _ \| '__|
 | |_| |  __/ | | |  __/ | | (_| | || (_) | |   
  \____|\___|_| |_|\___|_|  \__,_|\__\___/|_|   
                                                 
EOF

echo -e "${BL}This script will help you generate a new app template for the community scripts project.${CL}\n"

# Get app information
read -p "Enter the app name (e.g., Nextcloud): " APP_NAME
read -p "Enter app source URL (GitHub repository): " SOURCE_URL
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter tags (max 2, separated by semicolon, e.g., database;web): " APP_TAGS
read -p "Enter required CPU cores (default: 2): " CPU_CORES
CPU_CORES=${CPU_CORES:-2}
read -p "Enter required RAM in MB (default: 2048): " RAM_SIZE
RAM_SIZE=${RAM_SIZE:-2048}
read -p "Enter required disk space in GB (default: 4): " DISK_SIZE
DISK_SIZE=${DISK_SIZE:-4}

# OS selection
echo -e "\nSelect OS:"
echo "1) Debian"
echo "2) Ubuntu"
echo "3) Alpine"
read -p "Enter choice (default: 1): " OS_CHOICE
case $OS_CHOICE in
    2) OS="ubuntu"
       OS_VERSION="22.04"
       ;;
    3) OS="alpine"
       OS_VERSION="3.20"
       ;;
    *) OS="debian"
       OS_VERSION="12"
       ;;
esac

read -p "Is this an unprivileged container? (Y/n): " UNPRIVILEGED
UNPRIVILEGED=${UNPRIVILEGED:-Y}
if [[ ${UNPRIVILEGED^^} == "Y" ]]; then
    UNPRIVILEGED="1"
else
    UNPRIVILEGED="0"
fi

# GitHub executable download information
read -p "Does this app have a pre-built executable on GitHub? (y/N): " HAS_EXECUTABLE
HAS_EXECUTABLE=${HAS_EXECUTABLE:-N}
if [[ ${HAS_EXECUTABLE^^} == "Y" ]]; then
    read -p "Enter GitHub repository owner: " GITHUB_OWNER
    read -p "Enter GitHub repository name: " GITHUB_REPO
    read -p "Enter executable filename pattern (e.g., appname_VERSION_linux_amd64.deb): " EXECUTABLE_PATTERN
    read -p "Enter default port: " DEFAULT_PORT
    DEFAULT_PORT=${DEFAULT_PORT:-80}
fi

# Create directories if they don't exist
msg_info "Creating directory structure"
mkdir -p ct install
msg_ok "Created directory structure"

# Convert app name to lowercase and remove spaces for filenames
APP_FILENAME=$(echo "${APP_NAME}" | tr '[:upper:]' '[:lower:]' | tr -d ' ')

# Generate ct/AppName.sh
msg_info "Generating container template"
cat > "ct/${APP_FILENAME}.sh" << EOF
#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: ${GITHUB_USERNAME}
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: ${SOURCE_URL}

# App Default Values
APP="${APP_NAME}"
var_tags="${APP_TAGS}"
var_cpu="${CPU_CORES}"
var_ram="${RAM_SIZE}"
var_disk="${DISK_SIZE}"
var_os="${OS}"
var_version="${OS_VERSION}"
var_unprivileged="${UNPRIVILEGED}"

header_info "\$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    if [[ ! -f /opt/\${APP}_version.txt ]]; then
        msg_error "No \${APP} Installation Found!"
        exit
    fi

    RELEASE=\$(curl -s https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest | grep "tag_name" | awk '{print substr(\$2, 2, length(\$2)-3) }')
    if [[ "\${RELEASE}" != "\$(cat /opt/\${APP}_version.txt)" ]]; then
        msg_info "Stopping Service"
        systemctl stop \${APP,,}
        msg_ok "Stopped Service"

        msg_info "Updating \${APP} to v\${RELEASE}"
        wget -q "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/\${RELEASE}/${EXECUTABLE_PATTERN/\${VERSION}/\${RELEASE}}"
        \$STD dpkg -i "${EXECUTABLE_PATTERN/\${VERSION}/\${RELEASE}}"
        rm -f "${EXECUTABLE_PATTERN/\${VERSION}/\${RELEASE}}"
        echo "\${RELEASE}" >"/opt/\${APP}_version.txt"
        msg_ok "Updated \${APP} to v\${RELEASE}"

        msg_info "Starting Service"
        systemctl start \${APP,,}
        msg_ok "Started Service"
    else
        msg_ok "No update required. \${APP} is already at v\${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "\${CREATING}\${GN}\${APP} setup has been successfully initialized!\${CL}"
echo -e "\${INFO}\${YW} Access it using the following URL:\${CL}"
echo -e "\${TAB}\${GATEWAY}\${BGN}http://\${IP}:${DEFAULT_PORT}\${CL}"
EOF
msg_ok "Generated container template"

# Generate install/AppName-install.sh
msg_info "Generating installation script"
cat > "install/${APP_FILENAME}-install.sh" << EOF
#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: ${GITHUB_USERNAME}
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: ${SOURCE_URL}

source /dev/stdin <<< "\$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
\$STD apt-get install -y \\
    curl \\
    sudo \\
    mc
msg_ok "Installed Dependencies"

msg_info "Installing \${APPLICATION}"
RELEASE=\$(curl -s https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest | grep "tag_name" | awk '{print substr(\$2, 2, length(\$2)-3) }')
wget -q "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/releases/download/\${RELEASE}/${EXECUTABLE_PATTERN/\${VERSION}/\${RELEASE}}"
\$STD dpkg -i "${EXECUTABLE_PATTERN/\${VERSION}/\${RELEASE}}"
msg_ok "Install \${APPLICATION} completed"

msg_info "Creating Service"
cat <<EOT >/etc/systemd/system/\${APPLICATION,,}.service
[Unit]
Description=\${APPLICATION} Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/\${APPLICATION,,}
Restart=always

[Install]
WantedBy=multi-user.target
EOT
systemctl enable -q --now \${APPLICATION,,}
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f "${EXECUTABLE_PATTERN/\${VERSION}/\${RELEASE}}"
\$STD apt-get -y autoremove
\$STD apt-get -y autoclean
msg_ok "Cleaned"
EOF
msg_ok "Generated installation script"

# Make scripts executable
msg_info "Setting permissions"
chmod +x "ct/${APP_FILENAME}.sh" "install/${APP_FILENAME}-install.sh"
msg_ok "Set permissions"

echo -e "\n${GN}Successfully generated app templates!${CL}"
echo -e "\nNext steps:"
echo -e "1. Edit ${BL}ct/${APP_FILENAME}.sh${CL} to customize the container creation"
echo -e "2. Edit ${BL}install/${APP_FILENAME}-install.sh${CL} to implement the installation logic"
echo -e "3. Test your scripts in a development environment"
echo -e "4. Submit a pull request to the community scripts repository" 