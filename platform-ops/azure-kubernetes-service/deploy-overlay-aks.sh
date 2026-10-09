#!/usr/bin/env bash
# Learning cluster: creates billable Azure resources. Run after az login.
set -euo pipefail
: "${AZURE_SUBSCRIPTION:?Set AZURE_SUBSCRIPTION}"
: "${RESOURCE_GROUP:?Set RESOURCE_GROUP to a dedicated lab resource group}"
: "${LOCATION:?Set LOCATION to a supported Azure region}"
: "${AKS_NAME:?Set AKS_NAME}"
command -v az >/dev/null || { printf 'Azure CLI is required.\n' >&2; exit 1; }
az account set --subscription "$AZURE_SUBSCRIPTION"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
az aks create \
  --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" \
  --location "$LOCATION" --enable-managed-identity \
  --network-plugin azure --network-plugin-mode overlay \
  --pod-cidr 192.168.0.0/16 --service-cidr 10.0.0.0/16 \
  --dns-service-ip 10.0.0.10 --node-count 2 \
  --generate-ssh-keys
# Kubernetes version is intentionally selected by AKS for the region.
# Existing kubeconfig contexts are not overwritten automatically.
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME"
