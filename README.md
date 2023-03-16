# kontainer.sh
K8s powered `git push` deployments.
# Project status
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
[![asciicast](https://asciinema.org/a/d6BbvWoOZu99bJZvxiWmI3RAh.svg)](https://asciinema.org/a/d6BbvWoOZu99bJZvxiWmI3RAh)
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
Set GitHub personal access token:

    export GITHUB_TOKEN=<token>

Install Flux components with Flux bootstrap:

    flux bootstrap github \
    --owner kontainer-sh \
    --repository flux-test \
    --personal \
    --private \
    --path ./cluster \
    --branch main \
    --read-write-key \
    --components-extra=image-reflector-controller,image-automation-controller

The above command creates the GitHub repository (if it doesn’t exist).

Push the following files into the repository:

`cluster/git-repository.yaml`

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

`cluster/kontainer-base.yaml`

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

(...)

**_NOTE:_** This guide is in progress. Please look for ongoing development.
# Issues
- Provide a Helm chart for the sample project
- Parametrize several hardcoded values
- Support SSL
# Getting Support
You can use [GitHub Issues](https://github.com/kontainer-sh/kontainer-sh/issues) or contact us via [info@kontainer.sh](mailto:info@kontainer.sh).

Need something that isn't covered here? Visit our [homepage](https://kontainer.sh/) (currently in german language) to learn about all other available offerings and support options:
* „Infrastructure-as-Code“ Tutorial
* Mentoring
* DevOps-Insider Newsletter
# Contribution
Feel free to fork and create a pull request.
