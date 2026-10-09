# Set up a local Kubernetes cluster with Minikube

Reviewed 9 October 2026. Minikube is a local learning/development cluster. You need at least 2 CPUs, 2 GB free memory, 20 GB free disk space, internet access, and a supported container or VM driver. See the [official installation selector](https://minikube.sigs.k8s.io/docs/start/) for your OS/architecture.

## Install

On macOS with Homebrew:

```sh
brew install minikube kubectl
```

On Linux x86-64, install the stable Minikube binary:

```sh
curl -fLO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

Use `minikube-linux-arm64` on ARM64. Install kubectl using the [current official instructions](https://kubernetes.io/docs/tasks/tools/); older `apt.kubernetes.io`, `packages.cloud.google.com`, `apt-key`, and Ubuntu bionic recipes are obsolete. Package installation uses the versioned `pkgs.k8s.io` repositories. Select a kubectl version within one minor version of your API server.

## Start and verify

Install and start Docker first if using the Docker driver, then run as your normal user:

```sh
minikube start --driver=docker
minikube status
kubectl config current-context
kubectl get nodes
kubectl cluster-info
```

Alternatively, use a supported VM driver from the [driver list](https://minikube.sigs.k8s.io/docs/drivers/). Cloud VMs may not support nested virtualization; choose the driver according to the host capabilities.

If kubectl is not installed separately, Minikube can provide it:

```sh
minikube kubectl -- get pods -A
```

## Try an application

```sh
kubectl create deployment hello --image=nginx:stable-alpine
kubectl expose deployment hello --type=NodePort --port=80
kubectl rollout status deployment/hello
minikube service hello --url
```

Open the returned URL. Some drivers require the terminal to remain open for the tunnel. This floating image tag is for a disposable demo; pin a reviewed image digest for reproducible deployments.

For external HTTP routing, see the [Networking chapter](../03%20-%20Networking.md). The community Ingress NGINX controller retired in March 2026; choose a maintained controller rather than following old addon tutorials.

## Update and clean up

```sh
minikube version
minikube update-check
```

Upgrade using your original installation method (for example `brew upgrade minikube`) and consult [Minikube upgrades](https://minikube.sigs.k8s.io/docs/handbook/updating/) before changing an existing cluster.

```sh
kubectl delete service hello
kubectl delete deployment hello
minikube stop
```

`minikube delete` removes the local cluster and its data. The original [2024 getting-started post](https://cloudmelonvision.com/if-i-were-about-to-get-started-on-kubernetes-in-2024/) remains a historical reference.
