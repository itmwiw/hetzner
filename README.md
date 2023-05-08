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
### cloudhelper
sudo systemctl disable systemd-resolved && systemctl stop systemd-resolved
rm /etc/resolv.conf
sudo DEBIAN_FRONTEND=noninteractive apt -yq install dnsmasq
cat << "EOF" | sudo tee /etc/dnsmasq.conf
listen-address=::1,127.0.0.1,10.0.0.4
server=8.8.8.8
server=4.4.4.4
address=/.apps.okd.internal.com/10.0.0.2
EOF
sudo echo nameserver 127.0.0.1 > /etc/resolv.conf
append etc/hosts
10.0.0.3 api-int.okd.internal.com
10.0.0.3 api.okd.internal.com
10.0.0.2 *.apps.okd.internal.com
10.0.0.6 bootstrap.okd.internal.com
10.0.0.8 master0.okd.internal.com
10.0.0.5 master1.okd.internal.com
10.0.0.7 master2.okd.internal.com

### vm-ubuntu
ip route add default via 10.0.0.1
sudo systemd-resolve --interface ens10 --set-dns 10.0.0.253 --set-domain yourdomain.local
or resolvectl ...
- persistent -
sudo nmcli connection modify "Wired connection 1" ipv4.dns "10.0.0.4"
sudo systemctl restart NetworkManager
- ubuntu -
echo DNS=10.0.0.253 >> /etc/systemd/resolved.conf
systemctl restart systemd-resolved


# Provisioner

## Prepare Coreos-installer binary
apt-get -y install libzstd-dev libssl-dev pkg-config
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > cargo.sh
chmod +x cargo.sh
./cargo.sh -y
source "$HOME/.cargo/env"
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
baseDomain: internal.com
metadata:
  name: okd
compute:
- name: worker
  replicas: 3
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
### install hcloud
wget https://github.com/hetznercloud/cli/releases/download/v1.32.0/hcloud-linux-amd64.tar.gz
tar -xvf hcloud-linux-amd64.tar.gz
sudo mv hcloud /usr/local/bin
### install apache
sudo apt update -y
sudo apt install -y apache2
sudo sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
#sudo ufw app list
#sudo ufw allow 'Apache'
sudo ufw allow 8080
sudo ufw status
sudo systemctl restart apache2

# Pritunl ubuntu 22.04
sudo apt update -q
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq  upgrade
sudo apt install wget vim curl gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
sudo tee /etc/apt/sources.list.d/pritunl.list << EOF
deb https://repo.pritunl.com/stable/apt jammy main
EOF
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
-- Before we add the MongoDB repositories, we need to force libssl1.1 installation from the Ubuntu 21.10 repository --
echo "deb http://security.ubuntu.com/ubuntu focal-security main" | sudo tee /etc/apt/sources.list.d/focal-security.list
sudo apt update
sudo apt install libssl1.1
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

sudo apt update -q -y
sudo apt install -y pritunl mongodb-org
sudo systemctl start pritunl mongod
sudo systemctl enable pritunl mongod

# Cilium + hccm
cat << "EOF" | sudo tee install-config.yaml
apiVersion: v1
baseDomain: internal.com
metadata:
  name: okd
compute:
- name: worker
  replicas: 3
  metadata:
    labels:
      cloud-provider: hccm
controlPlane:
  name: master
  replicas: 3
  metadata:
    labels:
      cloud-provider: hccm
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: Cilium
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
fips: false
pullSecret: '{"auths":{"fake":{"auth":"aWQ6cGFzcwo="}}}'
sshKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/dWjs+ZIdD3glfevXkLs9dqnp/i7xGi5kXytrbHzZb tarik.haddouchi@advatys.com'
EOF
mkdir okd
cp install-config.yaml ./okd
openshift-install create manifests --dir=okd/

cilium_version='1.13.0'
git_dir='/tmp/cilium-olm'
CLUSTER_NAME=okd
git clone https://github.com/cilium/cilium-olm.git $git_dir
cp $git_dir/manifests/cilium.v$cilium_version/* ${CLUSTER_NAME}/manifests
test -d $git_dir && rm -rf -- $git_dir
sed -i 's|image:\ registry.connect.redhat.com/isovalent/cilium-olm@sha256:aed05a332413c8244b615d6b2f013e4fbc5ce7f65ed7f83213bc3605ae4dedce|image:\ quay.io/cilium/cilium-olm@sha256:78c47222700d2a552972d5a46e5b0297dec166e236e880190aab69f90df62979|g' \
  ${CLUSTER_NAME}/manifests/cluster-network-06-cilium-00002-cilium-olm-deployment.yaml \
  ${CLUSTER_NAME}/manifests/cluster-network-06-cilium-00014-cilium.*-clusterserviceversion.yaml
  
cat << 'EOF' > ${CLUSTER_NAME}/openshift/99_cloudprovider_external.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: KubeletConfig
metadata:
  name: cloudprovider-external
spec:
  machineConfigPoolSelector:
    matchLabels:
      cloud-provider: hccm
  kubeletConfig:
    cloudProvider: external
EOF
cat << 'EOF' > ${CLUSTER_NAME}/manifests/ccm-00-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    openshift.io/node-selector: ""
  labels:
    name: hcloud-cloud-controller-manager
    openshift.io/cluster-logging: "true"
    openshift.io/cluster-monitoring: "true"
    openshift.io/run-level: "0"
  name: hcloud-cloud-controller-manager
EOF
cat << 'EOF' > ${CLUSTER_NAME}/manifests/ccm-01-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: hcloud
  namespace: hcloud-cloud-controller-manager
stringData:
  token: ${var.hcloud_token}
EOF
wget https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/latest/download/ccm.yaml -O okd/manifests/ccm-02-deployment.yaml
sed -i 's|namespace:\ kube-system|namespace:\ hcloud-cloud-controller-manager|g' okd/manifests/ccm-02-deployment.yaml



./openshift-install create ignition-configs --dir=okd/