# Evercam Gateway

## Summary

This Elixir application is one part of a system designed to discover, route and securely connect LAN devices to the [Evercam.io](https://www.evercam.io) platform. 

This particular application is designed to run on minimal hardware sitting in the customer's LAN. It performs the following functions:

*    Announces itself to the (remote) Gateway API, awaiting verification by customer
*    Authenticates with the Gateway API
*    Configures itself based on configuration data supplied by the Gateway API
*    Joins Evercam VPN
*    Discovers local devices/cameras
*    Polls API for new routing rules
*    Adds and removes routing rules to the OS as directed by API

The other two main parts of the system are the [Gateway API](https://github.com/evercam/evercam-gateway-api) itself and the Gateway-VPN-Service which is part of the umbrella project which contains this app.

