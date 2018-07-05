# Cluster info
Kubectl cluster-info

# Current context
Kubectl config current-context # get current context (can be pointed to other k8s cluster)

# Gets
Kubectl get nodes
Kubectl get pods
Kubectl get pods/hello-k8s
Kubectl get pods --all-namespaces
Kubectl get ep # get endpoints
Kubectl get services # get services

# Applies
# Note create vs apply: create is for imperative, apply is for declarative
Kubectl apply -f hello-k8s-pod.yml # creates pod according to pod manifest in this yaml file
Kubectl apply -f hello-k8s-rc.yml # creates replication control according to replication controller manifest in this yaml file
Kubectl apply -f hello-k8s-rc.yml # applies new manifest file (e.g. after a change to the number of replicas)

# Roll forward and back
Kubectl apply -f hello-k8s-dep-with-ru.yml --record # applys new deployment.
	# You can append --record to this command to record the current command in the annotations of #the created or updated resource. This is useful for future review, such as investigating which # commands were executed in each Deployment revision.
Kubectl rollout status deployment hello-dep
Kubectl rollout history deployment hello-dep # This shows a rich audit history of changes if the --record flag was used by kubectl apply
	# and enumerates each change by its revision number
Kubectl rollout undo deployment hello-dep --to-revision=2 # rolls back configuration to previous revision number

# Describe
Kubectl describe pod hello-k8s # show info for a pod by this name
Kubectl describe rc hello-rc # shows info about replication controller by name

# Delete
Kubectl delete pod hello-k8s # deletes pod (name was defined in yaml file)

# Expose
Kubectl expose rc hello-rc --name hello-rc-service --target-port=8080 --type=NodePort

# Create a service the imperatively way, not declarative using the manifest