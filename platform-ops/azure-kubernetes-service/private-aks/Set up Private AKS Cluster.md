# Private AKS clusters

Reviewed 9 October 2026. The scripts in `scripts/` are historical examples, not current deployment recipes. They include obsolete CLI arguments, service-principal secrets, and old firewall requirements. The SQL Server Big Data Clusters script targets a product [retired on 28 February 2025](https://learn.microsoft.com/en-us/lifecycle/announcements/sql-server-2019-big-data-clusters-retirement).

For a new deployment, start with [Microsoft's private AKS cluster documentation](https://learn.microsoft.com/en-us/azure/aks/private-clusters). Use a managed identity, design private DNS and management connectivity, and run kubectl from a network that can reach the private API endpoint.

To adapt the current [Overlay learning example](../Set%20up%20AKS%20Cluster.md), add `--enable-private-cluster` to `az aks create`. This alone does not provide the management network or DNS resolution needed for kubectl. For controlled egress with user-defined routing, follow the [current outbound routing requirements](https://learn.microsoft.com/en-us/azure/aks/egress-outboundtype) and [required endpoints](https://learn.microsoft.com/en-us/azure/aks/outbound-rules-control-egress).

The retained scripts document prior designs only. Review identities, subnet permissions, routes, DNS, supported Kubernetes versions, and current CLI options before reusing any portion.
