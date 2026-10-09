# Playbook Part 2: Deploying an Application, Rolling Updates, and Rollback

This section we're going to talk a little bit about how to gradually roll out new versions using rolling updates and how to roll back in the event of a problem.  

Let's start with what if you want to deploy an application in the production. Let's say you have a number of web servers that needs to be deployed for some reasons, such many instances right ? Whenever newer versions of application builds become available on the docker registry you would like to upgrade your Docker instances seamlessly. However when you upgrade your instances, you do not want to upgrade all of them at once as we just did. This may impact users accessing our applications so you might want to upgrade them one after the other. And that kind of upgrade is known as rolling updates. 

## Play 0 : Scenario playing with deployment

Suppose one of the upgrades you performed resulted in an unexpected error and you're asked to undo the recent change you would like to be able to roll back the changes that were recently carried out.  Finally say for example you would like to make multiple changes to your environment as upgrading the underlying web server versions as well as scaling your environment and also modifying the resource allocations etc. You do not want to apply each change immediatly after the command is run instead you would like to apply a pause to your environment, make the changes and then resume so that all changes are rolled-out together. All of these capabilities are available with the Kubernetes deployement that comes higher in the hierarchy. 

To wrap-up, the deployment provides us with the capability to upgrade the underlying instances seamlessly using rolling updates, undo changes, and pause and resume changes as required. 


## Play 1 : Manage deployments

**Deployments** provide a way to define a desired state for the replica pod.

You can use the yaml defined template to define a deloyment : 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: melon-deploy
  labels:
    app: melonapp
spec:
  replicas : 3
  selector:
    matchLabels:
      app: melonapp
  template:
    metadata:
      labels:
        app: melonapp
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80

 ```

 Above yaml manifest means :

 - **spec.replicas** is the number of replica pods
 - **spec.template** is the template pod descriptor which defines the pods which will be created
 - **spec.selector** is the deployment will manage all pods whose labels match this selector

Run Busybox image : 

    kubectl run busybox --rm -it --image=busybox -- /bin/sh
    
Run nginx image : 

    kubectl run nginx --image=nginx --dry-run=client -o yaml > pod-sample.yaml

Create a deployment using the following : 

    kubectl create deployment kubeserve --image=nginx:stable

Scale a deployment using the following : 

    kubectl scale deployment kubeserve --replicas=5
    

Other useful command about query, edit, and delete deployment :
    
    kubectl get deployments

    kubectl get deployment melon-deploy

    kubectl describe deployment melon-deploy

    kubectl edit deployment melon-deploy

    kubectl delete deployment melon-deploy

Addtionally, you can also use **kubectl patch** to update an API object in place. An example is like the following : 

    kubectl patch deployment melon-deploy -p '{"spec":{"template":{"spec":{"terminationGracePeriodSeconds":45}}}}'

## Play 2 : Rolling updates

**Rolling updates** provide a way to update a deployment to a new container version by gradually updating replicas while keeping replicas available. Readiness probes, sufficient capacity, and appropriate `maxUnavailable` settings are needed to avoid downtime

Deploying an application : 

     kubectl create deployment kubedeploy --image=nginx:stable


Or using Yaml definition file :

 ```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:stable
        ports:
        - containerPort: 80
