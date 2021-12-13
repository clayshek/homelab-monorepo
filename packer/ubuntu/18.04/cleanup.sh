echo "==> Cleaning up tmp"
sudo rm -rf /tmp/*

# Cleanup apt cache
sudo apt-get -y autoremove --purge
sudo apt-get -y clean

echo "==> Clearing machine-id"
sudo truncate --size=0 /etc/machine-id