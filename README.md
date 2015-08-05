# Evercam Gateway

## Summary

This Elixir umbrella project is part of a system designed to discover, route and securely connect LAN devices to the [Evercam.io](https://www.evercam.io) platform. It is principally concerned with connecting cameras, though it is not strictly limited to camera hardware: Any source of image and video data should be routable.

This umbrella project contains two main apps:

*    [Gateway](https://github.com/evercam/evercam-gateway/tree/master/apps/gateway): software designed to run on minimal hardware in a customer's LAN, providing secure routing for cameras on the local network
*    [Gateway VPN Service](https://github.com/evercam/evercam-gateway/tree/master/apps/gateway_vpn_service): software designed to run on (or connected to) a VPN Server which facilitates automation of VPN services for the Gateway software.

These two apps are included within the same project as they share some critical code modules, which it currently does not make sense to release as individual, general purpose modules (though it may in the future).

The overall system further relies on another two elements:

*   [Gateway API](https://github.com/evercam/evercam-gateway-api): an API layer which provides authentication, data storage and communications for the system.
*   [Gateway Dashboard](https://github.com/evercam/evercam-gateway-dashboard): a browser-based dashboard which allows users to approve Gateway devices and connect LAN Cameras to their Evercam.io account.

## Example

A simple example of what the Gateway is intended to achieve. 

Take a LAN where the firewall allows only traffic out on ports 80 and 443 (we'll ignore 53 and so on). On the LAN are 5 IP Cameras. At present it would be necessary to open 10 incoming ports on the firewall and then port-forward all 5 cameras (HTTP and RTSP) on those specific ports. The Evercam Platform then relies on the configuration of the 3rd party router and also on a fixed IP address to access those forwarded cameras. In addition the connection to the cameras is often not secure (plain HTTP). 

This process then is manual, or semi-manual, tedious, unreliable and insecure. Enter the Gateway.

It connects to the API on port 443 (HTTPS) and to the VPN on port 80 (tunnelled). It automatically finds the 5 cameras and detects their configuration. It creates forwarding rules on its own local ports for the 5 cameras (10 ports in all usually, giving access to HTTP and RTSP on each device). These ports are then directly accessible over the VPN by the Evercam Platform which can securely ingest and process media, as well as directly send commands and data to the cameras - again over an encrypted connection.

The Gateway is automatic, reliable and secure.

## Technologies

The Gateway is designed to run on GNU/Linux. It relies on the following:

*    iptables
*    ip
*    openssl
*    dhclient
*    java

It also relies on the [Softether VPN client](http://www.softether.org).

## Why Elixir/Erlang OTP?

*    *Fault tolerance*: The Gateway performs many operations reliant on error-prone responses from external utilities and remote services that may have intermittent reliability. OTP is an obvious choice for this.
*    *Small footprint*: with erlang (erlang-mini), we can achieve a very small distribution size. We want to be able to support minimal hardware.
*    *Performance*: Erlang is fast
*    *Flexibility*: hot swapping of code is considered to be a major future benefit
*    *Maintainability*: creating a system of this complexity in C would be vastly too costly and too hard to maintain. Elixir has the features that we need to create maintainable software
*    *The future*: given that we expect to have a large network of hardware devices in a highly distributed network, it makes sense to use a language that can support multi-node communications out of the box.
