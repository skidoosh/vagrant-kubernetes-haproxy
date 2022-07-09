# -*- mode: ruby -*-
# vi: set ft=ruby :

NUM_WORKER_NODES=2
IP_START=13
IP_LOADBALANCER="172.16.20.12"
IP_KUBE_CONTROLLER="172.16.20.13"
IP_KUBE_WORKERS="172.16.20."
IP_CONSUL="172.16.20.10"
IP_VAULT="172.16.20.11"


Vagrant.configure("2") do |config|
  config.vm.provision "shell", env: {"IP_CONSUL" => IP_CONSUL,
                                     "IP_VAULT" => IP_VAULT,
                                     "IP_LOADBALANCER" => IP_LOADBALANCER,
                                     "IP_KUBE_CONTROLLER" => IP_KUBE_CONTROLLER, 
                                     "IP_KUBE_WORKERS" => IP_KUBE_WORKERS, 
                                     "NUM_WORKER_NODES" => NUM_WORKER_NODES,
                                     "IP_START" => IP_START}, 
                               inline: <<-SHELL
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get install -y apt-transport-https ca-certificates curl jq

    echo "$IP_CONSUL consul" >> /etc/hosts
    echo "$IP_VAULT vault" >> /etc/hosts
    echo "$IP_LOADBALANCER loadbalancer" >> /etc/hosts
    echo "$IP_KUBE_CONTROLLER controller" >> /etc/hosts
    for i in $(seq 1 $NUM_WORKER_NODES); do
      echo "$IP_KUBE_WORKERS$((IP_START + i)) worker-${i}" >> /etc/hosts
    done
  SHELL

  config.vm.box = "ubuntu/focal64"
  config.vm.box_check_update = true

  # WIP
  # config.vm.define "consul" do |consul|
  #   consul.vm.hostname = "consul"
  #   consul.vm.network "private_network", ip: IP_CONSUL
  #   consul.vm.provider "virtualbox" do |vb|
  #       vb.memory = 1024
  #       vb.cpus = 1
  #   end

  #   consul.vm.provision "shell", path: "scripts/consul.sh"
  # end

  config.vm.define "vault" do |vault|
    vault.vm.hostname = "vault"
    vault.vm.network "private_network", ip: IP_VAULT
    vault.vm.provider "virtualbox" do |vb|
        vb.memory = 1024
        vb.cpus = 1
    end

    vault.vm.provision "shell", path: "scripts/vault.sh"
    vault.vm.provision "shell", path: "scripts/vault_unseal.sh", run: "always"
  end

  config.vm.define "controller" do |controller|
    controller.vm.hostname = "controller"
    controller.vm.network "private_network", ip: IP_KUBE_CONTROLLER
    controller.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
        vb.cpus = 2
    end

    controller.vm.provision "shell", path: "scripts/common.sh"
    controller.vm.provision "shell", path: "scripts/controller.sh", env: {"CONTROLLER_IP" => IP_KUBE_CONTROLLER, 
                                                                          "POD_CIDR" => "192.168.0.0/16"}
  end

  (1..NUM_WORKER_NODES).each do |i|
    config.vm.define "worker-#{i}" do |worker|
      worker.vm.hostname = "worker-#{i}"
      worker.vm.network "private_network", ip: IP_KUBE_WORKERS + "#{IP_START + i}"
      worker.vm.provider "virtualbox" do |vb|
          vb.memory = 2048
          vb.cpus = 1
      end

      worker.vm.provision "shell", path: "scripts/common.sh"
      worker.vm.provision "shell", path: "scripts/worker.sh"
    end
  end

  config.vm.define "loadbalancer" do |loadbalancer|
    loadbalancer.vm.hostname = "loadbalancer"
    loadbalancer.vm.network "private_network", ip: IP_LOADBALANCER
    for i in 8000..10000
      loadbalancer.vm.network :forwarded_port, guest: i, host: i
    end
    loadbalancer.vm.provider "loadbalancer" do |vb|
        vb.memory = 1024
        vb.cpus = 1
    end

    loadbalancer.vm.provision "shell", path: "scripts/loadbalancer.sh", env: {"NUM_WORKER_NODES" => NUM_WORKER_NODES, 
                                                                              "IP_KUBE_WORKERS" => IP_KUBE_WORKERS, 
                                                                              "IP_START" => IP_START}
  end

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end
end