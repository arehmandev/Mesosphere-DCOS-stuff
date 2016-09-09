# Vagrantfile for quickly setting up a local Minimesos environment
# Shoutout to github.com/frankscholten
# Marathon is on port 10.11.12.13:8080

Vagrant.configure(2) do |config|
 config.vm.box = "ubuntu/trusty64"
 config.vm.network "private_network", ip: "10.11.12.13"
 config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
  end
 config.vm.provision "shell", privileged: false, inline: <<-SHELL
   curl https://get.docker.com/ | sh
   curl -sSL https://minimesos.org/install | sh
   sudo /home/vagrant/.minimesos/bin/minimesos init
   sudo /home/vagrant/.minimesos/bin/minimesos up --mapPortsToHost
 SHELL
end
