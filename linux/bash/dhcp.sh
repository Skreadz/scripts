#!/bin/bash
sudo apt install -y ipcalc
sudo apt install -y isc-dhcp-server
 
ip -o -4 addr show | awk '{print $2,$4}'
 
read -p "selectionner l'interface pour le dhcp: " nterface
read -p "Saisir le nom de l'etendue : " poolname
read -p "Saisir le debut de l'etendue : " pooldebut
read -p "Saisir la fin de l'etendue : " poolfin
read -p "Saisir le dns de l'etendue : " pooldns
 
network=$(ip route show dev $nterface | awk '{print $1}')
gateway=$(ip route show dev $nterface | awk '{print $7}')
mask=$(ipcalc $network | grep Netmask | awk '{print $2}')
reseau=$(ipcalc $network | grep Network | awk '{print $2}' | awk -F/ '{print $1}')
 
sudo sed -i "s/INTERFACESv4=\"\"/INTERFACESv4=\"$nterface\"/g" /etc/default/isc-dhcp-server
 
sudo cat << EOF >> /etc/dhcp/dhcpd.conf
#etendue $poolname
subnet $reseau netmask $mask {
 range $pooldebut $poolfin;
 option routers $gateway;
 option domain-name-servers $pooldns;
}
EOF
sudo systemctl restart isc-dhcp-server