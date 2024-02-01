
jour=$(date +"%Y-%m-%d")
read -p "login utilisateur : " login
read -p "mdp temporaire : " mdp
read -p "hostname (nom du pc) : " hostname
sudo ecryptfs-unwrap-passphrase /home/${login}/.ecryptfs/wrapped-passphrase ${mdp} > ${login}-${hostname}-${jour}.txt

mount -t cifs //fslevallois/Logiciels /mnt/samba -o user=crcitech
mv ${login}-${hostname}-${jour}.txt /mnt/samba/KEYBITLOCKER/BORDEAUX/Linux
sleep 5
umount /mnt/samba

sed -i 's/pc-name/'$hostname'/g' /etc/hostname
