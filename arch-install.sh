#! /bin/bash

# Variables
export disk="sda"
wifi_ssid=""
wifi_password=""
export kb_layout="sv-latin1"
export root_password=""
export username="arch"
export user_password=""
export locale="en_US"
export timezone="Europe/Stockholm"

# Check if system is being installed to the correct disk
lsblk -o NAME,FSTYPE,LABEL,MOUNTPOINTS /dev/${disk}
read -p "Press ENTER to install to above disk or CTRL+C to abort." key

# Set keyboard layout
loadkeys ${kb_layout}

# Connect to wifi
iwctl --passphrase ${wifi_password} station wlan0 connect ${wifi_ssid}
read -p "Connecting to internet...."$'\n' -t 5

#Sync time
hwclock --systohc --utc
timedatectl set-ntp true
sleep 5

# Partition the disk
sgdisk -Z /dev/${disk}
sgdisk -n 0:0:+512MiB -t 1:ef00 -c 1:"EFI System Partition" /dev/${disk}
sgdisk -n 0:0:0 -t 2:8300 -c 2:"Linux" /dev/${disk}
mkfs.fat -n ESP -F 32 /dev/"${disk}1"
yes | mkfs.ext4 -L ArchLinux /dev/"${disk}2"

# Mount partitions
mount /dev/"${disk}2" /mnt
mount --mkdir /dev/"${disk}1" /mnt/boot

# Pacstrap
reflector --country Sweden --latest 5 --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
read -p "Generating pacman mirrorlist...."$'\n' -t 10
pacman -Sy --noconfirm archlinux-keyring
pacstrap /mnt base linux linux-firmware

# Continue in chroot
cp arch-chroot.sh /mnt
arch-chroot /mnt /arch-chroot.sh
