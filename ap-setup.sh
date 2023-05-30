#!/bin/bash

echo SSID:
read ssid
echo PWD:
read pwd

sudo chmod +x onboot.sh

#https://pimylifeup.com/raspberry-pi-wireless-access-point/
sudo apt-get update
sudo apt-get -y upgrade


echo "Checking hostapd and dnsmasq installation status"
sudo apt-get -y install hostapd dnsmasq iptables


echo "Stopping hostapd and dnsmasq"
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq


echo "Writing to /etc/dhcpcd.conf"
sudo echo "interface wlan0" >> /etc/dhcpcd.conf
sudo echo "    static ip_address=192.168.220.1/24" >> /etc/dhcpcd.conf
sudo echo "    nohook wpa_supplicant" >> /etc/dhcpcd.conf


echo "Restarting dhcpcd"
sudo systemctl restart dhcpcd


echo "Writing to /etc/hostapd/hostapd.conf"
sudo touch /etc/hostapd/hostapd.conf
sudo echo "interface=wlan0" >> /etc/hostapd/hostapd.conf
sudo echo "driver=nl80211" >> /etc/hostapd/hostapd.conf
sudo echo "hw_mode=g" >> /etc/hostapd/hostapd.conf
sudo echo "channel=6" >> /etc/hostapd/hostapd.conf
sudo echo "ieee80211n=1" >> /etc/hostapd/hostapd.conf
sudo echo "wmm_enabled=0" >> /etc/hostapd/hostapd.conf
sudo echo "macaddr_acl=0" >> /etc/hostapd/hostapd.conf
sudo echo "ignore_broadcast_ssid=0" >> /etc/hostapd/hostapd.conf
sudo echo "auth_algs=1" >> /etc/hostapd/hostapd.conf
sudo echo "wpa=2" >> /etc/hostapd/hostapd.conf
sudo echo "wpa_key_mgmt=WPA-PSK" >> /etc/hostapd/hostapd.conf
sudo echo "wpa_pairwise=TKIP" >> /etc/hostapd/hostapd.conf
sudo echo "rsn_pairwise=CCMP" >> /etc/hostapd/hostapd.conf
sudo echo "ssid=${ssid}" >> /etc/hostapd/hostapd.conf
sudo echo "wpa_passphrase=${pwd}" >> /etc/hostapd/hostapd.conf


echo "Writing to /etc/default/hostapd"
sudo touch /etc/default/hostapd
sudo sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/g' /etc/default/hostapd

# step 12 isnt neccessary
 
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
echo "Writing to /etc/dnsmasq.conf"

echo "interface=wlan0" >> /etc/dnsmasq.conf
echo "server=1.1.1.1" >> /etc/dnsmasq.conf 
echo "dhcp-range=192.168.220.50,192.168.220.150,12h" >> /etc/dnsmasq.conf 

echo "Writing to /etc/sysctl.conf"
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

echo "Writing 1 to /proc/sys/net/ipv4/ip_forward"
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

echo "Saving Ip Tables"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

echo "Editing rc.local"
sudo sed -i '/^exit/i sudo /home/$USER/Pi3-WAP/onboot.sh' /etc/rc.local

sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd
sudo service dnsmasq start

echo "Please reboot! All set up :-)"
