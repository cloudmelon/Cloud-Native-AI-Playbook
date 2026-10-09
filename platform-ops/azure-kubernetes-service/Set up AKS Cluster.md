# Set up an AKS learning cluster

Reviewed 9 October 2026. Use Azure CNI Overlay for this new learning deployment. [Kubenet retires on 31 March 2028](https://learn.microsoft.com/en-us/azure/aks/configure-kubenet); the older kubenet script is historical.

Install the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli), authenticate with `az login`, and select a subscription where you can create a resource group and AKS cluster. This creates billable resources; pricing, quotas, and regional availability depend on your subscription.

From this directory:

```sh
export AZURE_SUBSCRIPTION="YOUR-SUBSCRIPTION-ID"
export RESOURCE_GROUP="cloud-native-playbook-lab"
export LOCATION="YOUR-AZURE-REGION"
export AKS_NAME="playbook-aks"
bash deploy-overlay-aks.sh
```

The script uses managed identity, avoids client-secret prompts, explicitly selects Azure CNI Overlay, and lets AKS choose the region's default Kubernetes version. Check [available supported versions](https://learn.microsoft.com/en-us/azure/aks/supported-kubernetes-versions) before deployment. The example Pod/Service CIDRs must not overlap your connected networks; adapt them for your environment.

```sh
az aks get-versions --location "$LOCATION" --output table
kubectl get nodes
kubectl get pods -A
```

For production, design identity/RBAC, API access, network policy, workload identity, monitoring, backup, and upgrades for your requirements. This script creates a basic public-API learning cluster.

## Cleanup

After confirming the dedicated lab resource group contains nothing you need:

```sh
az group delete --name "$RESOURCE_GROUP"
```

## Historical scripts

`deploy-cni-aks.sh` and `deploy-kubenet-aks.sh` retain the original implementation for reference. They contain obsolete parameters and are not validated for current Azure CLI/AKS. Use the new Overlay example instead.

See [Azure CNI Overlay](https://learn.microsoft.com/en-us/azure/aks/azure-cni-overlay), [AKS managed identities](https://learn.microsoft.com/en-us/azure/aks/managed-identity-overview), and [private-cluster guidance](private-aks/Set%20up%20Private%20AKS%20Cluster.md).
