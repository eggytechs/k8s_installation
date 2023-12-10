# REFERENCES: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# Container runtime: https://kubernetes.io/docs/setup/production-environment/container-runtimes/
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cgroup-drivers
# https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/


#?--------------------------------------
#? Update & install required package
#?--------------------------------------

sudo apt update -y
sudo apt install -y apt-transport-https ca-certificates curl gpg
#sudo apt install vim git wget gnupg2 software-properties-common lsb-release uidmap -y

#?-------------------------------------------
#? Download Kubernetes Cloud public signing key
#?-------------------------------------------
#sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

#?---------------------------
#? Add K8s apt repository
#?---------------------------
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

#?----------------------------------
#? Install kubelet,kubeadm,kubectl
#?----------------------------------
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#?----------------------------------
#? Containerd cgroup driver
#?----------------------------------
  # Disable swap
  swapoff -a

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


 # Install the necessary key for the software to install
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt update -y && sudo apt install containerd.io -y
  
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Sleep for 3s to ensure containerd startup properly
sleep 3

#?-----------------------------
#? Init K8s Cluster
#?-----------------------------
sudo kubeadm init  --cri-socket /run/containerd/containerd.sock --pod-network-cidr=192.168.0.0/16 --control-plane-endpoint k8s-cp --upload-certs -v=5 | tee ~/kadm-init.out


#?-----------------------------
#? Install CNI & Untaint node
#?-----------------------------
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml
kubectl taint node $(hostname) node-role.kubernetes.io/master:NoSchedule-
kubectl taint node $(hostname) node-role.kubernetes.io/control-plane:NoSchedule-

#?-----------------------------
#? Setup .kube/config file
#?-----------------------------
#mkdir -p $HOME/.kube
#sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#sudo chown $(id -u):$(id -g) $HOME/.kube/config

#?--------------------------------
#? Setup kubectl autocompletion
#?--------------------------------
#echo "source <(kubectl completion bash)" >> ~/.bashrc
#echo "alias k=kubectl" >> ~/.bashrc
#echo "complete -o default -F __start_kubectl k" >> ~/.bashrc
#source <(kubectl completion bash)

