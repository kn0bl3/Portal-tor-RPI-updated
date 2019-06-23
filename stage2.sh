
function GetWirelessDevice () {
	echo -e "Which of the following NICs is for the WAN (Wireless)? \n"$(ip addr | grep -E "^[0-9]" | cut -d ' ' -f 2 | sed s/\://g)"\nDevice: "
	read WAN_DEV
}


function GetWiredDevice () {

	echo -e "Which of the following NICs is for the LAN (Wired)? \n"$(ip addr | grep -E "^[0-9]" | cut -d ' ' -f 2 | sed s/\://g)"\nDevice: "
	read LAN_DEV
}

function GetWAPInfo () {
	echo "What is the SSID for the WAN connection?"
	read WAN_SSID
	echo "Whats the coffee shops WIFI password?"
	read WAN_PWD
}

function CreateTorService () {
	echo "Creating tor.service file"
	cat << __EXIT__ > /etc/systemd/system/tor.service
[Unit]
Description=Anonymizing overlay network for TCP
After=ntpd.service network.target nss-lookup.target

[Service]
Type=simple
User=tor
ExecStart=/usr/local/bin/tor -f /etc/tor/torrc
ExecReload=/bin/kill -HUP ${MAINPID}
KillSignal=SIGINT
LimitNOFILE=8192
PrivateDevices=yes

[Install]
WantedBy=multi-user.target
__EXIT__
}


function PrepareTorrc () {
	cat << __EXIT__ >> /etc/tor/torrc
SocksPort 127.0.0.1:9050
SocksPort 172.16.0.1:9050
TransPort 172.16.0.1:9040
TransPort 127.0.0.1:9040
DNSPort 172.16.0.1:9053
DNSPort 127.0.0.1:9053
AllowUnverifiedNodes middle,rendezvous
__EXIT__
}

function CreateMacspoofService () {
cat << __EXIT__ >> /etc/systemd/system/macspoof@.service
[Unit]
Description=MAC Address Cahnge %I
Wants=network-pre.target
Before=network-pre.target
BindsTo=sys-subsystem-net-devices-%i.device
After=sys-subsystem-net-device-%i.device

[Service]
Type=oneshot
ExecStart=/usr/bin/macchanger -r %I
Type=oneshot

[Install]
WantedBy=multi-user.target
__EXIT__
}

function CreatentptimesyncService () {
	cat << __EXIT__ >> /etc/systemd/system/ntptimesync.service
[Unit]
Description=Network Time Service
After=network.target nss-lookup.target
Before=ntpd.service

[Service]
Type=oneshot
PrivateTmp=true
ExecStart=/usr/bin/ntpd -gq

[Install]
WantedBy=multi-user.target

__EXIT__
}

function PrepIPTables () {
	cat << __EXIT__ >> /etc/iptables/iptables.rules
# Empty iptables rule file
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -i $LAN_DEV -p udp -m udp --dport 53 -j REDIRECT --to-ports 9053
-A PREROUTING -i $LAN_DEV -p tcp -m tcp -d 172.16.0.1 --dport 22 -j REDIRECT --to-ports 2222
-A PREROUTING -i $LAN_DEV -p tcp -m tcp -d 172.16.0.1 --dport 8123 -j REDIRECT --to-ports 9050
-A PREROUTING -i $LAN_DEV -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports 9040
COMMIT

*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -i $LAN_DEV -p tcp -m tcp --dport 9050 -j ACCEPT
-A INPUT -i $LAN_DEV -p tcp --dport 9040 -j ACCEPT
-A INPUT -i $LAN_DEV -p udp -m udp --dport 9053 -j ACCEPT
-A INPUT -i $LAN_DEV -p udp -m udp --dport 67 -j ACCEPT
-A INPUT -i $LAN_DEV -p tcp -m tcp --dport 2222 -j ACCEPT
-A INPUT -p tcp -j REJECT --reject-with tcp-reset
-A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
-A INPUT -j REJECT --reject-with icmp-proto-unreachable
COMMIT
__EXIT__
}

function SETUP_NETWORK () {
	cat << __EXIT__ > /etc/systemd/network/$LAN_DEV.network
[Match]
Name=$LAN_DEV

[Network]
Address=172.16.0.1/16
DNS=172.16.0.1
DHCPServer=yes
__EXIT__
	cat << __EXIT__ > /etc/systemd/network/$WAN_DEV.network
[Match]
Name=$WAN_DEV

[Network]
DHCP=ipv4
__EXIT__
}
pacman-key --init
pacman -Syu
pacman -S vim sudo tor macchanger ntp

sed -i "s/rw/rw ipv6.disable=1/g" /boot/cmdline.txt 

function Setupwpasupplicant () {
	wpa_passphrase "$WAN_SSID" "$WAN_PWD" >> /etc/wpa_supplicant/wpa_supplicant-$WAN_DEV.conf
}
GetWirelessDevice
GetWiredDevice
GetWAPInfo
CreateTorService
PrepareTorrc
CreateMacspoofService
CreatentptimesyncService
PrepIPTables
SETUP_NETWORK
Setupwpasupplicant


cat << __EXIT__ >> /etc/ssh/sshd
Port 2222
__EXIT__

systemctl enable sshd ntpd ntptimesync tor iptables macspoof@$WAN_DEV macspoof@$LAN_DEV systemd-networkd wpa_supplicant@$WAN_DEV

echo "Set Root Password (Running passwd).."
passwd
echo "Set alarm password (Running passwd alarm).."
passwd alarm



echo "STAGE2 COMPLETE. REBOOT REQUIRED. IPv6 Disabled, macspoofed, fail-closed, tor router setup complete"
echo "Consider using a tor bridge and replacing the wireless WAN connection for a wired WAN connection if your threat model calls for it."
echo "Support for 3g/4g GSM Dongles as internet source coming soon to a github repo near you!"


