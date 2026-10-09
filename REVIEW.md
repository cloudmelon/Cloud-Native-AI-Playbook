# Maintenance review — 9 October 2026

## Scope and changes

Fetched `origin/master`; the local branch was already current and had no pre-existing changes. Reviewed all chapter/setup Markdown files and deployment scripts for deprecated commands and outdated guidance. This is a documentation and static review, not a certification of every example or external link.

- Fixed the etcd table-of-contents link, chapter navigation, and certification list formatting.
- Replaced removed kubectl generators/dry-run syntax, broken JSONPath examples, Helm 2 Tiller patching, and deprecated rollout recording commands.
- Updated static-Pod inspection for CRI runtimes and corrected init-container retry behavior.
- Updated control-plane ports, NetworkPolicy isolation semantics, and Ingress manifests to `networking.k8s.io/v1`.
- Replaced obsolete Minikube/Ubuntu installation recipes with current OS-specific installation references and a working learning workflow.
- Reworked etcd examples around v3 TLS access, `etcdctl snapshot save`, and `etcdutl` recovery, including Kubernetes revision-bump considerations.
- Added a new managed-identity Azure CNI Overlay learning script. Retained original AKS scripts as explicitly historical examples; their deployment behavior is unchanged.
- Marked the Azure Vote manifest historical and updated its OS selector label. Image availability remains unverified.
- Added current Secret, Pod Security Admission, ServiceAccount token, and workload identity guidance.

## Lifecycle findings

The community Ingress NGINX controller retired in March 2026; use a maintained controller or evaluate Gateway API. The Ingress API itself remains supported. SQL Server 2019 Big Data Clusters retired on 28 February 2025. AKS kubenet retirement is scheduled for 31 March 2028; new examples use Azure CNI Overlay.

Avoid hardcoding a “latest” Kubernetes release in long-lived notes. Choose supported versions from Kubernetes/provider release pages at deployment time, and keep kubectl within one minor version of the API server.

## Official references checked

- [Kubernetes release support](https://kubernetes.io/releases/) and [version skew policy](https://kubernetes.io/releases/version-skew-policy/)
- [Ports and protocols](https://kubernetes.io/docs/reference/networking/ports-and-protocols/)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) and [Ingress NGINX retirement](https://kubernetes.io/blog/2026/01/29/ingress-nginx-statement/)
- [Minikube installation](https://minikube.sigs.k8s.io/docs/start/) and [kubectl Linux installation](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [etcd recovery](https://etcd.io/docs/v3.7/op-guide/recovery/)
- [Azure CNI Overlay](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay) and [kubenet retirement](https://learn.microsoft.com/en-us/azure/aks/configure-kubenet)
- [SQL Server Big Data Clusters retirement](https://learn.microsoft.com/en-us/lifecycle/announcements/sql-server-2019-big-data-clusters-retirement)

## Validation and remaining work

Checked shell syntax with `bash -n`, repository-relative Markdown links, and whitespace with `git diff --check`. The new script's AKS flags were checked against the installed Azure CLI help.

No Kubernetes cluster was available; manifests and commands were not applied. Azure resources were not provisioned. Legacy scripts and legacy sample images require separate migration/testing before use. External blog links and historical screenshots were retained; their content was not comprehensively checked. The certification program page could not be retrieved during the review, so its existing list was reformatted without expanding its eligibility claims.

For a follow-up release, run the Minikube workflow and AKS script in disposable environments, validate manifests against the target API server, review/pin container digests, and add automated Markdown/link checking.
