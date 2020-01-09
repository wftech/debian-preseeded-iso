#!/bin/sh

# Check requirements
check() {
    command -v "$1" >/dev/null 2>&1 || { echo "[!] $1 is required" >&2; exit 1; }
}

check "bsdtar"
check "gunzip"
check "gzip"
check "cpio"
check "xorriso"

set -e
set -x

# Setup
original_iso="firmware-10.2.0-amd64-netinst.iso"
base_dowload_path="https://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/10.2.0+nonfree/amd64/iso-cd/"
new_iso="preseed-debian-buster.iso"
output_dir="$(pwd)"
tmp_dir="$(mktemp -d)"
cp preseed.cfg "$tmp_dir"

cd "$tmp_dir"
mkdir isofiles

# Download ISO
wget "$base_dowload_path$original_iso"

# Extract & modify
bsdtar -C isofiles -xf "$original_iso"
chmod +w -R isofiles/install.amd/
gunzip isofiles/install.amd/initrd.gz
echo preseed.cfg | cpio -H newc -o -A -F isofiles/install.amd/initrd
gzip isofiles/install.amd/initrd
chmod -w -R isofiles/install.amd/

# Create new iso
xorriso -as mkisofs -o "$new_iso" \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot \
    -boot-load-size 4 -boot-info-table isofiles

mv "$new_iso" "$output_dir"

# Clean-up
chmod +w -R isofiles
cd "$output_dir"
rm -rf "$tmp_dir"