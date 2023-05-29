#!/bin/bash

#https://pimylifeup.com/raspberry-pi-wireless-access-point/
sudo apt update
sudo apt upgrade
sudo apt install hostapd dnsmasq iptables
echo "Stopping hostapd and dnsmasq"
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq
echo "Writing to /etc/dhcpcd.conf"
sudo touch /etc/dhcpcd.conf
sudo sed -i '$a interface wlan0\n    \static ip_address=192.168.220.1/24\n    nohook wpa_supplicant' /etc/dhcpcd.conf
echo "Restarting dhcpcd"
sudo systemctl restart dhcpcd
echo "Writing to /etc/hostapd/hostapd.conf"
sudo touch /etc/hostapd/hostapd.conf 
sudo sed -i '$a interface=wlan0\ndriver=nl80211\n\nhw_mode=g\nchannel=6\nieee80211n=1\nwmm_enabled=0\nmacaddr_acl=0\nignore_broadcast_ssid=0\n\nauth_algs=1\nwpa=2\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP\nrsn_pairwise=CCMP\n\n# This is the name of the network\n\nssid=AAAP\n# The network passphrase\nwpa_passphrase=asdfghjklzx' /etc/dhcpcd.conf
echo "Writing to /etc/default/hostapd"
sudo touch /etc/default/hostapd
sudo sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/g' /etc/default/hostapd
echo "Mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig"
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
echo "Writing to /etc/dnsmasq.conf"
sudo touch /etc/dnsmasq.conf
sudo sed -i '$a interface=wlan0       # Use interface wlan0  \nserver=1.1.1.1       # Use Cloudflare DNS  \ndhcp-range=192.168.220.50,192.168.220.150,12h # IP range and lease time' /etc/dnsmasq.conf
echo "Writing to /etc/sysctl.conf"
sudo touch /etc/sysctl.conf
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
echo "Writing 1 to /proc/sys/net/ipv4/ip_forward"
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
echo "Saving Ip Tables"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
sudo sed -i '/^exit/i sudo hostapd /etc/hostapd/hostapd.conf & iptables-restore < /etc/iptables.ipv4.nat' /etc/rc.local
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl start hostapd
sudo service dnsmasq start
echo "Please reboot! All set up :-)"
