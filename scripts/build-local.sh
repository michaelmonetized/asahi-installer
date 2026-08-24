#!/bin/bash
# SPDX-License-Identifier: MIT
# Omnux local release builder — replaces GitHub Actions entirely.
#
# Usage:  ./scripts/build-local.sh [version]
# Output: releases/installer-<ver>.tar.gz, releases/latest, releases/SHA256SUMS
#
# Requirements (Arch): gcc-aarch64-linux-gnu, libarchive-tools, jq, curl,
# rustup with target aarch64-unknown-none-softfloat, python3, tar, cpio.

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"

PYTHON_VER=3.13.9
PYTHON_PKG="python-$PYTHON_VER-macos11.pkg"
PYTHON_URI="https://www.python.org/ftp/python/$PYTHON_VER/$PYTHON_PKG"

LIBFFI_VER=3.5.2
LIBFFI_MANIFEST_URI="https://ghcr.io/v2/homebrew/core/libffi/manifests/$LIBFFI_VER"
LIBFFI_BASE_URI="https://ghcr.io/v2/homebrew/core/libffi/blobs"
LIBFFI_TARGET_OS="macOS 26"
LIBFFI_PKG="libffi-$LIBFFI_VER-macos.tar.gz"

M1N1_REPO="${M1N1_REPO:-$ROOT/../m1n1}"
PACKAGE="$ROOT/package"
RELEASES="$ROOT/releases"
DL="$ROOT/dl"

VER="${1:-$(git describe --always --tags --dirty 2>/dev/null || echo local)}"
VER="omnux-$VER-$(date +%Y%m%d%H%M)"

rm -rf "$PACKAGE" "$RELEASES"
mkdir -p "$DL" "$PACKAGE" "$RELEASES" "$PACKAGE/bin"

echo "== Omnux local build: $VER =="

echo "-- Building m1n1 (integration branch) --"
if [ ! -r "$M1N1_REPO/build/m1n1.bin" ]; then
    make -C "$M1N1_REPO" distclean >/dev/null 2>&1 || true
    CARGO_NET_GIT_FETCH_WITH_CLI=true \
        TOOLCHAIN= ARCH=aarch64-linux-gnu- RELEASE=1 CHAINLOADING=1 \
        make -C "$M1N1_REPO" -j"$(nproc)"
fi
M1N1_STAGE1="$M1N1_REPO/build/m1n1.bin"

echo "-- Assembling payload --"
cp -r "$ROOT/src/"* "$PACKAGE/"
rm -rf "$PACKAGE/asahi_firmware"
cp -r "$ROOT/asahi_firmware" "$PACKAGE/"
mkdir -p "$PACKAGE/boot"
cp "$M1N1_STAGE1" "$PACKAGE/boot/m1n1.bin"

if [ -r "$ROOT/artwork/logos/icns/AsahiLinux_logomark.icns" ]; then
    cp "$ROOT/artwork/logos/icns/AsahiLinux_logomark.icns" "$PACKAGE/logo.icns"
else
    echo "   warning: artwork submodule missing, no logo.icns"
fi

echo "-- Fetching Python $PYTHON_VER + libffi $LIBFFI_VER --"
[ -e "$DL/$PYTHON_PKG" ] || curl -sSL -o "$DL/$PYTHON_PKG" "$PYTHON_URI"

if [ ! -e "$DL/$LIBFFI_PKG" ]; then
    token=$(curl -s "https://ghcr.io/token?service=ghcr.io&scope=repository%3Ahomebrew/core/go%3Apull" | jq -jr ".token")
    digest=$(curl -s \
        -H "Authorization: Bearer ${token}" \
        -H 'Accept: application/vnd.oci.image.index.v1+json' \
        "$LIBFFI_MANIFEST_URI" \
        | jq -r '[.manifests[] |
                select(.platform.architecture == "arm64"
                and .platform."os.version" == "'"$LIBFFI_TARGET_OS"'")
            ] | first | .annotations."sh.brew.bottle.digest"')
    curl -sL -o "$DL/$LIBFFI_PKG" \
        -H "Authorization: Bearer ${token}" \
        -H 'Accept: application/vnd.oci.image.index.v1+json' \
        "$LIBFFI_BASE_URI/sha256:$digest"
fi

echo "-- Vendoring runtime --"
cd "$PACKAGE"
bsdtar -xOf "../dl/$LIBFFI_PKG" "libffi/$LIBFFI_VER/lib/"libffi*.dylib > /dev/null 2>&1 || true
mkdir -p libffi-extract
tar xf "../dl/$LIBFFI_PKG" -C libffi-extract

mkdir -p Frameworks/Python.framework
bsdtar -tf "../dl/$PYTHON_PKG" Python_Framework.pkg/Payload > /dev/null
bsdtar -xOf "../dl/$PYTHON_PKG" Python_Framework.pkg/Payload | zcat | \
    cpio -i -D "Frameworks/Python.framework"

PYVERDIR="Frameworks/Python.framework/Versions/Current"
mv libffi-extract/libffi/$LIBFFI_VER/lib/libffi*.dylib "$PYVERDIR/lib/"
rm -rf libffi-extract

echo "-- Slimming Python --"
PYMAJMIN="${PYTHON_VER%.*}"
PYROOT="Frameworks/Python.framework/Versions/$PYMAJMIN"
rm -rf "$PYROOT/include" "$PYROOT/share"
( cd "$PYROOT/lib" && rm -rf tdb* tk* Tk* libtk* *tcl* )
PYSITE="$PYROOT/lib/python$PYMAJMIN"
rm -rf "$PYSITE/test" "$PYSITE/ensurepip" "$PYSITE/idlelib"
( cd "$PYSITE/lib-dynload" && rm -f _test* _tkinter* )

echo "-- Certificates --"
CERTS="$(python3 -c 'import certifi; print(certifi.where())' 2>/dev/null || echo /etc/ssl/certs/ca-certificates.crt)"
mkdir -p "$PYROOT/etc/openssl"
cp "$CERTS" "$PYROOT/etc/openssl/cert.pem"

echo "-- Packaging --"
echo "$VER" > version.tag
PKGFILE="$RELEASES/installer-$VER.tar.gz"
tar czf "$PKGFILE" .
echo "$VER" > "$RELEASES/latest"
( cd "$RELEASES" && sha256sum "installer-$VER.tar.gz" latest > SHA256SUMS )

echo
echo "Built:"
ls -la "$RELEASES"
