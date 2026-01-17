wget https://archive.archlinux.org/packages/l/linux/linux-6.12.arch1-1-x86_64.pkg.tar.zst
wget https://archive.archlinux.org/packages/l/linux-headers/linux-headers-6.12.arch1-1-x86_64.pkg.tar.zst

sudo pacman -U linux-6.12.arch1-1-x86_64.pkg.tar.zst linux-headers-6.12.arch1-1-x86_64.pkg.tar.zst

sudo sed -i '/^#\[options\]/a IgnorePkg = linux linux-headers' /etc/pacman.conf

sudo mkinitcpio -P

sudo reboot now
