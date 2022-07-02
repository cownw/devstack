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

# Database Configuration
# ----------------------

# To select between database backends, add the following to ``local.conf``:
#
#    disable_service mysql
#    enable_service postgresql
#
# The available database backends are listed in ``DATABASE_BACKENDS`` after
# ``lib/database`` is sourced. ``mysql`` is the default.

if 

if is_service_enabled mysql; then

fi

# Using the cloud
# ===============

echo ""
echo ""
echo ""
echo "This is your host IP address: $HOST_IP"
if [ "$HOST_IPV6" != "" ]; then
    echo "This is your host IPv6 address: $HOST_IPV6"
fi

# If you installed Horizon on this server you should be able
# to access the site using your browser.
if is_service_enabled horizon; then
    echo "Horizon is now available at http://$SERVICE_HOST$HORIZON_APACHE_ROOT"
fi

# If Keystone is present you can point ``nova`` cli to this server
if is_service_enabled keystone; then
    echo "Keystone is serving at $KEYSTONE_SERVICE_URI/"
    echo "The default users are: admin and demo"
    echo "The password: $ADMIN_PASSWORD"
fi

# Warn that a deprecated feature was used
if [[ -n "$DEPRECATED_TEXT" ]]; then
    echo
    echo -e "WARNING: $DEPRECATED_TEXT"
    echo
fi

echo
echo "Services are running under systemd unit files."
echo "For more information see: "
echo "https://docs.openstack.org/devstack/latest/systemd.html"
echo

# Useful info on current state
cat /etc/devstack-version
echo

# Indicate how long this took to run (bash maintained variable ``SECONDS``)
echo_summary "stack.sh completed in $SECONDS seconds."

# Restore/close logging file descriptors
exec 1>&3
exec 2>&3
exec 3>&-
exec 6>&-
