#!/usr/bin/env bash

if [ $EUID -ne 0 ]; then
    echo "ERROR: Must be run as root"
    exit 1
fi

HAS_SYSTEMD=$(ps --no-headers -o comm 1)
if [ "${HAS_SYSTEMD}" != 'systemd' ]; then
    echo "This install script only supports systemd"
    echo "Please install systemd or manually create the service using your systems's service manager"
    exit 1
fi

if [[ $DISPLAY ]]; then
    echo "ERROR: Display detected. Installer only supports running headless, i.e from ssh."
    echo "If you cannot ssh in then please run 'sudo systemctl isolate multi-user.target' to switch to a non-graphical user session and run the installer again."
    echo "If you are already running headless, then you are probably running with X forwarding which is setting DISPLAY, if so then simply run"
    echo "unset DISPLAY"
    echo "to unset the variable and then try running the installer again"
    exit 1
fi

DEBUG=0
NOMESH=0

IGNOREZOHOASSIST=1
ZOHOAGENT=''

agentDL='https://agentsw.faveodemo.com/api/agent/download/?platform=linux&architecture=amd64'
meshDL='https://k3d.faveodemo.com/meshagents?id=2UWY3pA$$JjTYUbmOp0tJuWfpzq@wuTdv7boaVBgnIqfp5DXtv3m0CsJuIa5dQzb&installflags=2&meshinstall=6'

agentDL='https://agentsw.faveodemo.com/api/agent/download/?platform=linux&architecture=amd64'
apiURL='https://agentsw.faveodemo.com'
token='KEmZbpNl7u1C89HQuS1wwhafxhTJ8ej1HnOnehRvf7h2sVzpAYk4sEcSCpfm'
clientID='1'
siteID='1'
assetTypeId=34

agentBinPath='/usr/local/bin'
binName='faveoagent'
agentBin="${agentBinPath}/${binName}"
agentConf='/etc/faveoagent'
agentSvcName='faveoagent.service'
agentSysD="/etc/systemd/system/${agentSvcName}"
agentDir='/opt/faveoagent'

meshDir='/opt/faveomesh'
meshSystemBin="${meshDir}/meshagent"
meshSvcName='meshagent.service'
meshSysD="/lib/systemd/system/${meshSvcName}"

deb=(ubuntu debian raspbian kali linuxmint)
rhe=(fedora rocky centos rhel amzn arch opensuse)

set_locale_deb() {
    locale-gen "en_US.UTF-8"
    localectl set-locale LANG=en_US.UTF-8
    . /etc/default/locale
}

set_locale_rhel() {
    localedef -c -i en_US -f UTF-8 en_US.UTF-8 >/dev/null 2>&1
    localectl set-locale LANG=en_US.UTF-8
    . /etc/locale.conf
}

RemoveOldAgent() {
    if [ -f "${agentSysD}" ]; then
        systemctl disable ${agentSvcName}
        systemctl stop ${agentSvcName}
        rm -f "${agentSysD}"
        systemctl daemon-reload
    fi

    if [ -f "${agentConf}" ]; then
        rm -f "${agentConf}"
    fi

    if [ -f "${agentBin}" ]; then
        rm -f "${agentBin}"
    fi

    if [ -d "${agentDir}" ]; then
        rm -rf "${agentDir}"
    fi
}


InstallMesh() {
    if [ -f /etc/os-release ]; then
        distroID=$(
            . /etc/os-release
            echo $ID
        )
        distroIDLIKE=$(
            . /etc/os-release
            echo $ID_LIKE
        )
        if [[ " ${deb[*]} " =~ " ${distroID} " ]]; then
            set_locale_deb
        elif [[ " ${deb[*]} " =~ " ${distroIDLIKE} " ]]; then
            set_locale_deb
        elif [[ " ${rhe[*]} " =~ " ${distroID} " ]]; then
            set_locale_rhel
        else
            set_locale_rhel
        fi
    fi

    meshTmpDir='/root/meshtemp'
    mkdir -p $meshTmpDir

    meshTmpBin="${meshTmpDir}/meshagent"
    wget --no-check-certificate -q -O ${meshTmpBin} ${meshDL}
    chmod +x ${meshTmpBin}
    mkdir -p ${meshDir}
    env LC_ALL=en_US.UTF-8 LANGUAGE=en_US XAUTHORITY=foo DISPLAY=bar ${meshTmpBin} -install --installPath=${meshDir}
    sleep 1
    rm -rf ${meshTmpDir}
}

RemoveMesh() {
    if [ -f "${meshSystemBin}" ]; then
        env XAUTHORITY=foo DISPLAY=bar ${meshSystemBin} -uninstall
        sleep 1
    fi

    if [ -f "${meshSysD}" ]; then
        systemctl stop ${meshSvcName} >/dev/null 2>&1
        systemctl disable ${meshSvcName} >/dev/null 2>&1
        rm -f ${meshSysD}
    fi

    rm -rf ${meshDir}
    systemctl daemon-reload
}

Uninstall() {
    RemoveOldAgent
    RemoveMesh
}