```

Then using the following command : 
     kubectl apply -f filename.yaml


Check status:
    
     kubectl rollout status deployments kubedeploy


     kubectl set image deployment/nginx-deployment nginx=nginx:stable-alpine


Or

     kubectl set image deployment/kubedeploy nginx=nginx:stable-alpine

The removed `--record` flag is no longer used. Deployment Pod-template changes create revisions automatically. Add a human-readable reason with `kubectl annotate deployment/kubedeploy kubernetes.io/change-cause="Switch to Alpine image" --overwrite`. Rollback restores the Pod template; it does not restore external configuration or databases. Floating `stable` tags here illustrate the workflow; use distinct immutable image digests for reliable production rollouts.


## Play 3 : Rollback

**Rollback** allow us to revert to a previsou state. For example, if a rolling update breaks someting, we can quickly recover by using a rollback. 

Or simply using : 

     kubectl rollout history deployment/kubedeploy

Performing an roll back : 

     kubectl rollout undo deployments kubedeploy

Check the history of deployments : 

     kubectl rollout history deployment kubedeploy

Then you can get back to the specific revision : 

     kubectl rollout undo deployment kubedeploy --to-revision=2

Check if rollout successfully using the following : 

     kubectl rollout status deployment/kubedeploy

You'll see the output similar to the following : 

 <img src="screenshots/Rollout status.PNG" alt="rollout status" width="800px"/>   
    
**--revision** flag will give more information on a specific revision number

Specifically : 
Speaking of the rolling update strategy. Here, under the spec, rolling update that's populated simply by the default values. Because we didn't give it a specific value when we created the deployment. You'll notice we have two values here, called maxSurge and maxUnavailable, just give you an idea of what they do.  

**maxSurge** does is it dertermines the maximum number of extra replicas that can be created during a rolling deployment. We can assume we have 3 replicas here, as soon as we start doing a rolling update, it's going to create some addtional replicas running those new versions. So for a short period of time, there could potentially be more than three replicas, and the maxSurge simply put a hard maximum on that. So you can use this, especially if you have a big deployment with a lot of different replicas. You can use that maxSurge value to control how fast or how gradually the deployment rolls out. Two scenarios : 
-  You could set that very low, and it's ging to just spend a few at a time and just gradually replace the replicas that in your deployment. 
-  Or you could set that to very high number, it's going to do a huge chunk of them all at once

So it is just give you a little more control over how quickly those new instances are created. Surge can be set as a percentage or a specific number. 

**maxUnavailable** does is it sets a maximum number on the number of replicase that could be considered unavailable during their rolling update. It can be a number of percentage sign. So if you're doing a rolling update or you're doing a rollback, you can use that value to ensure that at any givevn time, a large number or a small number of your active replicas are actually available. 


So those just give you a little more control over what actually occurs when you do a rolling update. 


## Play 4: OS Upgrades

Imagine there is one node offline now which host your blue and green application, When you have multiple replicas of the blue pod, the users accessing the blue application are not impacted as they're being served through the other blue pod that's online, however users accessing the green pod, are impacted as that was the only pod running the green application. 

When a node becomes unreachable, node conditions and taints drive eviction. Pods normally receive 300-second tolerations for `node.kubernetes.io/not-ready` and `node.kubernetes.io/unreachable`; timing depends on tolerations and cluster configuration. Controllers can recreate evicted Pods on healthy nodes. A single replica can still cause an outage.

If you're not sure the node will be back online within 5 minutes, the safe way is to drain the nodes of all the workloads so that the pods are moved to other nodes in the cluster by using the following command : 

    kubectl drain node-super-007

    k drain node-super-007 --ignore-daemonsets

Technically there are not moved when you drain the node, the pods are gracefully terminated from the node that they're on and recreated on another. The node is also **cordoned** or marked as **unschedulable**. Meaning no pods can be scheduled on this node until you specifically you remove the restriction. When the pods are safe on the other nodes, you can upgrade and reboot the node, when it comes back online, it is still unschedulable, you then need to uncordon it so that pods can be scheduled on it again by using the following command : 

    kubectl uncordon node-super-007


Now remember, the pods that were moved to the other nodes don't automatically fall back. If pods were deleted or new pods were created in the cluster, then they would be created. 

There is another command simply mark the node unschedulable, unlike drain, it does not terminate or move the pods on an existing node :

    kubectl cordon node-super-007

## Play 5: Taints and Tolerations 

Taints on the node and toleration on the pods. 

You can use the following command to taint the node :

    kubectl taint nodes node-name key=value:taint-effect

Example is as the following : 

    kubectl taint nodes melonnode app=melonapp:NoSchedule


From the point of view of pods, they might be :
- NoSchedule
- PreferNoSchedule
- NoExecute

Then translate it into pod yaml defnition file is as the following :

 ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
    name: melon-ns-pod
    namespace: melon-ns
    labels:
      app: melonapp
   spec:
    containers:
    - name: melonapp-container
      image: busybox
      command: ['sh', '-c', 'echo Salut K8S! && sleep 3600']
    tolerations:
    - key: "app"
      operator: "Equal"
      value: "melonapp"
      effect: "NoSchedule"
 ```

When Kubernetes cluster first set up, there's a taint set up automatically for the master, the scheduler's not going to schedule any pods to the master which is refer to as a best practice so no workloads will be deployed in the master. 

To untaint a node ( here's not a good practice but just to show how to untaint master node ) : 

    kubectl taint nodes master node-role.kubernetes.io/control-plane:NoSchedule-
