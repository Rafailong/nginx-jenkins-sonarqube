# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  config.vm.box = "Debian72VB43"

  config.vm.network "public_network"


  # neo4j webadmin port
  config.vm.network :forwarded_port, guest: 7474, host: 7474

  # node app port
  config.vm.network :forwarded_port, guest: 80, host: 3000

  # neo4j webadmon port
  # config.vm.network :forwarded_port, guest: 7474, host: 3001

  config.vm.synced_folder "infraestructure/puppet/files", "/files"
  
  config.vm.synced_folder "../app", "/app"

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "infraestructure/puppet/manifests"
    puppet.manifest_file  = "default.pp"
    #puppet.options = ["--fileserverconfig=infraestructure/puppet/files/fileserver.conf"]
  end
end
