# install packages and upgrade
echo "==> Updating list of repositories"
sudo apt-get -y update
sudo apt-get -y dist-upgrade

# Clean up the apt cache
sudo apt-get -y autoremove --purge
sudo apt-get -y clean