#!/bin/bash

#This script needs three parameters to run:
#GitHub-token; Owner of the repository; name of the repository with the configuration of the cluster

#If docker is installed, the installation gets skipped
if which docker > /dev/null; then
	echo "docker is already installed"
else
	#Step 1.1
	sudo apt-get update
	sudo apt-get install ca-certificates curl gnupg

	#Step 1.2
	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg

	#Step 1.3
	echo \
  	"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

	#Installing the Docker Engine
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi


#Step 2
sudo usermod -aG docker $USER
newgrp docker <<DOCKER

if which kubectl > /dev/null; then
	echo "kubectl is already installed"
else
	#Step 3
	sudo apt-get update && sudo apt-get install -y apt-transport-https
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /usr/share/keyrings/kubernetes.gpg
	echo "deb [arch=amd64 signed-by=/usr/share/keyrings/kubernetes.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
	sudo apt-get update
	sudo apt-get install -y kubectl
fi

if which flux > /dev/null; then
	echo "flux is already installed"
else
	#Step 4
	curl -s https://fluxcd.io/install.sh | sudo bash

	#Step 5
	curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

#Step 9
k3d cluster delete --all
k3d registry delete --all
k3d registry create myregistry.localhost --port 5000
k3d cluster create --wait -p "443:443@loadbalancer" -p "80:80@loadbalancer" --servers 1 --agents 3 --registry-use myregistry.localhost:5000 --k3s-arg '--kubelet-arg=eviction-hard=imagefs.available<1%,nodefs.available<1%@agent:*' --k3s-arg '--kubelet-arg=eviction-minimum-reclaim=imagefs.available=1%,nodefs.available=1%@agent:*'

#Step 10
export GITHUB_TOKEN=$1
flux bootstrap github --owner $2 --repository $3 --personal --private --path ./cluster --branch main --read-write-key --components-extra=image-reflector-controller,image-automation-controller
DOCKER
