# Chances are if you know what this is for, you've already pulled your hair out

!#/bin/bash

sudo systemctl stop dcos-mesos-slave.service
sudo systemctl stop dcos-mesos-slave-public.service
sudo rm -f /var/lib/dcos/mesos-resources
sudo rm -f /var/lib/mesos/slave/meta/slaves/latest
sudo mkdir -p /dcos/volume0

# /efs is where Amazon EFS has been mounted for Docker external volume storage

sudo dd if=/dev/zero of=/efs/volume0.img bs=1M count=200
sudo losetup /dev/loop0 /efs/volume0.img
sudo mkfs -t ext4 /dev/loop0
sudo losetup -d /dev/loop0
echo "/efs/volume0.img /dcos/volume0 auto loop 0 2" | sudo tee -a /etc/fstab
sudo mount /dcos/volume0
sudo reboot

# Now you're ready to try Rex-ray again until it works.
