#! /bin/bash

# SoftEther VPN setup script
# by Ria, N2RJ
# Simple script to setup a SoftEther VPN using L2TP
# Feedback: n2rj@arrl.net

#Download URL (from webpage)
DOWNLOADURL="http://www.softether-download.com/files/softether/v4.27-9666-beta-2018.04.21-tree/Linux/SoftEther_VPN_Server/32bit_-_ARM_EABI/softether-vpnserver-v4.27-9666-beta-2018.04.21-linux-arm_eabi-32bit.tar.gz"

#Download package
curl $DOWNLOADURL -s | sudo tar xzvf - -C /usr/local/
pushd .

#Compile
cd /usr/local/vpnserver
echo "1
1
1
1
" | sudo make
popd

#Adjust permissions
sudo chmod 755 /usr/local/vpnserver
sudo chmod 600 /usr/local/vpnserver/*
sudo chmod 700 /usr/local/vpnserver/vpncmd
sudo chmod 700 /usr/local/vpnserver/vpnserver

#copy files
sudo cp vpnserver /etc/init.d/
sudo chmod 755 /etc/init.d/vpnserver

#Automatically start when booted
sudo update-rc.d vpnserver defaults

#Start VPN server
sudo /etc/init.d/vpnserver start

#VPN configuration
eth0=`ifconfig -a | grep -m1 -o "^\w*\b"`
sed -i -e 's/IFPLACEHOLDER/$eth0/g' commands.in
HOSTNAME=`hostname`
CONFIGBASEFILENAME=commands.in
mkdir .vpnsetuptemp
cp $CONFIGBASEFILENAME .vpnsetuptemp/
CONFIG=.vpnsetuptemp/$CONFIGBASEFILENAME
echo "Please enter your softether admin password: "
read softadmin
echo "Please enter your IPSEC Secret: "
read secret
echo "Please enter your l2tp username: "
read username
echo "Please enter your l2tp password: "
read pass
echo "Please enter a dynamic DNS hostname (your callsign is easiest):"
read ddnshost

sed -i "s/ADMINPASSWORD/$softadmin/g" $CONFIG
sed -i "s/USERNAME_RP/$username/g" $CONFIG
sed -i "s/PASSWORD_RP/$pass/g" $CONFIG
sed -i "s/SECRET_RP/$secret/g" $CONFIG
sed -i "s/DDNS_HOSTNAME/$ddnshost/g" $CONFIG


sudo /usr/local/vpnserver/vpncmd localhost:443 /SERVER /IN:$CONFIG



sudo rm -r .vpnsetuptemp

echo "DONE!"

echo "#####################ROUTER INSTRUCTIONS#####################"
echo "1. Set up this Raspberry Pi as a static DHCP in your router."
echo "   This ensures that the IP will remain the same."
echo
echo "Hardware address/MAC address:" `cat /sys/class/net/eth0/address`
echo "IP address:"                   `ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`
echo
echo
echo "2. Forward the following ports to the IP address in step 1:"
echo "4500/UDP"
echo "500/UDP"
echo "5555/TCP"
echo
echo
echo "#####################iPhone/iPad setup instructions#####################"
echo "# 1. Go to settings -> General -> VPN"
echo "# 2. Tap \"Add VPN Configuration\"   "
echo "# 3. Select type \"L2TP\""
echo "# 4. Enter the data in the fields:"
echo "#         hostname: $ddnshost.softether.net"
echo "#         username: $username"
echo "#         password: $pass"
echo "#         secret  : $secret"
echo "#         Description can be anything you choose"
echo "#         Send all traffic switched ON"
echo "#         Proxy switched OFF"
echo "# 5. Tap \"Done\""
echo "########################################################################"



