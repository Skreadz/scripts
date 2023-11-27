#!/bin/bash
sudo sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf
 
sudo sysctl -p /etc/sysctl.conf
 
sudo touch /etc/init.d/firewall.sh
 
ip -o -4 addr show | awk '{print $2,$4}'
read -p "Saisir l'interface du wan : " intwan
 
sudo cat << EOF >> /etc/init.d/firewall.sh
#!/bin/bash
# Vider les tables actuelles
iptables -t filter -F
iptables -t filter -X
echo -Purge : [OK]
 
 
# Activez le NAT pour le trafic sortant (y compris le ping et le SSH)
iptables -t nat -A POSTROUTING -o $intwan -j MASQUERADE
 
echo -Activation NAT : [OK]
EOF
 
sudo chmod +x /etc/init.d/firewall.sh
sudo chmod 770 /etc/init.d/firewall.sh
 
sudo touch /lib/systemd/system/firewall.service
 
sudo cat << EOF >> /lib/systemd/system/firewall.service
[Unit]
Description=Firewall
Requires=network-online.target
After=network-online.target
 
[Service]
User=root
Type=oneshot
RemainAfterExit=yes
 
ExecStart=/etc/init.d/firewall.sh start
ExecStop=/etc/init.d/firewall.sh stop
 
[Install]
WantedBy=multi-user.target
EOF
 
sudo systemctl enable firewall.service
 
sudo /etc/init.d/firewall.sh
 
sudo iptables -t nat -L -n -v