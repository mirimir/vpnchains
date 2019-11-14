This is a crude bash hack for creating dynamic two-hop VPN chains in a Debian router with DHCP. There's an infinite while loop script which:

* terminates all openvpn processes
* uses shuf to randomly select a VPN server IPv4 from each of two lists (vpns0 and vpns1)
* writes an iptables ruleset for the VPN chain, and restores it
* writes an init script for each VPN server, which tweaks routing before connecting
* connects to the first VPN server, and waits five seconds
* connects to the second VPN server, and waits 15 seconds
* pings 1.1.1.1 via the second VPN
* if there's a response, waits 10 minutes, and then restarts the loop
* otherwise restarts the loop

The ip6tables ruleset drops everything.

The iptables ruleset for each VPN chain:

* allows traffic only to vpn0 via enp0s3
* allows traffic only to vpn1 via tun0
* forwards enp0s8 via tun1 with masquerade

Each vpn0 init script:

* deletes routes for 0.0.0.0/1 and 128.0.0.0/1
* adds a route for vpn0 via enp0s3
* starts openvpn with vpn0.conf

Each vpn1 init script:

* deletes routes for 0.0.0.0/1 and 128.0.0.0/1
* adds a route for vpn1 via tun0
* starts openvpn with vpn1.conf

### Background

For online privacy and anonymity, the main options are Tor and VPN services. There's also I2P, but it's primarily about hidden "eepsites", and not access to the open Internet. Both Tor and I2P provide strong privacy and anonymity by design. They obscure connections by routing through multiple servers. And they both encrypt traffic in ways that prevent intervening servers from tracing connections.

However, for VPN services, privacy and anonymity depend entirely on trust. Basically, users must trust that VPN providers won't pwn them to adversaries. And there's no way for them to know which VPN services are safe. There's public evidence that EarthVPN, HideMyAss, IPVanish, Proxy.sh and PureVPN have pwned their users. And there's also public evidence that ExpressVPN and Private Internet Access (PIA) have not pwned their users, in that they retained no relevant records. Even so, there's no way to know what any VPN provider is doing currently.

Tor and I2P deal with that risk by distributing trust. That is, users connect through nested chains of servers. The first server ("relay" for Tor, and "router" for I2P) obviously knows the user's IP address, and it obviously knows the IP address of the next server in the chain. But it doesn't know the IP address of the Internet site that the user is connecting to. Because that information is securely encrypted.

Conversely, the last server in the chain obviously knows the IP address of the previous server, and it obviously knows the IP address of the Internet site that it must connect to. But it doesn't know the user's IP address. So as long as an adversary can't obtain data from all servers in the chain, it can't associate users and the Internet sites that they're connecting to.

However, this scheme is transparent to global adversaries with access to traffic data from enough relevant parts of the Internet. They can correlate traffic patterns, seeing where traffic comes from, and where it's going. That risk can be mitigated somewhat by mixing (combining multiple traffic flows) and padding (adding junk to keep traffic flows steady). But it's most effective to introduce variable propagation delays, which are much longer than traffic duration. And that just doesn't work for interactive Internet use.

OK, but let's say that you're not concerned about such global adversaries. Or that you just don't trust Tor, given its obvious ties to the US government. And that you want higher bandwidth than Tor or I2P provide. One answer is using nested VPN chains. That is, you route traffic successively through multiple VPN services. And like Tor and I2P, you distribute trust among multiple providers.

