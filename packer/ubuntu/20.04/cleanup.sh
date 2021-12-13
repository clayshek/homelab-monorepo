echo "==> Cleaning up tmp"
rm -rf /tmp/*

# Cleanup apt cache
echo '==> Cleaning up apt cache'
apt-get -y autoremove --purge
apt-get -y clean

# Reset machine ID
echo '==> Clearing machine-id'
truncate --size=0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Cleans SSH keys.
echo '==> Cleaning SSH keys ...'
rm -f /etc/ssh/ssh_host_*

# Sets hostname to localhost.
echo '==> Setting hostname to localhost ...'
cat /dev/null > /etc/hostname
hostnamectl set-hostname localhost

# Enable Proxmox ConfigDrive to be used
echo '==> Enable ConfigDrive usage'
mv /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg.orig
cat << EOF > /etc/cloud/cloud.cfg.d/99-pve.cfg
datasource_list: [ConfigDrive, NoCloud]
EOF

# Remove Netplan files
rm -f /etc/netplan/00-installer-config.yaml
rm -f /etc/netplan/50-cloud-init.yaml
# Ref: https://www.burgundywall.com/post/using-cloud-init-to-set-static-ips-in-ubuntu-20-04

# Cleanup Cloud-Init
echo '==> Cleaning up cloud-init'
cloud-init clean
