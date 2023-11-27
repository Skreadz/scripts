#!/bin/bash
sudo apt install squid
 
sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.old
 
sudo touch /etc/squid/squid.conf
 
ip -brief address show | awk '{print $1,$3}'
read -p "Choisir l'interface du LAN : " nterface
network=$(ip route show dev $nterface | awk '{print $1}')
ipsqui=$(ip -brief address show | grep $nterface | awk '{print $3}'| awk -F/ '{print $1}')
 
sudo cat << EOF > /etc/squid/squid.conf
# Par défaut le proxy écoute sur ses deux interfaces, pour des soucis de sécurité il faut donc le
# restreindre à écouter sur l’interface du réseau local (LAN)
http_port $ipsqui:3128
 
# Changer la taille du cache de squid, changer la valeur 100 par ce que vous voulez (valeur en Mo)
cache_dir ufs /var/spool/squid 100 16 256
 
acl all src all
acl lan src $network
acl Safe_ports port 80
acl Safe_ports port 443
acl Safe_ports port 21
acl Safe_ports port 22
acl Safe_ports port 10000
 
# Désactiver tous les protocoles sauf les ports sures
http_access deny !Safe_ports
 
# Désactiver l'accès pour tous les réseaux sauf les clients de l'ACL Lan
# deny = refuser ; ! = sauf ; lan = nom de l’ACL à laquelle on fait référence.
http_access deny !lan
 
# Déclarer un fichier qui contient les domaines à bloquer
acl deny_domain url_regex -i "/etc/squid/denydomain.txt"
 
# Refuser les domaines déclarés dans le fichier définit dans l'ACL deny_domain
http_access deny deny_domain
 
access_log /var/log/squid/access.log squid
EOF
 
sudo systemctl restart squid