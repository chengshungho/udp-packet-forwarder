#!/bin/bash

set -e

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------

COLOR_INFO="\e[32m" # green
COLOR_WARNING="\e[33m" # yellow
COLOR_ERROR="\e[31m" # red
COLOR_END="\e[0m"

# -----------------------------------------------------------------------------
# Tools
# -----------------------------------------------------------------------------

clone_and_patch() {

    URL=$1
    TAG=$2
    FOLDER=$( echo ${URL##*/} | sed 's/\.git//' )

    # Clone
    if [[ ! -d $FOLDER ]]; then
        git clone -b ${TAG} $URL $FOLDER
        pushd $FOLDER >> /dev/null
    else
        pushd $FOLDER >> /dev/null
        git checkout -- .
        git clean -d -x -f
        git checkout ${TAG}
    fi

    # Apply patches
    if [ -f ../patches/$FOLDER.$TAG.patch ]; then
        echo -e "${COLOR_INFO}Applying $FOLDER.$TAG.patch ...${COLOR_END}"
        git apply ../patches/$FOLDER.$TAG.patch
    fi

    popd >> /dev/null

}


clone_patch_and_make() {

    URL=$1
    TAG=$2
    FOLDER=$( echo ${URL##*/} | sed 's/\.git//' )

    clone_and_patch $URL $TAG
    
    pushd $FOLDER >> /dev/null
    make clean all
    popd >> /dev/null

}

print_header() {

    TITLE=$1
    echo -e "${COLOR_INFO}-------------------------------------------------------${COLOR_END}"
    echo -e "${COLOR_INFO}$TITLE${COLOR_END}"
    echo -e "${COLOR_INFO}-------------------------------------------------------${COLOR_END}"

}

# -----------------------------------------------------------------------------
# Building libmpsse for FTDI access
# -----------------------------------------------------------------------------

print_header "Building LIBMPSSE"
clone_and_patch https://github.com/devttys0/libmpsse.git master
pushd libmpsse/src >> /dev/null
./configure --disable-python
make clean all install
ldconfig
popd > /dev/null

# -----------------------------------------------------------------------------
# Building packet forwarder for V2 in native (SPI) mode
# -----------------------------------------------------------------------------

print_header "Building UDP Packet Forwarder for V2 NATIVE"
clone_and_patch https://github.com/Lora-net/lora_gateway.git v5.0.1
pushd lora_gateway >> /dev/null
echo "CFG_SPI= native" >> libloragw/library.cfg
make clean all
popd > /dev/null
clone_patch_and_make https://github.com/Lora-net/packet_forwarder.git v4.0.1
mkdir -p artifacts/v2/native
cp packet_forwarder/lora_pkt_fwd/lora_pkt_fwd artifacts/v2/native/

# -----------------------------------------------------------------------------
# Building packet forwarder for V2 in FTDI (USB) mode
# -----------------------------------------------------------------------------

print_header "Building UDP Packet Forwarder for V2 FTDI"
clone_and_patch https://github.com/Lora-net/lora_gateway.git v5.0.1
pushd lora_gateway >> /dev/null
echo "CFG_SPI= ftdi" >> libloragw/library.cfg
make clean all
popd > /dev/null
clone_patch_and_make https://github.com/Lora-net/packet_forwarder.git v4.0.1
mkdir -p artifacts/v2/ftdi
cp packet_forwarder/lora_pkt_fwd/lora_pkt_fwd artifacts/v2/ftdi/
cp lora_gateway/libloragw/99-libftdi.rules artifacts/v2/ftdi/

# -----------------------------------------------------------------------------
# Building packet forwarder for Corecells
# -----------------------------------------------------------------------------

print_header "Building UDP Packet Forwarder for Corecells"
clone_patch_and_make https://github.com/Lora-net/sx1302_hal.git V2.1.0
mkdir -p artifacts/corecell
cp sx1302_hal/packet_forwarder/lora_pkt_fwd artifacts/corecell/
cp sx1302_hal/util_chip_id/chip_id artifacts/corecell/

# -----------------------------------------------------------------------------
# Building packet forwarder for Picocells
# -----------------------------------------------------------------------------

print_header "Building UDP Packet Forwarder for Picocells"
clone_patch_and_make https://github.com/Lora-net/picoGW_hal V0.2.3
clone_patch_and_make https://github.com/Lora-net/picoGW_packet_forwarder.git V0.1.0
mkdir -p artifacts/picocell
cp picoGW_packet_forwarder/lora_pkt_fwd/lora_pkt_fwd artifacts/picocell/
cp picoGW_hal/util_chip_id/util_chip_id artifacts/picocell/chip_id

# -----------------------------------------------------------------------------
# Building packet forwarder for designs based on SX1280
# -----------------------------------------------------------------------------

print_header "Building UDP Packet Forwarder for 2.4 GHz"
clone_patch_and_make https://github.com/Lora-net/gateway_2g4_hal V1.1.0
mkdir -p artifacts/2g4
cp gateway_2g4_hal/packet_forwarder/lora_pkt_fwd artifacts/2g4/
cp gateway_2g4_hal/util_chip_id/chip_id artifacts/2g4/
