#!/bin/bash
__MINOR_VER=1.28
__VER=1.28.3
__MY_K8S_SETUP_DIR="/opt/k8s-setup"

_____k8s_initial_setup() {
  # Step 1 - Perform update and upgrade to the system
  apt update && apt upgrade -y

  # Step 2 - Install required packages
  apt install curl apt-transport-https vim git wget gnupg2 software-properties-common ca-certificates uidmap lsb-release -y

  # Step 3 - Disable swap
  swapoff -a

  # Step 4 - Load br_netfilter, overlay modules to ensure they are available for the subsequent steps
  modprobe overlay
  modprobe br_netfilter

  # Step 5 - Update kernel networking to allow necessary traffic
  cat << EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

  # Step 6 - Apply sysctl parameters with reboot. Ensure the changes are used by the current kernel as well
  sysctl --system

  # Step 7 - Install the necessary key for the software to install
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Step 8 - Install containerd software
  apt-get update && apt-get install containerd.io -y
  containerd config default | tee /etc/containerd/config.toml
  sed -e "s/SystemdCgroup = false/SystemdCgroup = true/g" -i /etc/containerd/config.toml
  systemctl restart containerd

  # Step 9 - Add repo for Kubernetes
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v$__MINOR_VER/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$__MINOR_VER/deb/ /" >>/etc/apt/sources.list.d/kubernetes.list

  # Step 10 - Install the Kubernetes software, and lock the version
  apt-get update
  apt-get install -y kubeadm kubelet kubectl
  apt-mark hold kubelet kubeadm kubectl
}

#! Check whether k8s is installed or not
if [ ! -d /etc/kubernetes/ ]; then
    if [[ $(whoami) != "root" ]]; then
        echo "Please run as root"
        exit 1
    else
        _____k8s_initial_setup
    fi
else
    echo "Already installed"
    exit 1
fi
