#!/bin/bash
#
# Setup for vault servers

set -euxo pipefail

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y consul
sudo apt-mark hold consul

sudo tee /etc/consul.d/consul.hcl > /dev/null <<-CONFIG
  ui_config{
    enabled = true
  }

  datacenter = "vagrant"
  data_dir = "/opt/consul"
  client_addr = "0.0.0.0"
  server = true
  bind_addr = "0.0.0.0"
  advertise_addr = "127.0.0.1"
CONFIG

sudo systemctl daemon-reload
sudo systemctl start consul
sudo systemctl enable consul
