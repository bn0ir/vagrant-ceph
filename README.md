vagrant-ceph
============

Vagrant ceph single machine template

To start VM:

1. install virtualbox 4.3 (for windows <= 4.3.12): https://www.virtualbox.org/wiki/Downloads;
2. install vagrant: http://www.vagrantup.com/downloads.html;
3. add vagrant to PATH (windows)
4. execute: vagrant box add bn0ir/ubuntu-trusty
5. execute: vagrant up

VM IP: 192.168.200.2

Bootstrap script creates s3.key file with auth parameters