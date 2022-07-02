#!/usr/bin/env bash

set -o xtrace

PATH=$PATH:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin

TOP_DIR=$(cd $(dirname "$0") && pwd)

FILES=$TOP_DIR/files
if [ ! -d $FILES ]; then
    set +o xtrace
    echo "missing devstack/files"
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    set +o xtrace
    echo "DevStack should be run as a user with sudo permissions, "
    echo "not root."
    echo "A \"stack\" user configured correctly can be created with:"
    echo " $TOP_DIR/tools/create-stack-user.sh"
    exit 1
fi

# Import common functions
source $TOP_DIR/functions

# Import 'public' stack.sh functions
source $TOP_DIR/lib/stack

GetDistro


source $TOP_DIR/stackrc

# write /etc/devstack-version
write_devstack_version

SUPPORTED_DISTROS="bullseye|focal|jammy|f35|opensuse-15.2|opensuse-tumbleweed|rhel8|rhel9"

if [[ ! ${DISTRO} =~ $SUPPORTED_DISTROS ]]; then
    echo "WARNING: this script has not been tested on $DISTRO"
    if [[ "$FORCE" != "yes" ]]; then
        die 
    fi
fi

# Local Settings
# --------------

# Make sure the proxy config is visible to sub-processes

# Configure sudo
# ==============

# We're not as **root** so make sure ``sudo`` is available
is_package_installed sudo || is_package_installed sudo-ldap || install_package sudo

# UEC images ``/etc/sudoers`` does not have a ``#includedir``, add one
sudo grep -q "^#includedir.*/etc/sudoers.d" /etc/sudoers ||
    echo "#includedir /etc/sudoers.d" | sudo tee -a /etc/sudoers

TEMPFILE=`mktemp`
echo "All=(root) NOPASSWD:ALL" >$TEMPFILE

# Configure Target Directories
# ============================

# Destination path for installation ``DEST``
DEST=${DEST:-/opt/stack}

# Start Services
# ==============

# Dstat
# -----

# A better kind of sysstat, with the top process per time slice
start_dstat

# Run a background tcpdump for debugging
# Note: must set TCPDUMP_ARGS with the enabled service
if is_service_enabled tcpdump; then
    start_tcpdump
fi