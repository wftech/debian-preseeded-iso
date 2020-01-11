# Debian preseeded ISO

## Requirements

- wget
- bsdtar
- gzip
- gunzip
- cpio
- xorriso
- GNU sed
- isolinux

## Usage

### Create preseeded ISO

```sh
./make-iso.sh
```

### Test with qemu

```sh
qemu-img create deb.img 5G
qemu-system-x86_64 -hda deb.img -m 2048 -cdrom preseed-debian-buster.iso
```

## TODO

- [x] Boot into TUI installer by default
- [x] Check local isolinux files
- [x] Setup GRUB auto boot (needed for EFI)
