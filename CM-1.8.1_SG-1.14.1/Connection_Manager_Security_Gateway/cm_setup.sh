#!/bin/bash

# Copyright 2015 Teradici Corporation
# All Rights Reserved
# No portions of this material may be reproduced in any form without the
# written permission of Teradici Corporation.  All information contained
# in this document is Teradici Corporation company private, proprietary,
# and trade secret.

set -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PRODUCT_VERSION=1.8.1
CM_SG_PRODUCT_VERSION=$PRODUCT_VERSION
RDWA_ADAPTOR_PRODUCT_VERSION=$PRODUCT_VERSION
THIRDPARTY_PRODUCT_VERSION=$PRODUCT_VERSION

# verify checksum of a file
verify_checksum() {
    local FILENAME=$1
    local TYPE=$2
    local EXPECTED_CHECKSUM=$3

    echo "$EXPECTED_CHECKSUM *$FILENAME" > $FILENAME.$TYPE
    ${TYPE}sum -c --status ${FILENAME}.${TYPE}
	if [ "$?" -ne "0" ]; then
		echo "[ERROR] Checksum mismatch for ${FILENAME}!"
		exit 1
	fi
    rm -f $FILENAME.$TYPE
}

echo -e "Installing necessary dependencies that are available through yum install."

# These packages will be skipped if they have already been installed
yum -y install gcc
yum -y install redhat-lsb
yum -y install java-1.8.0-openjdk.x86_64

echo -e "Checking system default Java version ..."
SUPPORTED_JAVA_VERSION="1.8."
FOUND_JAVA=0
if type -p java >/dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo -e "System default Java version is $JAVA_VERSION."
    if [[ "$JAVA_VERSION" == "$SUPPORTED_JAVA_VERSION"* ]]; then
        echo -e "System default Java is supported."
        FOUND_JAVA=1
    else
        echo -e "ERROR: System default Java is not supported."
    fi
    
else
    echo -e "ERROR: Failed to find Java."
fi

if [ "$FOUND_JAVA" -ne 1 ]; then
    echo -e "Please set your system default Java to version 1.8."
    # Exit the script if system default Java is not the version we supported
    exit 1
fi

echo -e "Downloading and installing authbind."
curl -Of -# http://ftp.debian.org/debian/pool/main/a/authbind/authbind_2.1.1.tar.gz
verify_checksum authbind_2.1.1.tar.gz sha1 9b1adbb6be86a77d751c20a7f84b7decc8669e61
tar -xzf authbind_2.1.1.tar.gz
cd authbind-2.1.1
make
make install
cd ..
rm -f authbind_2.1.1.tar.gz
rm -rf authbind-2.1.1

echo -e "Installing Connection Manager Third Party Dependencies RPM"
yum -y install $DIR/cm_third_party_dependencies-$THIRDPARTY_PRODUCT_VERSION*.rpm

echo -e "Installting Teradici PCoIP Connection Manager and Security Gateway"
yum -y install $DIR/cm_sg-$CM_SG_PRODUCT_VERSION*.rpm

echo -e "Configuring authbind to allow Connection Manager to run on port 443"
touch /etc/authbind/byport/443
chmod 500 /etc/authbind/byport/443
chown connection_manager /etc/authbind/byport/443

if [ -f $DIR/rdwa_adaptor-$RDWA_ADAPTOR_PRODUCT_VERSION*.rpm ]; then
    echo -e "Installting Teradici RDWA Adaptor"
    yum -y install $DIR/rdwa_adaptor-$RDWA_ADAPTOR_PRODUCT_VERSION*.rpm
elif [ -f $DIR/rdwa_adaptor-*.rpm ]; then
    echo -e "Installting Teradici RDWA Adaptor"
    echo -e "Warning: installing older version of RPM"
    rpm_file=($DIR/rdwa_adaptor-*.rpm)
    rpm -Uvh --nodeps $rpm_file
#else
    # RDWA Adaptor is no longer supported - just silently continue if its .rpm is not available.
fi

echo -e "Installation finished. Please update configuration in /etc/ConnectionManager.conf"
echo -e "and /etc/SecurityGateway.conf as described in the product"
echo -e "documentation, then start the components as follows:"
echo -e "   /opt/Teradici/Management/bin/restart_components.sh start"
