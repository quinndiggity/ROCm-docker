#!/bin/bash
# #################################################
# Copyright (c) 2017 Advanced Micro Devices, Inc.
# #################################################
# Author: Paul Fultz II

set -e

apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl bzip2 apt-utils wget

function add_repo {
    sh -c "echo deb [arch=amd64] $1 xenial main > /etc/apt/sources.list.d/rocm.list"
}

function add_local_repo {
    sh -c "echo deb [trusted=yes] file://$1 xenial main > /etc/apt/sources.list.d/rocm.list"
}

function download_repo {
    mkdir -p /repo/tmp
    curl $1 | tar --strip-components=1 -x --bzip2 -C /repo/tmp
    # Some archives are in a debian directory
    if [ -d "/repo/tmp/debian" ]; then
        mv /repo/tmp /repo/radeon
    else
        mkdir -p /repo/radeon
        mv /repo/tmp /repo/radeon/debian
    fi
    cat /repo/radeon/debian/rocm.gpg.key | apt-key add -
    add_local_repo /repo/radeon/debian
}

if uname -r | grep -q 'rocm'; then
    KERNEL_VERSION=$(uname -r | sed 's/.*rocm-rel-//g')
    KERNEL_PATCH_VERSION=$(echo $KERNEL_VERSION | sed 's/.*-//g')
    ROCM_VERSION=$(echo $KERNEL_VERSION | sed 's/-.*//g')

    if [ "$ROCM_VERSION" == "1.4" ]
    then
        download_repo http://repo.radeon.com/rocm/archive/apt_1.4.0.tar.bz2
    elif [ "$ROCM_VERSION" == "1.5" ]
    then
        download_repo http://repo.radeon.com/rocm/archive/apt_1.5.1.tar.bz2
    elif [ "$ROCM_VERSION" == "1.6" ] && [ "$KERNEL_PATCH_VERSION" == "77" ]
    then
        download_repo http://repo.radeon.com/rocm/archive/apt_1.6.0.tar.bz2
    elif [ "$ROCM_VERSION" == "1.6" ] # Latest patch version is 180
    then
        download_repo http://repo.radeon.com/rocm/archive/apt_1.6.4.tar.bz2
    else
        add_repo http://repo.radeon.com/rocm/apt/debian/
    fi

else
    KERNEL_VERSION=$(cat /sys/module/amdkfd/version)
    KERNEL_SRC_VERSION=$(cat /sys/module/amdkfd/srcversion)
    if [ "$KERNEL_VERSION" == "2.0.0" ]
    then
        download_repo http://repo.radeon.com/rocm/archive/apt_1.7.2.tar.bz2
    else
        add_repo http://repo.radeon.com/rocm/apt/debian/
    fi

fi

# Install key
wget -O - http://repo.radeon.com/rocm/apt/debian/rocm.gpg.key | apt-key add -
apt-get update
