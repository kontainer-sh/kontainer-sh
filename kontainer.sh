#!/bin/bash
sudo apt update
sudo apt -y install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubectl
curl -s https://fluxcd.io/install.sh | sudo bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
newgrp docker << FOO
k3d cluster delete --all
k3d registry delete --all
k3d registry create myregistry.localhost --port 5000
k3d cluster create --wait -p "8443:443@loadbalancer" -p "8080:80@loadbalancer" --servers 1 --agents 3 --registry-use myregistry.localhost:5000 --k3s-arg '--kubelet-arg=eviction-hard=imagefs.available<1%,nodefs.available<1%@agent:*' --k3s-arg '--kubelet-arg=eviction-minimum-reclaim=imagefs.available=1%,nodefs.available=1%@agent:*'
export GITHUB_TOKEN=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
flux bootstrap github --owner kontainer-sh --repository test-deployment --personal --private --path ./cluster --branch main --read-write-key --components-extra=image-reflector-controller,image-automation-controller
echo '127.0.0.1 hello-world.local' | sudo tee -a /etc/hosts
FOO
