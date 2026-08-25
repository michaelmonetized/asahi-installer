#!/bin/sh
# SPDX-License-Identifier: MIT
# Omnux Linux bootstrap installer.
#
#   curl -fsSL https://raw.githubusercontent.com/michaelmonetized/asahi-installer/omnux/scripts/bootstrap-omnux.sh | sh
#
# Based on the Asahi Linux bootstrap installer.

if true; then
    set -e

    if [ ! -e /System ]; then
        echo "You appear to be running this script from Linux or another non-macOS system."
        echo "Omnux Linux can only be installed from macOS (or recoveryOS)."
        echo "Apple Silicon Macs cannot boot PC-style ISO images; there is no ISO."
        exit 1
    fi

    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

    if ! curl --no-progress-meter file:/// >/dev/null 2>&1; then
        echo "Your version of cURL is too old. This usually means your macOS is very out"
        echo "of date. Installing Omnux Linux requires at least macOS version 13.5."
        exit 1
    fi

    CHIP="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo unknown)"

    case "$CHIP" in
        *M1*|*M2*)
            echo "Detected: $CHIP — supported track."
            ;;
        *M3*)
            echo "Detected: $CHIP"
            echo
            echo "*** OMNUX EXPERIMENTAL BRING-UP TRACK ***"
            echo "M3 support is experimental: core hardware (NVMe, WiFi, Bluetooth,"
            echo "keyboard, trackpad, audio) works, but graphics are software-rendered"
            echo "(the M3 GPU driver does not exist yet upstream). Expect a slow desktop,"
            echo "no sleep, and reduced battery life. Do not file bugs against Omnux or"
            echo "Asahi Linux from this track."
            echo
            printf "Type EXPERIMENTAL to continue, anything else to abort: "
            if [ -t 0 ] || [ -e /dev/tty ]; then
                IFS= read -r ANSWER </dev/tty || ANSWER=""
            else
                ANSWER=""
            fi
            if [ "$ANSWER" != "EXPERIMENTAL" ]; then
                echo "Aborted. Track progress at the support matrix:"
                echo "https://github.com/michaelmonetized/asahi-installer/blob/omnux/SUPPORT.md"
                exit 1
            fi
            export OMNUX_EXPERIMENTAL=1
            ;;
        *M4*|*M5*|*M6*|*T8132*|*T6040*|*T6041*)
            echo "Detected: $CHIP"
            echo
            echo "M4-, M5- and M6-class machines cannot boot Linux yet — anywhere."
            echo "The required hardware enablement has not been reverse-engineered."
            echo "Newer machines (Mac mini M6/M5 Pro, Mac Studio M5 Max/Ultra, all"
            echo "announced August 25, 2026) are in the same boat until public"
            echo "patches exist; we integrate them the day they do."
            echo "Track progress at the support matrix:"
            echo "https://github.com/michaelmonetized/asahi-installer/blob/omnux/SUPPORT.md"
            exit 1
            ;;
        *)
            echo "Detected chip: $CHIP"
            echo "This does not look like a supported Apple Silicon machine."
            exit 1
            ;;
    esac

    export VERSION_FLAG="https://github.com/michaelmonetized/asahi-installer/releases/latest/download/latest"
    export INSTALLER_BASE="https://github.com/michaelmonetized/asahi-installer/releases/latest/download"
    export INSTALLER_DATA="https://cdn.asahilinux.org/data/installer_data.json"
    export REPO_BASE="https://cdn.asahilinux.org"

    #TMP="$(mktemp -d)"
    TMP=/tmp/omnux-install

    echo
    echo "Bootstrapping Omnux installer:"

    if [ -e "$TMP" ]; then
        mv "$TMP" "$TMP-$(date +%Y%m%d-%H%M%S)"
    fi

    mkdir -p "$TMP"
    cd "$TMP"

    echo "  Checking version..."

    PKG_VER="$(curl --no-progress-meter -L "$VERSION_FLAG")"
    echo "  Version: $PKG_VER"

    PKG="installer-$PKG_VER.tar.gz"

    echo "  Downloading..."

    curl --no-progress-meter -L -o "$PKG" "$INSTALLER_BASE/$PKG"
    curl --no-progress-meter -L -O "$INSTALLER_DATA"

    echo "  Extracting..."

    tar xf "$PKG"

    echo "  Initializing..."
    echo

    if [ "$USER" != "root" ]; then
        echo "The installer needs to run as root."
        echo "Please enter your sudo password if prompted."
        exec caffeinate -dis sudo -E ./install.sh "$@"
    else
        exec caffeinate -dis ./install.sh "$@"
    fi
fi