Some years ago, I worked out [how to create nested VPN chains](https://www.ivpn.net/privacy-guides/advanced-privacy-and-anonymity-part-1) using virtual pfSense routers in nested networks. Each router serves as a NAT gateway for a VPN service. And routing routers through other routers creates nested VPN chains.

That approach has served me well. But it's somewhat resource heavy, in that each VPN gateway router is a separate VM. However, one can [instead use routing and iptables](https://github.com/TensorTom/VPN-Chain) in a single machine. There's no OS-level isolation, but it's far lighter, and also far easier to control.

Here, I use that basic approach to create dynamic two-hop VPN chains in a Debian router with DHCP. Using simple bash scripting. Without the forwarding and DHCP, the scripts could be used in a single machine or VM. 

### Details

For the router VM, I used Debian 10 x64, with 1-2 CPU cores, 1 GB RAM and 8 GB dynamically allocated storage. With two network interfaces, one NATed (enp0s3) and the other (enp0s8) attached to a virtual network. One CPU core is enough, unless you'll be torrenting. 

First clone the vpnchains repository to /home/user/, and fix permissions

    $ git clone https://github.com/mirimir/vpnchains.git
    $ chmod u+x /home/user/vpnchains/utility_scripts/*.sh
    $ su
    # chmod u+x /home/user/vpnchains/openvpn_scripts/*.sh

Install packages, enable IPv4 forwarding, and configure ISC DHCP server

    # apt-get update
    # apt-get -y install openvpn isc-dhcp-server iptables-persistent w3m
    # echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    # sysctl -p
    # cp /home/user/vpnchains/dhcp/dhcpd.conf /etc/dhcp/
    # echo 'INTERFACES="enp0s8"' > /etc/default/isc-dhcp-server

ISC DHCP server is configured with subnet 192.168.11.0, the router at 192.168.11.1, and 10 client addresses.

Decide which VPN services to use. I tested this using ExpressVPN and VPN.ac, but AirVPN, IVPN, Mullvad and PIA are also good choices. It's OK to pay for the first VPN service with a credit card, but I recommend using well-mixed Bitcoin for the rest.

Most VPN services specify servers by hostname in their OpenVPN configuration files. Also, most now use inline certificates and keys. And if they require username/password authentication, they let OpenVPN prompt for them.

But here, it's most convenient to specify servers by IPv4 addresses. With no need for DNS when connecting, there's less chance of DNS leaks. Also, using IPv4 addresses simplifies writing routing commands and iptables rulesets on the fly.

Download the desired UDP-mode OpenVPN configuration files for each VPN service, and put each set in a working directory (such as /home/user/vpn0, /home/user/vpn1, etc). To get server hostnames and ports, run these in each directory:

    $ grep -h -e "remote" * | grep -v "random" | grep -v "cert" | grep -v "persist" | awk '{ print $2 }' | sort | uniq > hostnames.txt
    $ grep -h -e "remote" * | grep -v "random" | grep -v "cert" | grep -v "persist" | awk '{ print $3 }' | sort | uniq > ports.txt

Choose which port to use from "ports.txt", and review and redact "hostnames.txt" as desired. 

    $ cp /home/user/vpnchains/utility_scripts/hostname-ipv4.sh /home/user/vpn0/
    $ cd /home/user/vpn0
    $ ./hostname-ipv4.sh
    $ cat hostname-ipv4.txt | awk '{ print $2 }' | sort | uniq > ipv4.txt

Repeat for vpn1 etc.

Now you have a list of server IPv4 addresses for each VPN service. Obviously, the more IPv4 addresses that you have for each, the more possible chains there will be. Copy them to "/etc/openvpn/scripts/", renaming appropriately.

    # cp /home/user/vpn0/ipv4.txt /etc/openvpn/scripts/vpns0
    # cp /home/user/vpn1/ipv4.txt /etc/openvpn/scripts/vpns1

Create a directory in "/etc/openvpn/" for each VPN service.

    # mkdir /etc/openvpn/vpn0
    # mkdir /etc/openvpn/vpn1

Create these files for each VPN service, as needed. For example:

    /etc/openvpn/vpn0/ca.crt
    /etc/openvpn/vpn0/client.crt
    /etc/openvpn/vpn0/client.key
    /etc/openvpn/vpn0/ta.key
    /etc/openvpn/vpn0/up
    /etc/openvpn/vpn0/base.conf

The certificates and keys come from the OpenVPN configuration files. Most VPN services use the same "ca.crt" and "ta.key" for all servers. But you should verify that. If they're server-specific, just leave them inline.

Many VPN services still use "client.crt" and "client.key", and they're typically client-specific. But there's arguably no need for them, given that client authentication doesn't matter much for VPN services. And indeed, they arguably reduce user privacy. But if they're provided, you must use them.

The "up" file for each VPN service contains the username and password, on separate lines. The "base.conf" file for each contains the shared block from the OpenVPN configuration files, after stripping out "remote *" lines, inline certificates and keys, and the "auth-user-pass" line. 

Now create an OpenVPN configuration file for each server IPv4 address.

    # cp /home/user/vpnchains/openvpn_scripts/write-vpn0-conf.sh /etc/openvpn/scripts/
    # cp /home/user/vpnchains/openvpn_scripts/write-vpn1-conf.sh /etc/openvpn/scripts/

Those scripts specify UDP port 1194, so change as required. Then execute them to create the OpenVPN configuration files.

    # /etc/openvpn/scripts/write-vpn0-conf.sh
    # /etc/openvpn/scripts/write-vpn1-conf.sh

Next add a base init script for each VPN service.

    # cp /home/user/vpnchains/openvpn_scripts/vpn0-base.sh /etc/openvpn/scripts/
    # cp /home/user/vpnchains/openvpn_scripts/vpn1-base.sh /etc/openvpn/scripts/

These won't get run as such. They'll get tweaked, and run on the fly, in the main infinite while loop script. They adjust routing for each VPN server, and then run openvpn to establish the connection. For additional VPNs in the chain, use vpn1-base.sh as the model, and increment the VPN and TUN names (VPN1 to VPN2, and TUN0 to TUN1, and so on). The routes pushed by the final VPN server are not changed.

Then copy the ip6tables rulset and base iptables ruleset to "/etc/iptables/", and restore ip6tables.

    # cp /home/user/vpnchains/iptables/rules.v6 /etc/iptables/
    # cp /home/user/vpnchains/iptables/vpn-rules-base.v4 /etc/iptables/
    # ip6tables-restore < /etc/iptables/rules.v6

All IPv6 traffic gets dropped. As with the VPN init scripts, "vpn-rules-base.v4" doesn't get restored as such. It'll get tweaked and restored on the fly in the main infinite while loop script. 

Finally, copy the main loop script to "/etc/openvpn/scripts/".

    # cp /home/user/vpnchains/openvpn_scripts/vpn-chains.sh /etc/openvpn/scripts/

It's just a simple infinite while loop script:

* terminates all openvpn processes
* uses shuf to randomly select a VPN server IPv4 from each of two lists (vpns0 and vpns1)
* writes an iptables ruleset for the VPN chain, and restores it
* writes an init script for each VPN server, which tweaks routing before connecting
* connects to the first VPN server, and waits five seconds
* connects to the second VPN server, and waits 15 seconds
* pings 1.1.1.1 via the second VPN
* if there's a response, waits 10 minutes, and then restarts the loop
* otherwise restarts the loop

For adding a third VPN to the chain, please see comments in the script.

Run and enjoy.

    # /etc/openvpn/scripts/vpn-chains.sh &

To check status:

    $ ping -fc 10 -I tun2 1.1.1.1
    $ w3m -dump https://ipchicken.com
    $ tail /etc/openvpn/scripts/vpns.log
    $ cat /etc/openvpn/scripts/vpns.log | less

