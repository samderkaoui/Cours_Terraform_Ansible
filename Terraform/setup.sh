#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x

apt update -y
apt install -y nginx python3 python3-pip git
systemctl start nginx
systemctl enable nginx
pip3 install ansible --break-system-packages
echo "Hello World" > /var/www/html/index.html
