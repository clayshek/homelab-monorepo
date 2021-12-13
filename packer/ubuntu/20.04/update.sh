# install packages and upgrade
echo "==> Updating list of repositories"
apt-get -y update
apt-get -y dist-upgrade

# Clean up the apt cache
apt-get -y autoremove --purge
apt-get -y clean
