# Playbook Part 4: etcd

etcd is the distributed key-value store used by the Kubernetes API server to persist cluster state. Applications interact through the API server rather than writing directly to etcd. Snapshots contain sensitive data, including Secrets; encrypt backups and restrict access.

## Client commands

Install tools matching your etcd version from [official releases](https://github.com/etcd-io/etcd/releases). Current v3 clients use `put`, not the removed v2 `set` command:

```sh
etcdctl --endpoints=http://127.0.0.1:2379 put key1 value1
etcdctl --endpoints=http://127.0.0.1:2379 get key1
```

These plain-HTTP commands are for a local test instance only. Kubernetes etcd normally requires TLS. In a kubeadm cluster, find the static Pod and configured endpoints/certificates:

```sh
kubectl get pods -n kube-system -l component=etcd
sudo cat /etc/kubernetes/manifests/etcd.yaml
```

For read-only inspection, substitute the actual Pod name and certificate paths:

```sh
kubectl exec -n kube-system etcd-CONTROL-PLANE-NAME -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  get /registry/ --prefix --keys-only
```

## Backup

Run on a control-plane host with authorized certificate access. Use the paths from your cluster configuration:

```sh
sudo etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/healthcheck-client.crt \
  --key=/etc/kubernetes/pki/etcd/healthcheck-client.key \
  snapshot save snapshot.db
sudo etcdutl snapshot status snapshot.db --write-out=table
```

Use `etcdctl` to save and `etcdutl` to inspect/restore snapshots. Do not treat a copy of a running data directory as a consistent backup. Also back up the Kubernetes PKI and control-plane configuration separately.

## Recovery

Recovery replaces cluster state and needs a cluster-specific procedure. Stop all API servers from writing to the old etcd cluster. With kubeadm, control-plane components are usually static Pods, not `service kube-apiserver` units.

For Kubernetes, restore with a revision bump and mark compacted to invalidate informer caches. This is an illustrative single-member restore into a new directory, not a complete production recovery procedure:

```sh
sudo etcdutl snapshot restore snapshot.db \
  --name=control-plane-1 \
  --data-dir=/var/lib/etcd-restored \
  --initial-cluster=control-plane-1=https://CONTROL-PLANE-IP:2380 \
  --initial-advertise-peer-urls=https://CONTROL-PLANE-IP:2380 \
  --initial-cluster-token=etcd-restored-cluster \
  --bump-revision=1000000000 --mark-compacted
```

Replace the peer address and size the revision bump for your write rate and backup age. Multi-member recovery requires restoring the same snapshot to each member with consistent membership parameters. Update the etcd configuration/hostPath to the restored directory before restarting components; check permissions, TLS, health, and API access.

For managed Kubernetes such as AKS, use the provider's backup/recovery procedures; customers do not manage the control-plane etcd instance directly.

Follow [etcd disaster recovery](https://etcd.io/docs/v3.7/op-guide/recovery/) for the version you run and [Kubernetes etcd operations](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/).
