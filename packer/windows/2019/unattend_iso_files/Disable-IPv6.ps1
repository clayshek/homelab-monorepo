# Script to disale IPv6 as part of template provisioning
# Addresses Packer WinRM bug, Ref: https://github.com/hashicorp/packer/issues/10227
# IPv6 can be reenabled at a later time if desired

Disable-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6