# References: https://docs.docker.com/engine/install/ubuntu/

#?------------------------------
#? Install using the repository
#?------------------------------
#! Step 1: Update & install required packages
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

#! Step 2: Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg

#! Step 3: Setup repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#?------------------------------
#? Install Docker engine
#?------------------------------
#! Step 1: Install docker engine, containerd
#sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update
#! (Install the latest version)
#sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
#! (Install specific version)
# apt-cache madison docker-ce
DOCKER_VER="5:20.10.17~3-0~ubuntu-jammy"
sudo apt-get install -y docker-ce=$DOCKER_VER docker-ce-cli=$DOCKER_VER containerd.io docker-compose-plugin

#?--------------------------------------------
#? Setup 
#?--------------------------------------------
cat <<EOF | sudo tee /etc/docker/daemon.json
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {
"max-size": "100m"
},
"storage-driver": "overlay2"
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

#?--------------------------------------------
#? Enable non-privileged user to use Docker
#?--------------------------------------------
sudo usermod -aG docker $USER
# Refresh group without logout : https://superuser.com/questions/134406/linux-refreshing-groups-without-having-to-re-login
exec newgrp docker