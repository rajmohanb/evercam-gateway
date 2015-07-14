# Gateway VPN Service

## Summary

This Elixir application is one part of a system designed to discover, route and securely connect LAN devices to the [Evercam.io](https://www.evercam.io) platform. 

The Gateway VPN Service is designed to run on (or connected to) a VPN Server, which provides connectivity between Evercam services and Gateway devices on the LAN.

The Gateway VPN Service's overall function is to automate VPN services for Gateway devices connecting to the system. It performs the following functions:

*    Creates user accounts for connecting devices
*    Generates Public/Private Key Pairs for authentication
*    Assigns a unique hardware address (MAC address) to virtual NIC on Gateway device. This is the NIC used to connect the device to the VPN.
*    Creates a static DHCP lease for a connecting device. This ensures that devices connecting can use DHCP to self-configure networking on the VPN and still consistently have a static IP address on the VPN.
*    Assigns a unique hostname to the connecting Gateway device. This allows Evercam services to connect to a Gateway using a hostname, instead of an IP address.
*    For publicly bound routing rules the VPN Service creates forwarding rules which route incoming internet traffic to Gateway devices (which in turn route to LAN devices).

It is important to note that the VPN service only communicates directly with the Gateway API.  
