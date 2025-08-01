# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "geerlingguy/ubuntu2004"
  config.vm.box_version = "1.0.4"
  
  config.vm.hostname = "yolo-server"
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.network "forwarded_port", guest: 3001, host: 3001
  config.vm.network "forwarded_port", guest: 5001, host: 5001
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
    vb.name = "yolo-vm"
  end
  
  # Disabling default vagrant shared folder
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # Provisioning with Ansible
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.inventory_path = "inventory.yml"
    ansible.host_key_checking = false
    ansible.verbose = ""
  end
end