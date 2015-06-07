#!/usr/bin/python

import pypureomapi
import struct
import os
import sys

KEYNAME="defomapi"
BASE64_ENCODED_KEY=os.environ['OMAPI_SECRET_KEY']

lease_ip = sys.argv[1] # ip of some host with a dhcp lease on your dhcp server
mac_address = sys.argv[2]
host_name = sys.argv[3]
dhcp_server_ip="127.0.0.1"
port = 7911 # Port of the omapi service

try:
    omapi = pypureomapi.Omapi(dhcp_server_ip,port, KEYNAME, BASE64_ENCODED_KEY)
    omapi.add_host_supersede_name(lease_ip,mac_address,host_name)
    print "Static lease added"
    exit(0)  
except pypureomapi.OmapiError, err:
    print "An error occured: %r" % (err,)
    exit(1)

