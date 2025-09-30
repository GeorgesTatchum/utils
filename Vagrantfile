# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "boxen/debian-13"
  config.vm.box_version = "2025.08.20.12"

  config.vm.define "linux_formation" do |linux_formation|
    linux_formation.vm.hostname = "linux-formation"
  end

  config.vm.synced_folder "./linux_data/", "/vagrant/linux_data"

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
    # Customize the amount of memory on the VM:
    vb.memory = "1024"
  end
end
