#! /bin/bash

# Hostname and time
echo "Skylake" > /etc/hostname
ln -s /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc --utc

# Locale
echo "${locale}.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=${locale}.UTF-8" > /etc/locale.conf
echo "KEYMAP=${kb_layout}" > /etc/vconsole.conf

# User config
echo "root:${root_password}" | chpasswd
useradd -m -G wheel ${username}
echo "${username}:${user_password}" | chpasswd

# Enable sudo
pacman -Sy --noconfirm sudo
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/99_wheel

# Create fstab
UEFI_UUID=$(blkid -s UUID -o value /dev/"${disk}1")
ROOT_UUID=$(blkid -s UUID -o value /dev/"${disk}2")
cat << EOF >> /etc/fstab
UUID=${ROOT_UUID} / ext4 defaults 0 1
UUID=${UEFI_UUID} /boot vfat defaults,noatime 0 2
EOF

# Swapfile
fallocate -l 4G /swapfile
chmod 0600 /swapfile
mkswap /swapfile
swapon /swapfile
cat << EOF >> /etc/fstab
/swapfile none swap sw 0 0
EOF

# EFI stub booting
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
pacman -S --noconfirm efibootmgr
efibootmgr -d /dev/${disk} -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "root=/dev/"${disk}2" rw initrd=\intel-ucode.img initrd=\initramfs-linux.img"

# Development tools
pacman -S --noconfirm --needed base-devel

# Essential packages and useful tools
pacman -S --noconfirm intel-ucode ntfs-3g curl nano mlocate tree btop xdg-utils xdg-desktop-portal

# Xorg - Nvidia
pacman -S --noconfirm --needed xorg-server xorg-xinit xorg-apps
pacman -S --noconfirm nvidia nvidia-settings nvidia-utils libvdpau

# Gstreamer
pacman -S --noconfirm gstreamer gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly

# Install fonts
pacman -S --noconfirm --needed ttf-roboto noto-fonts noto-fonts-emoji noto-fonts-cjk noto-fonts-extra

# Gnome
pacman -S --noconfirm gdm gnome-shell gnome-shell-extensions gnome-backgrounds gnome-settings-daemon gnome-control-center gnome-tweaks gnome-console gnome-text-editor eog eog-plugins gnome-disk-utility gnome-screenshot gnome-calculator gnome-characters gnome-keyring gnome-logs gnome-system-monitor evince nautilus file-roller sushi rhythmbox

systemctl enable gdm.service

# Software
pacman -S --noconfirm font-manager firefox mpv

# Themes
pacman -S --noconfirm papirus-icon-theme

# Enable NetworkManager and use iwd backend
pacman -S --noconfirm iwd networkmanager
cat << EOF >> /etc/NetworkManager/NetworkManager.conf
[device]
wifi.backend=iwd
wifi.iwd.autoconnect=yes
EOF
systemctl enable NetworkManager.service

# Nvidia config
cat << EOF > /usr/share/X11/xorg.conf.d/20-nvidia.conf
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    BoardName      "GeForce GTX 1070"
    Option         "Coolbits" "4"
EndSection
EOF

# Acpid
pacman -S --noconfirm acpid
systemctl enable acpid

# Xinitrc
cat << EOF > /home/${username}/.xprofile
nvidia-settings -a '[gpu:0]/GPUFanControlState=1' -a '[fan:0]/GPUTargetFanSpeed=40'
EOF

# Enable pacman colors
sed -i '/Color/s/^#//g' /etc/pacman.conf

# Create user directories
pacman -S --noconfirm xdg-user-dirs-gtk
xdg-user-dirs-update

# Self delete & exit
rm arch-chroot.sh && exit 0