RemoveZoho() {
    echo "========== Uninstalling Zoho Assist Unattended Agent =========="

    SERVICE="ZohoAssistUrs"
    PKG="zohoassist"
    INSTALL_DIR="/usr/local/ZohoAssist"
    SERVICE_FILE="/etc/systemd/system/${SERVICE}.service"
    DPKG_INFO_DIR="/var/lib/dpkg/info"

    echo "[1/6] Stopping Zoho Assist service..."
    sudo systemctl stop "$SERVICE" >/dev/null 2>&1
    sudo systemctl disable "$SERVICE" >/dev/null 2>&1

    echo "[2/6] Removing systemd service file..."
    if [[ -f "$SERVICE_FILE" ]]; then
        sudo rm -f "$SERVICE_FILE"
        sudo systemctl daemon-reload
    fi

    echo "[3/6] Deleting installation directory..."
    if [[ -d "$INSTALL_DIR" ]]; then
        sudo rm -rf "$INSTALL_DIR"
    fi

    echo "[4/6] Removing dpkg package scripts (fix broken postrm errors)..."
    sudo rm -f "${DPKG_INFO_DIR}/${PKG}.postrm"
    sudo rm -f "${DPKG_INFO_DIR}/${PKG}.prerm"
    sudo rm -f "${DPKG_INFO_DIR}/${PKG}.postinst"
    sudo rm -f "${DPKG_INFO_DIR}/${PKG}.preinst"

    echo "[5/6] Removing dpkg package entry (force if broken)..."
    if dpkg -l | grep -qi "$PKG"; then
        sudo dpkg --remove --force-remove-reinstreq "$PKG" >/dev/null 2>&1
        sudo dpkg --purge --force-all "$PKG" >/dev/null 2>&1
    fi

    echo "[6/6] Cleaning log and temp files..."
    sudo rm -rf /var/log/zohoassist* >/dev/null 2>&1
    sudo rm -rf /tmp/za* >/dev/null 2>&1

    echo "========== Zoho Assist Unattended Agent Uninstalled Successfully =========="
}

if [ $# -ne 0 ] && [[ $1 =~ ^(uninstall|-uninstall|--uninstall)$ ]]; then
    Uninstall
    # Remove the current script
    rm "$0"
    exit 0
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -debug | --debug | debug) DEBUG=1 ;;
    -insecure | --insecure | insecure) INSECURE=1 ;;
    *)
        echo "ERROR: Unknown parameter: $1"
        exit 1
        ;;
    esac
    shift
done

RemoveOldAgent

echo "Downloading faveo agent..."
wget -q -O ${agentBin} "${agentDL}"
if [ $? -ne 0 ]; then
    echo "ERROR: Unable to download faveo agent"
    exit 1
fi
chmod +x ${agentBin}


MESH_NODE_ID=""

if [[ $NOMESH -eq 1 ]]; then
    echo "Skipping mesh install"
else

    meshSystemBin="/opt/faveomesh/meshagent"

    if [ -f "${meshSystemBin}" ]; then
        RemoveMesh
    fi
    echo "Downloading and Installing Faveo Mesh Agent..."
    InstallMesh
    sleep 5
fi


if [ ! -d "${agentBinPath}" ]; then
    echo "Creating ${agentBinPath}"
    mkdir -p ${agentBinPath}
fi

INSTALL_CMD="${agentBin} -m install -api ${apiURL} -client-id ${clientID} -site-id ${siteID} -asset_type_id ${assetTypeId} -auth ${token} "

if [[ $DEBUG -eq 1 ]]; then
    INSTALL_CMD+=" --log debug"
fi

if [[ $NOMESH -eq 1 ]]; then
    INSTALL_CMD+=" -nomesh"
fi

if [[ "$IGNOREZOHOASSIST" == "1" ]]; then
    INSTALL_CMD+=" -with_zoho=0"
else
    INSTALL_CMD+=" -with_zoho=1"
fi


eval ${INSTALL_CMD}

faveosvc="$(
    cat <<EOF
[Unit]
Description=Faveo Linux Agent

[Service]
Type=simple
ExecStart=${agentBin} -m svc
User=root
Group=root
Restart=always
RestartSec=5s
LimitNOFILE=1000000
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
)"
echo "${faveosvc}" | tee ${agentSysD} >/dev/null

systemctl daemon-reload
systemctl enable ${agentSvcName}
systemctl start ${agentSvcName}

${agentBin} -m recovermesh


if [[ "${IGNOREZOHOASSIST}" == "1" ]]; then
    echo "Skipping Zoho Assist installation"
else

    RemoveZoho

    echo "Installing Zoho Agent"

    # Ensure URL is not empty
    if [[ -z "${ZOHOAGENT}" ]]; then
        echo "Error: ZOHO AGENT URL is empty"
        exit 1
    fi

    echo "Downloading Zoho Assist Agent from: ${ZOHOAGENT}"
    if ! wget -q --show-progress "${ZOHOAGENT}" -O zoho_agent.deb; then
        echo "Download failed!"
        exit 1
    fi

    # Detect Debian/Ubuntu system
    if command -v dpkg >/dev/null 2>&1; then
        echo "Detected Debian/Ubuntu system"
        if ! sudo dpkg -i zoho_agent.deb >dpkg.log 2>&1; then
            echo "dpkg failed (see dpkg.log)"
            exit 1
        fi
    else
        echo "Detected non-Debian system (RPM / others)"

        if [[ -f "zohoassist_1.0.0.1.zip" ]]; then
             unzip zohoassist_1.0.0.1.zip
             chmod +x install.bin
             sudo ./install.bin
        else
             echo "Error: zohoassist_1.0.0.1.zip not found"
             exit 1
       fi
    fi
fi

echo -e "\e[32m Installation Completed Successfully \e[0m"

