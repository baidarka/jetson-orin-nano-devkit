#!/usr/bin/env bash

set -e

WORKDIR="$PWD/jetson_flash"
BOARD="jetson-orin-nano-devkit"
L4T_VERSION="36.4.4"  # see: https://developer.nvidia.com/embedded/jetson-linux-archive
L4T_RELEASE_VERSION="36_release_v4.4"

banner() { echo -e "\n=== $1 ===\n"; }

# --- CHECK REQUIREMENTS ---
check_requirements() {

    banner "Checking requirements"
    sudo apt install qemu binfmt-support qemu-user-static libxml2-utils binutils

    for cmd in wget tar grep awk sed sudo lsusb; do
      echo "check $cmd"
      command -v $cmd >/dev/null 2>&1 || { echo "$cmd is required"; exit 1; }
    done

}

# --- GET LATEST VERSION + URLs ---
get_latest_urls() {

    banner "Finding Jetson Linux release (defaulting to: $L4T_VERSION)"
    # check at the archive for latest version
    #ARCHIVE_PAGE=$(curl https://developer.nvidia.com/embedded/jetson-linux-archive)
    # L4T_VERSION=$(echo "$ARCHIVE_PAGE" | grep -oP 'Jetson Linux R\d+\.\d+\.\d+' | head -n1 | grep -oP '\d+\.\d+\.\d+')
    # echo "Found L4T_VERSION: $L4T_VERSION"

    if [ -z "$L4T_VERSION" ]; then
      echo "❌ Failed to determine latest L4T version."
      exit 1
    fi

    #BSP_URL=$(echo "$ARCHIVE_PAGE" | grep -oP "https://developer.download.nvidia.com/embedded/L4T/.+Jetson_Linux_R${L4T_VERSION}_aarch64\.tbz2" | head -n1)
    #ROOTFS_URL=$(echo "$ARCHIVE_PAGE" | grep -oP "https://developer.download.nvidia.com/embedded/L4T/.+Tegra_Linux_Sample-Root-Filesystem_R${L4T_VERSION}_aarch64\.tbz2" | head -n1)

    # Driver package BSP
    BSP_URL="https://developer.nvidia.com/downloads/embedded/l4t/r${L4T_RELEASE_VERSION}/release/Jetson_Linux_r${L4T_VERSION}_aarch64.tbz2"
    ROOTFS_URL="https://developer.nvidia.com/downloads/embedded/l4t/r${L4T_RELEASE_VERSION}/release/Tegra_Linux_Sample-Root-Filesystem_r${L4T_VERSION}_aarch64.tbz2"

    if [ -z "$BSP_URL" ] || [ -z "$ROOTFS_URL" ]; then
      echo "❌ Failed to find BSP or RootFS URLs."
      exit 1
    fi

    echo "BSP URL: $BSP_URL"
    echo "RootFS URL: $ROOTFS_URL"

}

# --- AUTO-SELECT DEVICE ---

detect_device() {
    # Default assumption: Jetson Orin Nano DevKit has onboard eMMC
    # DEVICE="mmcblk0p1"
    # sdmmc_user
    # I use a 1TB NVMe

    DEVICE="nvme0n1p1"
    banner "Detecting target storage device"
    echo "Assuming NWMe ($DEVICE)."
    echo
    echo "Press Enter to accept default ($DEVICE) or type your device:"
    read -r input

    if [ -n "$input" ]; then
      DEVICE="$input"
    fi

    echo "Using DEVICE=$DEVICE"
}

# --- DOWNLOAD FILES ---
download_files() {
    banner "Downloading BSP and RootFS to '$WORKDIR'"
    mkdir -p "$WORKDIR"
    cd "$WORKDIR"

    BSP_FILE="Jetson_Linux_R${L4T_VERSION}_aarch64.tbz2"
    ROOTFS_FILE="Tegra_Linux_Sample-Root-Filesystem_R${L4T_VERSION}_aarch64.tbz2"

    # if not exists, then download file
    [ -f "$BSP_FILE" ] || curl -L "$BSP_URL" -o "$BSP_FILE"
    [ -f "$ROOTFS_FILE" ] || curl -L "$ROOTFS_URL" -o "$ROOTFS_FILE"

    ls -al $WORKDIR
}

# --- EXTRACT & APPLY BINARIES ---

extract_and_prepare() {
    banner "Extracting BSP"
    tar -xvjf Jetson_Linux_R${L4T_VERSION}_aarch64.tbz2
    banner "Extracting RootFS"
    sudo tar -xvjf Tegra_Linux_Sample-Root-Filesystem_R${L4T_VERSION}_aarch64.tbz2 -C Linux_for_Tegra/rootfs
    banner "Applying Binaries"
    cd Linux_for_Tegra
    sudo ./apply_binaries.sh
}

# --- WAIT FOR BOARD IN RECOVERY MODE ---

wait_for_device() {
    banner "Waiting for Jetson in recovery mode"
    echo "Put Jetson Orin Nano into recovery mode:"
    echo "    1. Power off the board."
    echo "    2. Hold FORCE RECOVERY and press POWER."
    echo "    3. Connect USB-C to host."
    echo "Press Enter when ready..."
    read

    if ! lsusb | grep -q NVIDIA; then
      echo "❌ No Jetson device detected. Check USB & recovery mode."
      exit 1
    fi
}

# --- FLASH DEVICE ---
flash_device() {
    banner "Flashing $BOARD to $DEVICE"
    sudo ./flash.sh $BOARD $DEVICE
}

# --- MAIN EXECUTION ---
check_requirements
get_latest_urls
#detect_device
download_files
extract_and_prepare
#wait_for_device
#flash_device

banner "✅ Flash complete. Reboot your Jetson to finish setup."
