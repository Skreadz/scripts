#!/bin/bash
sudo apt install -y dfc
read -p "Saisir le nom du futur raid de type md"numero": " nameraid
read -p "Creer le dossier du futur point de montage (chemin direct): " pointdemontage
read -p "Saisir le nombre de disque: " nbredisk
 
sudo mkdir $pointdemontage
 
if [[ $nbredisk -eq 2 ]];then
   sudo fdisk -l | grep /dev/sd
   read -p "Saisir le nom des disques separé par des espaces: " listdisk
   raidmirroir=($listdisk)
   position="/dev/disk/by-path/"
 
      for disks in "${raidmirroir[@]}";
      do
      result+=" $position$(udevadm info -q property -n $disks | grep 'ID_PATH=' | cut -d= -f2 & echo > /dev/null 2>&1)"
      done
 
   sudo mdadm --create /dev/$nameraid  --level=1 --raid-devices=2 $result
   sudo update-initramfs -u
 
elif [[ $nbredisk -eq 3 ]];then
   sudo fdisk -l | grep /dev/sd
   read -p "Saisir le nom des disques separé par des espaces: " listdisk
   raidmirroir=($listdisk)
   position="/dev/disk/by-path/"
 
      for disks in "${raidmirroir[@]}";
      do
      result+=" $position$(udevadm info -q property -n $disks | grep 'ID_PATH=' | cut -d= -f2 & echo > /dev/null 2>&1)"
      done
 
   sudo mdadm --create /dev/$nameraid  --level=5 --raid-devices=3 $result
   sudo update-initramfs -u
 
elif [[ $nbredisk -eq 4 ]];then
   sudo fdisk -l | grep /dev/sd
   read -p "Saisir le nom des disques separé par des espaces: " listdisk
   raidmirroir=($listdisk)
   position="/dev/disk/by-path/"
 
      for disks in "${raidmirroir[@]}";
      do
      result+=" $position$(udevadm info -q property -n $disks | grep 'ID_PATH=' | cut -d= -f2 & echo > /dev/null 2>&1)"
      done
 
   sudo mdadm --create /dev/$nameraid  --level=5 --raid-devices=4 $result
   sudo update-initramfs -u
fi
 
sudo mkfs.ext4 /dev/$nameraid
 
sudo cat << EOF >> /etc/fstab
/dev/$nameraid $pointdemontage ext4 defaults 0 1
EOF
 
sudo mount -a
dfc