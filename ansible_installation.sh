#!/bin/bash

sudo apt update
sudo apt install -y virtualenv

cd /home/vagrant
virtualenv -p python3 .venv
. .venv/bin/activate
pip install ansible
ansible --version

sudo cp /vagrant/.vagrant/machines/default/virtualbox/private_key /home/vagrant/private_key
sudo chown vagrant:vagrant /home/vagrant/private_key
sudo chmod 400 /home/vagrant/private_key

cat << EOF > hosts
[vagrant]
127.0.0.1 ansible_ssh_user=vagrant ansible_ssh_private_key_file=/home/vagrant/private_key
EOF

ansible -i hosts vagrant -m ping
