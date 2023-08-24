# kontainer.sh
K8s powered `git push` deployments.
# Project Status
ALPHA
# Features
* Deploy your applications written in various languages without hassle
* Install your environment in less than one hour
* Create new projects quickly
* Integration with GitHub
* Automatically deploy on new commits - Just push to Git
* Deploy anywhere on any Kubernetes cluster and cloud provider (no lock-in)
* Avoid complex setup and DevOps tasks
* More coding time instead of solving infrastructure problems
* Focus on building your application and get results
* Ready-to-use database instances (planned)


# Goals and Motivation
This demo repository will deploy and configure:
* A Tekton CI System (https://tekton.dev/)
* A demo pipeline consisting of the following build stages:
  * Checkout a sample project repository
  * Build a container image using https://buildpacks.io/
  * Push the container image to the local registry
  * Perform a rollout restart
* The pipeline is triggered by a GitHub webhook
* This project is to be expanded into an Open Source PaaS in the future
# Requirements
* macOS
* A GitHub repository and a personal access token
* An account at AWS (Amazon Web Services)

# AWS Server-Setup with Terraform

To set up the server from scratch on AWS, you can use Terraform. 
To begin, you need the necessary software on your computer. 
First, install Terraform with brew on your terminal.

    brew tap hashicorp/tap  
    brew install hashicorp/tap/terraform

After that, we need to install AWS CLI and configure it. 
For the configuration, you need your AWS access key.

    brew install awscli
    aws configure

Configuration example:

    Default region: eu-central-1
    Default output format: yaml

After that, you need to export your AWS access key.

    export AWS_ACCESS_KEY_ID=yourID
    export AWS_SECRET_ACCESS_KEY=yourSecret

Now you need to create a directory for Terraform files and copy the file "main.tf" from the directory "terraform" in this project to your folder. 
With this file, you will create an Ubuntu server in the "eu-central-1" region with 20GB disk space and ports 22, 443, and 80 open. 
If you want to change the region, you need to modify it in "main.tf," and you need to change the AMI. 
The server will be reachable via SSH, and the script will look for your public key file in the directory "~/.ssh". 
If your public key is in a different directory, you need to change this directory in "main.tf" before you can run the script.

Back in the terminal, you need to run the following commands:

    terraform init
	terraform validate
 	terraform plan
	terraform apply

"terraform init" is only necessary the first time you want to run Terraform. 
"terraform validate" checks if "main.tf" makes sense. 
With "terraform plan," you test everything and get a plan about what will be done without the possibility of implementing it. 
With "terraform apply," you get the plan of what will be done, and you need to confirm it. 
After that, the changes will take place. 
At the end, you will see the IP address of the server.

Now the server is set up for the installation.

# Installation

Create a new repository on GitHub. 
This repository needs a new folder named "cluster," which gets three new files. 
In this repository, you configure your cluster:

`git-repository.yaml`

    apiVersion: source.toolkit.fluxcd.io/v1beta2
    kind: GitRepository
    metadata:
      name: kontainer-sh
      namespace: flux-system
    spec:
      interval: 5m
      url: https://github.com/kontainer-sh/kontainer-sh.git
      ref:
        branch: main


`kontainer-base.yaml`

    apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
    kind: Kustomization
    metadata:
      name: kontainer-base
      namespace: flux-system
    spec:
      interval: 5m
      path: ./kontainer-base
      prune: true
      validation: client
      sourceRef:
        kind: GitRepository
        name: kontainer-sh
      postBuild:
        substitute:
        url_gitrepo: "https://github.com/$USER/$AppRepo.git"
        subpath_source: "."
        wh_secret: "topsecret"

"url_gitrepo" needs the path to the GitHub repository of the app. 
So far, this needs to be a public repository. 
If the App isn't in the root directory, you need to set the path in "subpath_source." 
"wh_secret" needs to be a String; only numbers don't work.

`sample-frontend.yaml`

    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    metadata:
      name: sample-app
      namespace: default
    spec:
      interval: 5m
      releaseName: sample-app
      chart:
        spec:
          chart: charts/test-app
          sourceRef:
            kind: GitRepository
            name: kontainer-sh
            namespace: flux-system
      values:
        host: foo.bar.com
        issuer: staging-issuer #prod-issuer
        secretName: staging-issuer #prod-issuer

In values, you need to enter the host where the app will be found. 
With this configuration, the cert-manager will use the staging API from Let's Encrypt. 
If you want to use the production API, you need to change the issuer and the secretName to "prod-issuer."

Your server needs the following file in the root directory.
 
 `payload.json`
    
    {"ref":"refs/heads/main","repository":{"html_url":"http://test"},"commits":[]}

Now you need to run the script "install.sh" on your server. 
To do so, you need to copy the script to your server, and it needs the necessary rights.
    
    chmod 775 install.sh
After that, you run the script with its three arguments.
    
    ./install.sh Github_token_(classic) owner_of_repo name_of_repo_with_the_cluster_configuration
This will install all the necessary software on your server and configure it.

The webhook for the app repository needs to be added on GitHub with the following configuration:

* payload URL: Server-IP/hooks
* Content type: application/json
* secret: wh_secret from kontainer-base.yaml
* Just the push event.
* Active

Now everything is set up and installed. 
To trigger the first installation of the app, you need to wait for the pod "el-trigger-demo-el-xxx" to be ready. 
After the pod is ready, you need to trigger a push event in your GitHub repository with your app code. 
After a while, your app pod gets the status "running," and after that, everything is ready.



**_NOTE:_** This guide is in progress. Please look for ongoing development.

# Getting Support
You can use [GitHub Issues](https://github.com/kontainer-sh/kontainer-sh/issues) or contact us via [info@kontainer.sh](mailto:info@kontainer.sh).

Need something that isn't covered here? Visit [kontainer.sh](https://kontainer.sh/devops-insider/) (currently in the German language) to subscribe to the free DevOps-Insider Newsletter. You will get even more free resources that save your time and sanity.

Furthermore, you will find tips & tricks that I share nowhere else.
# Contribution
Feel free to fork and create a pull request.
