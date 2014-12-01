# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "bn0ir/ubuntu-trusty"
  config.vm.network "private_network", ip: "192.168.200.2"
  config.vm.provision :shell, path: "bootstrap.sh"
  config.vm.provision "shell", path: "restart.sh",
    run: "always"
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end
end
