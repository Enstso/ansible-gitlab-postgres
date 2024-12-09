#!/bin/bash

echo "Starting removal of GitLab EE, GitLab CE, PostgreSQL, Apache2, and Nginx..."

# Function to stop services safely
stop_service() {
    local service_name=$1
    if systemctl is-active --quiet "$service_name"; then
        echo "Stopping $service_name service..."
        sudo systemctl stop "$service_name"
    else
        echo "$service_name service is not running."
    fi
}

# Stop GitLab services
echo "Stopping GitLab services..."
sudo gitlab-ctl stop || echo "GitLab services are already stopped."

# Remove GitLab EE (Enterprise Edition)
echo "Removing GitLab EE..."
sudo apt-get remove --purge -y gitlab-ee || echo "GitLab EE is not installed."

# Remove GitLab CE (Community Edition)
echo "Removing GitLab CE..."
sudo apt-get remove --purge -y gitlab-ce || echo "GitLab CE is not installed."

# Clean up GitLab directories
echo "Cleaning GitLab files and directories..."
sudo rm -rf /etc/gitlab /var/opt/gitlab /var/log/gitlab

# Remove GitLab repository sources
echo "Removing GitLab repository sources..."
sudo rm -f /etc/apt/sources.list.d/gitlab_*.list

# Remove GitLab GPG keys
echo "Removing GitLab GPG keys..."
GPG_KEY=$(sudo apt-key list | grep -B 1 'gitlab.com' | head -n 1 | awk '{print $NF}')
if [[ -n "$GPG_KEY" ]]; then
    sudo apt-key del "$GPG_KEY"
else
    echo "No GitLab GPG key found."
fi

# Stop PostgreSQL service
echo "Stopping PostgreSQL service..."
stop_service postgresql

# Remove PostgreSQL
echo "Removing PostgreSQL..."
sudo apt-get remove --purge -y postgresql* || echo "PostgreSQL is not installed."

# Clean up PostgreSQL directories
echo "Cleaning PostgreSQL files and directories..."
sudo rm -rf /etc/postgresql /var/lib/postgresql /var/log/postgresql

# Stop Apache2 service
echo "Stopping Apache2 service..."
stop_service apache2

# Remove Apache2
echo "Removing Apache2..."
sudo apt-get remove --purge -y apache2* || echo "Apache2 is not installed."

# Clean up Apache2 directories
echo "Cleaning Apache2 files and directories..."
sudo rm -rf /etc/apache2 /var/www/html /var/log/apache2

# Stop Nginx service
echo "Stopping Nginx service..."
stop_service nginx

# Remove Nginx
echo "Removing Nginx..."
sudo apt-get remove --purge -y nginx* || echo "Nginx is not installed."

# Clean up Nginx directories
echo "Cleaning Nginx files and directories..."
sudo rm -rf /etc/nginx /var/www /var/log/nginx

# Perform autoremove and clean package cache
echo "Removing unnecessary dependencies..."
sudo apt-get autoremove -y
echo "Cleaning package cache..."
sudo apt-get clean

# Supprimer les fichiers de sources GitLab
echo "Suppression des fichiers de sources GitLab..."
rm -f /etc/apt/sources.list.d/packages_gitlab_com_gitlab_gitlab_ce_ubuntu.list
rm -f /etc/apt/sources.list.d/packages_gitlab_com_gitlab_gitlab_ee_ubuntu.list

# Supprimer les clés GPG GitLab
echo "Suppression des clés GPG GitLab..."
rm -f /usr/share/keyrings/gitlab_gitlab-ee-archive-keyring.gpg

# Mettre à jour les dépôts pour appliquer les changements
echo "Mise à jour des dépôts..."
apt update

# Mise à jour finale
echo "Mise à jour des paquets..."
apt upgrade -y

# Final verification
echo "Verifying removal..."
dpkg -l | grep -E 'gitlab|postgresql|apache2|nginx' && echo "Some packages are still installed." || echo "GitLab EE, GitLab CE, PostgreSQL, Apache2, and Nginx have been removed successfully."

echo "Removal process completed."
