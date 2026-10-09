# Playbook Part 3 : Networking

Kubernetes uses a CRI-compatible runtime to create Pod sandboxes and a Container Network Interface (CNI) implementation to configure Pod networking.

## Play 0 : Container Network Interface

[CNI](https://github.com/containernetworking/cni) defines how plugins configure container network interfaces and manage IP allocation. Choose a networking implementation appropriate for your cluster; NetworkPolicy enforcement requires a supporting implementation.

Common TCP ports include:

| Component | Port | Purpose |
| --- | --- | --- |
| kube-apiserver | 6443 | Kubernetes API |
| etcd | 2379–2380 | Client and peer traffic |
| kubelet | 10250 | Kubelet API |
| kube-scheduler | 10259 | Secure scheduler endpoint |
| kube-controller-manager | 10257 | Secure controller endpoint |
| NodePort Services | 30000–32767 | Default configurable range |

These ports are not a recommendation to expose the control plane publicly. See [official ports and protocols](https://kubernetes.io/docs/reference/networking/ports-and-protocols/).

Every Pod has its own IP, and Pod-to-Pod communication follows the Kubernetes network model. Network policies can restrict that communication.

## Play 1 : Network Policy 

By default : all pods in the cluster can communicate with any other pods within Kubernetes cluster, and reach out to any available IP. This accomplished by deploying a pod networking solution to the cluster. A pod network is an internal virtual network that spans across all the nodes in the cluster to which all the pods connect to. But there is no guarantee that the IPs will always remain the same. 

Imagine that we have a web application and want to access the database. Here is also the reason why the better way for the web application to access the database is using a service. If we create a service, it can expose the database application across the cluster from any not. 

Here the interest of using network policy is to allow user to restrict what's allowed to talk to your pods and what your pods are allowed to talk to in your cluster. The web application can now access the database using the name of the service db. The service also gets an IP address assigned to it whenever a pod tries to reach the service using its IP or name it forwards the traffic to the back end pod in this case the database. Here is also where Kube-proxy come in. Kube-proxy is a process that runs on each node in the Kubernetes cluster, creates rules on each node to forward traffic to those services to the backend pods. One way it does this is using **IPTABLES** rules. In this case, it creates an IP tables rule on each node in the cluster to forward traffic heading to the IP of the service.  

NetworkPolicy rules are additive allow rules. A selected Pod becomes isolated only in the directions listed in `policyTypes`; other directions remain unaffected. Traffic allowed by any matching policy is permitted. For a connection between two isolated Pods, the source egress and destination ingress policies must both allow it. Allow DNS egress explicitly when using default-deny egress.

Definition :

- **ingress** defines rules for incoming traffic. 
- **egress** defines rules for outgoing traffic. 
- **rules** both ingress and egress rules are whitelist-based, meaning that any traffic that does not match at least one rule will be blocked. 
- **port** specifies the protocols and ports that match the rule. 
- **from/to** selectors specifies the sources and destinations of network traffic that matches the rule

Check network policy :

    kubectl get netpol

Or

    kubectl get networkpolicies

Check the content of the network policy :

    kubectl describe netpol netpolicyname

Define a network policy : 

```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: melon-network-policy
  spec:
    podSelector: 
      matchLabels:
        app: secure-app
    policyTypes:
    - Ingress
    - Egress
    ingress:
    - from:
      - podSelector:
          matchLabels:
            allow-access: "true"
      ports: 
      - protocol : TCP
        port : 80
      egress: 
      - to: 
        - podSelector:
            matchLabels:
              allow-access: "true"
        ports:
        - protocol: TCP
          port: 80
 ```

For some default policy : 

Deny all ingress

```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: default-deny
  spec:
    podSelector: {}
    policyTypes:
    - Ingress
 ```
 
 Allow all ingress :
 
 ```yaml
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: allow-all
  spec:
    podSelector: {}
    policyTypes:
    - Ingress
    ingress:
    - {}
 
 ```

 ## About Selectors 

There are multiple types of selectors:

- **podSelector** matches traffic from/to pods which match the selector
- **namespaceSelector** matches traffic from/to pods within namespaces which match the selector.  Note that when podSelector and namespaceSelector are both present, the matching pods must also be within a matching namespace.
- **ipBlock** specifies a CIDR range of IPs that will match the rule. This is mostly used for traffic from/to outside the cluster. You can also specify exceptions to the reange using except. 


## Play 2 :  DNS in Kubernetes 

CoreDNS in Kubernetes
From the version 1.12 the recommended DNS Server is CoreDNS. CoreDNS uses a file named Corefile located at /etc/coredns ( the full path is /etc/coredns/Corefile ), within this file you have a number of plugins configured. 

For the pod remember we talked about a record being created for each Pod by converting their IPs into a dashed format that's disabled by default. It is forwarded to the nameserver specified in the coredns pods /etc/resolv.conf file, which is set to use the nameserver from the Kubernetes node.  Also note that this core file is passed into the pods has a configMap object, you can modify it by using the following command : 

     kubectl get configmap -n kube-system

Every DNS records in CoreDNS falls in **cluster.local** domain, it usually looks like :

For the service :
     servicename.namespace.svc.cluster.local


For the pod is to convert their IPs into a dash format. 

When we deployed CoreDNS solution, it also creates a service to make it available to other components within the cluster which is kube-dns. The IP address of this service is configured as name server on pods

    kubectl get svc kube-dns -n kube-system

The DNS configurations on Pods are done by Kubernetes automatically when the pods are created. Want to guess which Kubernetes component is responsible for that ? The kubelet. You can check the following to find the IP of cluster DNS server and domain in it : 
      
    cat /var/lib/kubelet/config.yaml

Once the pods are configured with the right nameserver, you can now resolve other pods and services.  

Checking if DNS is actually working:

    host webservice 

It will return the full qualified domain name of the web service which is happen to have the following output :

    web-service.default.svc.cluster.local has address xxx.xxx.xxx.xxx


    kubectl exec -ti busybox -- nslookup nginx

So the resolv.conf file helps you resolve the naming even though you didn't ask for full name, as this file has a search entry which is set to default.svc.cluster.local, as well as svc.cluster.local and cluster.local. This allows to find any name for the **service**, not for the pod though. For the Pod you'll still need the FQDN.  

    kubectl exec busybox -- cat /etc/resolv.conf


### References 

https://github.com/kubernetes/dns/blob/master/docs/specification.md

https://coredns.io/plugins/kubernetes/


## Play 3 :  Ingress in Kubernetes

Ingress Controller : Reverse proxy product such as Nginx, HAProxy, Treafik, Contour etc deployed in Kubernetes cluster and configure them to route traffic to other services which involved defining URL Routes, SSL certificate, load balancing etc ( a set of rules as Ingress resources ).  Service mesh solution such as Linkerd and Istio also providing capabilities similarily to Ingress Controller. 

Remember a Kubernetes cluster does not come with an Ingress Controller by default. You can check out the following page to get more ideas : 

https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/



With Ingress object and define a set of rules. An Ingress Controller will be able to do things like the following : 
- Route users to a simple application
- URL-based routing such as different pages for the same web application ( example : www.cloud-melon.com/contacts and www.cloud-melon.com/aboutme )
- Based on domain name itself to route specific users ( such as blog.cloud-melon.com and code.cloud-melon.com )

All those will fully depend on your backend configuration of the ingress controller. 

You can check the examples of ingress resources and rules from
 the following link : 

https://kubernetes.io/docs/concepts/services-networking/ingress/


### Current Ingress example

Ingress uses `networking.k8s.io/v1`. The older beta APIs were removed in Kubernetes v1.22. Install a maintained controller and replace `example` below with an existing IngressClass name (`kubectl get ingressclass`). The backend Service must exist in the same namespace.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
spec:
  ingressClassName: example
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

This forwards the original request path; rewriting is controller-specific.

The community **Ingress NGINX** project retired in March 2026; its old installation and rewrite examples are historical. This retirement concerns that controller, not the Ingress API or all NGINX products. See the [Kubernetes announcement](https://kubernetes.io/blog/2026/01/29/ingress-nginx-statement/).

For new deployments, evaluate [Gateway API](https://gateway-api.sigs.k8s.io/) and its [implementations](https://gateway-api.sigs.k8s.io/implementations/). Gateway API requires its CRDs and a compatible controller; it is not automatically installed with Kubernetes. Existing Ingress resources can continue with a maintained controller.
