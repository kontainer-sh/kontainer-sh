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

Now you need to create a directory for Terraform files and copy the file "main.tf", "terraform.tfvars" and "vars.tf" 
from the directory "terraform" in this project to your folder. In "terraform.tfvars" are variables that can be changed to your liking. 
With all these files, you will create an Ubuntu server in the "eu-central-1" region with 20GB disk space and ports 22, 443, and 80 open. 
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

# Installation (Part one)

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
          app_name: "hello-world"
          app_image: "k3d-myregistry.localhost:5000/hello-world:1.0"
          cm_email: "foo@bar.com"

"url_gitrepo" needs the path to the GitHub repository of the app. 
So far, this needs to be a public repository. 
If the App isn't in the root directory, you need to set the path in "subpath_source." 
"wh_secret" needs to be a String; only numbers don't work.
"cm_email" is the e-mail-address for cert-manager. 
This address will get notifications, for example when a certificate gets old.

`helm-frontend.yaml`

    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    metadata:
      name: app
      namespace: default
    spec:
      interval: 5m
      releaseName: app
      chart:
        spec:
          chart: charts/app
          sourceRef:
            kind: GitRepository
            name: kontainer-sh
            namespace: flux-system
      values:
        host: foo.bar.com
        issuer: staging-issuer #prod-issuer
        secretName: staging-issuer #prod-issuer
        appname: hello-world
        appimage: k3d-myregistry.localhost:5000/hello-world:1.0

In values, you need to enter the host where the app will be found. 
With this configuration, the cert-manager will use the staging API from Let's Encrypt. 
If you want to use the production API, you need to change the issuer and the secretName to "prod-issuer."

## DB-Setup

If your app uses a database, you need to add the following files to the cluster repository to install MariaDB. If you don't need a database,
you can skip this step and continue with "Installation (part two)".

`db-helm.yaml`

    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    metadata:
      name: maria-database
      namespace: default
    spec:
      interval: 5m
        chart:
          spec:
            chart: mariadb
            version: '13.1.x'
            sourceRef:
              kind: HelmRepository
              name: maria-database
              namespace: flux-system
            interval: 1m
        values:
          auth:
            rootPassword: password
          replicaCount: 1

Under rootPassword you set the password for the user "root". You need this information for the connection setup in your app.

`db-source.yaml`

    apiVersion: source.toolkit.fluxcd.io/v1beta2
    kind: HelmRepository
    metadata:
      name: maria-database
      namespace: flux-system
    spec:
      type: oci
      interval: 5m0s
      url: oci://registry-1.docker.io/bitnamicharts

The database is reachable under the name "maria-database-mariadb.default.svc.cluster.local" and the port is 3306. 
The name of the database is "my_database". The username is "root" and the password is set in "db-helm.yaml". Here is an example
of the application.properties from a springboot project.

`application.properties`

    spring.datasource.url=jdbc:mariadb://maria-database-mariadb.default.svc.cluster.local:3306/my_database
    spring.datasource.username=root
    spring.datasource.password=password
    spring.jpa.generate-dll=true
    spring.jpa.hibernate.dll-auto=create-drop

In this file the table of the database gets dropped and created everytime you start the app anew, so it's just for test purposes.
Now you should have five files in the cluster repository, and you can continue with the installation.

# Installation (part two)

Now you need to run the script "install.sh" on your server. 
To do so, you need to copy the script to your server, and it needs the necessary rights.
    
    chmod 775 install.sh
After that, you run the script with its three arguments.
    
    ./install.sh Github_token_(classic) owner_of_repo name_of_repo_with_the_cluster_configuration
This will install all the necessary software on your server and configures it.

The webhook for the app repository needs to be added on GitHub with the following configuration:

* payload URL: Server-IP/hooks
* Content type: application/json
* secret: wh_secret from kontainer-base.yaml
* Just the push event.
* Active

Now everything is set up and installed. 
To trigger the first installation of the app, you need to wait for the pod "el-trigger-el-xxx" to be ready. 
After the pod is ready, you need to trigger a push event in your GitHub repository with your app code. 
After a while, your app pod gets the status "running," and after that, everything is ready.



**_NOTE:_** This guide is in progress. Please look for ongoing development.

# Getting Support
You can use [GitHub Issues](https://github.com/kontainer-sh/kontainer-sh/issues) or contact us via [info@kontainer.sh](mailto:info@kontainer.sh).

Need something that isn't covered here? Visit [kontainer.sh](https://kontainer.sh/devops-insider/) (currently in the German language) to subscribe to the free DevOps-Insider Newsletter. You will get even more free resources that save your time and sanity.

Furthermore, you will find tips & tricks that I share nowhere else.
# Contribution
Feel free to fork and create a pull request.
