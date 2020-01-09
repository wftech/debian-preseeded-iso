# Debian preseeded ISO

## Requirements

- bsdtar
- gzip
- gunzip
- cpio
- xorriso
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

- [ ] Boot into TUI installer by default
