# References: https://docs.docker.com/engine/install/ubuntu/

#?------------------------------
#? Install using the repository
#?------------------------------
#! Step 1: Update & install required packages
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

#! Step 2: Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

#! Step 3: Setup repository
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#?------------------------------
#? Install Docker engine
#?------------------------------
#! Step 1: Install docker engine, containerd
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#?--------------------------------------------
#? Enable non-privileged user to use Docker
#?--------------------------------------------
# sudo usermod -aG docker $USER
# Refresh group without logout : https://superuser.com/questions/134406/linux-refreshing-groups-without-having-to-re-login
# newgrp docker
