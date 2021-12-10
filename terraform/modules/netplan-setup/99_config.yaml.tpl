network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses:
        - ${netplan_static_ip_and_mask}
      gateway4: ${netplan_default_gateway}
      dhcp4: false
      nameservers:
          search: [${netplan_dns_search_suffix}]
          addresses: [${netplan_dns_server}]