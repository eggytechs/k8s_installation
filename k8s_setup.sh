# REFERENCES: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# Container runtime: https://kubernetes.io/docs/setup/production-environment/container-runtimes/ 

#?------------------------------------------------------
#? Forward IPv4, letting iptables see bridged traffic
#?------------------------------------------------------
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

#?--------------------------------------
#? Update & install required package
#?--------------------------------------
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
#?-------------------------------------------
#? Download Google Cloud public signing key
#?-------------------------------------------
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

#?---------------------------
#? Add K8s apt repository
#?---------------------------
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

#?----------------------------------
#? Install kubelet,kubeadm,kubectl
#?----------------------------------
sudo apt-get update
# sudo apt-get install -y kubelet kubeadm kubectl
K8S_VERSION=1.24.2-00
K8S_VER=v1.24.2
sudo apt-get install -y kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION
sudo apt-mark hold kubelet kubeadm kubectl

#?----------------------------------
#? Containerd cgroup driver
#?----------------------------------
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd 

# Sleep for 3s to ensure containerd startup properly
sleep 3

#?-----------------------------
#? Init K8s Cluster
#?-----------------------------
sudo kubeadm init --kubernetes-version=$K8S_VER  --cri-socket /run/containerd/containerd.sock --pod-network-cidr=10.10.0.0/16 --upload-certs -v=5 | tee ~/kadm-init.out

#?-----------------------------
#? Setup .kube/config file
#?-----------------------------
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#?-----------------------------
#? Install CNI & Untaint node
#?-----------------------------
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl taint node $(hostname) node-role.kubernetes.io/master:NoSchedule-
kubectl taint node $(hostname) node-role.kubernetes.io/control-plane:NoSchedule-

#?--------------------------------
#? Setup kubectl autocompletion
#?--------------------------------
echo "source <(kubectl completion bash)" >> ~/.bashrc
source <(kubectl completion bash)