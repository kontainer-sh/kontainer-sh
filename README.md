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
* Ready to use database instances (planned)
# Demo
[![asciicast](https://asciinema.org/a/d6BbvWoOZu99bJZvxiWmI3RAh.svg)](https://asciinema.org/a/d6BbvWoOZu99bJZvxiWmI3RAh?autoplay=1)
# Goals and Motivation
This Demo repository will deploy and configure:
* A Tekton CI System (https://tekton.dev/)
* A demo pipeline consisting of the following build stages:
  * Checkout a sample project repository
  * Build a container image using https://buildpacks.io/
  * Push the container image to the local registry
  * Perform a rollout restart
* The pipeline is triggered by a GitHub webhook
* This project is to be expanded into an Open Source PaaS in the future
# Requirements
* Kubernetes (https://kubernetes.io/)
* Flux (https://fluxcd.io/)
* kubectl (https://kubernetes.io/docs/tasks/tools/)
* Tekton Pipelines CLI (https://tekton.dev/docs/cli/)
* A GitHub repository and a personal access token
* An Ingress controller
* A local docker registry
# Installation
Create a new repository on GitHub. This repository needs a new folder named "cluster".
"cluster" gets three new files. In this repository you configure your cluster.

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
        branch: 15-parametrize-hardcoded-settings


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

"url_gitrepo" needs the path to the GitHub repository of the app. So far this needs to be a public repository. 
If the App isn't in the root directory, you need to set the path in "subpath_source".
"wh_secret" needs to be a String, only numbers don't work.

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

Your server needs the following file in the root directory.
 
 `payload.json`
    
    {"ref":"refs/heads/main","repository":{"html_url":"http://test"},"commits":[]}

Now you need to run the script "install.sh" on your server.
    
    ./install.sh Github_token_(classic) owner_of_repo name_of_repo_with_the_cluster_configuration
This will install all the necessary software on your server and configures it.

The webhook for the app repository needs to be added. 

* payload url: Server-IP:8080/hooks
* Contant type: application/json
* secret: wh_secret from kontainer-base.yaml
* Just the push event.
* Active

Now everything is set up and installed.


**_NOTE:_** This guide is in progress. Please look for ongoing development.
# Issues
- Provide a Helm chart for the sample project
- Parametrize several hardcoded values
- Support SSL
# Getting Support
You can use [GitHub Issues](https://github.com/kontainer-sh/kontainer-sh/issues) or contact us via [info@kontainer.sh](mailto:info@kontainer.sh).

Need something that isn't covered here? Visit [kontainer.sh](https://kontainer.sh/devops-insider/) (currently in german language) to subscribe to the free DevOps-Insider Newsletter. You will get even more free resources that save your time and sanity.

Furthermore, you will find tips&tricks that I share nowhere else.
# Contribution
Feel free to fork and create a pull request.
