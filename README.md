# kontainer.sh
K8s powered `git push` deployments (work in progress).
## Requirements
* Flux (https://fluxcd.io/flux/installation/)
## Installation

    flux bootstrap github \
    --owner kontainer-sh \
    --repository myrepo \
    --personal \
    --private \
    --path ./cluster \
    --branch main \
    --read-write-key \
    --components-extra=image-reflector-controller,image-automation-controller
