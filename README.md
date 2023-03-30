# Networking and DNS

## NAT Gateway
sudo apt update -q
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq  upgrade
sudo echo 1 > /proc/sys/net/ipv4/ip_forward
sudo ip_forward="net.ipv4.ip_forward=1"; sed -i "/^#$ip_forward/ c$ip_forward" /etc/sysctl.conf
sudo DEBIAN_FRONTEND=noninteractive apt -yq install iptables-persistent
sudo iptables -t nat -A POSTROUTING -s '10.0.0.0/16' -o eth0 -j MASQUERADE
sudo iptables-save
## DNS
sudo apt install bind9 -y

# Provisioner

## Prepare Coreos-installer binary
sudo apt-get install libzstd-dev libssl-dev
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
apt install cargo
cargo install --target-dir . coreos-installer
## Hetzner public ssh key
cat << "EOF" | sudo tee ssh_public_key
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/dWjs+ZIdD3glfevXkLs9dqnp/i7xGi5kXytrbHzZb tarik.haddouchi@advatys.com
EOF
## Instal oc and openshift installer
wget https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz
tar xvf oc.tar.gz
sudo mv oc /usr/local/bin
sudo mv kubectl /usr/local/bin
oc adm release extract --command=openshift-install --to ./ quay.io/openshift/okd:4.12.0-0.okd-2023-03-18-084815
sudo cp openshift-install /usr/local/bin
## Generate ignition files
cat << "EOF" | sudo tee install-config.yaml
apiVersion: v1
baseDomain: hatred.world
metadata:
  name: okd
compute:
- name: worker
  replicas: 1
controlPlane:
  name: master
  replicas: 3
networking:
  clusterNetwork:
  - cidr: 10.140.0.0/14
    hostPrefix: 23
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.40.0.0/16
platform:
  none: {}
fips: false
pullSecret: '{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}'
sshKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/dWjs+ZIdD3glfevXkLs9dqnp/i7xGi5kXytrbHzZb tarik.haddouchi@advatys.com'
EOF
mkdir okd
cp install-config.yaml ./okd
./openshift-install create manifests --dir=okd/
./openshift-install create ignition-configs --dir=okd/
## Provision nodes
mkdir terraform


