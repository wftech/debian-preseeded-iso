#!/bin/sh

# Check requirements
check() {
    command -v "$1" >/dev/null 2>&1 || { echo "[!] $1 is required" >&2; exit 1; }
}


check "wget"
check "bsdtar"
check "gunzip"
check "gzip"
check "cpio"
check "sed"
check "egrep"
check "xorriso"


locations="/usr/lib/ISOLINUX/isohdpfx.bin /usr/share/syslinux/isohdpfx.bin"
for location in $locations failed; do
    if [ -f "$location" ]; then
         ISOHDPFX_LOCATION=$location
         break
    fi
    if [ "$location" = failed ]; then
         echo "[!] isohdpfx.bin not found"; exit 1
    fi
done

set -e
set -x

# Setup
original_iso="firmware-11.2.0-amd64-netinst.iso"
base_dowload_path="https://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/11.2.0+nonfree/amd64/iso-cd/"
new_iso="preseed-debian-bullseye.iso"
output_dir="$(pwd)"
tmp_dir="$(mktemp -d)"

# Download ISO
wget "$base_dowload_path$original_iso" -O "$original_iso" --continue

# Prepare temp dir
cp "$original_iso" "$tmp_dir"
cp preseed.cfg "$tmp_dir"
cd "$tmp_dir"
mkdir isofiles

# Extract & modify
bsdtar -C isofiles -xf "$original_iso"
chmod +w -R isofiles/install.amd/
gunzip isofiles/install.amd/initrd.gz
echo preseed.cfg | cpio -H newc -o -A -F isofiles/install.amd/initrd
gzip isofiles/install.amd/initrd
chmod -w -R isofiles/install.amd/

# Disable gtk installer and modify timeout - grub
chmod +w -R isofiles/boot/grub
sed -i '1i set timeout=5' isofiles/boot/grub/grub.cfg
sed -ie '/Graphical install/,+4 s/^/#/' isofiles/boot/grub/grub.cfg
chmod -w -R isofiles/boot/grub

# Disable gtk installer and modify timeout - isolinux
chmod +w -R isofiles/isolinux
sed -i '/gtk/s/^/#/' isofiles/isolinux/menu.cfg
sed -i 's/timeout 0/timeout 50/' isofiles/isolinux/isolinux.cfg
echo 'totaltimeout 100' >>  isofiles/isolinux/isolinux.cfg
chmod -w -R isofiles/isolinux

# Regenerate md5sum.txt
cd isofiles
chmod +w md5sum.txt
rm md5sum.txt
# egrep hack bacause of "debian -> ." - find exits with status code 1
iso_files="$(find -follow -type f | egrep '.*')"
for f in $iso_files; do
    md5sum "$f" >> md5sum.txt
done
chmod -w md5sum.txt
cd ..

# Create new iso
xorriso -as mkisofs -o "$new_iso" \
    -isohybrid-mbr "${ISOHDPFX_LOCATION}" \
    -c isolinux/boot.cat -b isolinux/isolinux.bin -no-emul-boot \
    -boot-load-size 4 -boot-info-table isofiles

mv "$new_iso" "$output_dir"

# Clean-up
chmod +w -R isofiles
cd "$output_dir"
rm -rf "$tmp_dir"
