# Source: https://gist.github.com/bc334351b8f5659e903de2a6eb9e3079

######################
# Creating A Cluster #
######################

# GKE with Istio: https://gist.github.com/924f817d340d4cc52d1c4dd0b300fd20 (gke-istio.sh)
# EKS with Istio: https://gist.github.com/3989a9707f80c2faa445d3953f18a8ca (eks-istio.sh)
# AKS with Istio: https://gist.github.com/c512488f6a30ca4783ce3e462d574a5f (aks-istio.sh)

#############################
# Deploying The Application #
#############################

cd go-example

git pull

kubectl create namespace go-example

kubectl label namespace go-example \
    istio-injection=enabled

kubectl --namespace go-example 
    apply --filename k8s/app-db

kubectl --namespace go-example \
    rollout status deployment go-example

curl -H "Host: go-example.acme.com" \
    "http://$INGRESS_HOST"

###########################
# Drainining Worker Nodes #
###########################
    
cat chaos/node-drain.yaml

kubectl describe nodes

export NODE_LABEL="beta.kubernetes.io/os=linux"

chaos run chaos/node-drain.yaml

############################
# Uncordoning Worker Nodes #
############################

kubectl get nodes

cat chaos/node-uncordon.yaml

diff chaos/node-drain.yaml \
    chaos/node-uncordon.yaml

chaos run chaos/node-uncordon.yaml

kubectl get nodes

##########################
# Making Nodes Drainable #
##########################

kubectl --namespace istio-system \
    get deployment

export CLUSTER_NAME=[...] # Replace `[...]` with the name of the cluster (e.g., `chaos`)

# NOTE: Might need to increase quotas

# If GKE
gcloud container clusters \
    resize $CLUSTER_NAME \
    --zone us-east1-b \
    --num-nodes=3

# If EKS
eksctl get nodegroup \
    --cluster $CLUSTER_NAME

# If EKS
export NODE_GROUP=[...] # Replace `[...]` with the node group

# If EKS
eksctl scale nodegroup \
    --cluster=$CLUSTER_NAME \
    --nodes 3 \
    $NODE_GROUP

# If AKS
az aks show \
    --resource-group chaos \
    --name chaos \
    --query agentPoolProfiles

# If EKS
export NODE_GROUP=[...] # Replace `[...]` with the `name` (e.g., `nodepool1`)

# If AKS
az aks scale \
    --resource-group chaos \
    --name chaos \
    --node-count 3 \
    --nodepool-name $NODE_GROUP

kubectl get nodes

# Repeat the previous command if there are no three `Ready` nodes

kubectl --namespace istio-system \
    get hpa

kubectl --namespace istio-system \
    patch hpa istio-ingressgateway \
    --patch '{"spec": {"minReplicas": 2}}'

kubectl --namespace istio-system \
    get hpa

kubectl --namespace istio-system \
    get pods \
    --output wide

chaos run chaos/node-uncordon.yaml

kubectl get nodes

#########################
# Deleting Worker Nodes #
#########################

cat chaos/node-delete.yaml

diff chaos/node-uncordon.yaml \
    chaos/node-delete.yaml

chaos run chaos/node-delete.yaml

kubectl get nodes

# NOTE: You might need to terminate the node that was removed from Kubernetes

kubectl --namespace go-example \
    get pods

############################
# Destroying Cluster Zones #
############################

# Regional and scalable GKE: https://gist.github.com/88e810413e2519932b61d81217072daf
# Regional and scalable EKS: https://gist.github.com/d73fb6f4ff490f7e56963ca543481c09
# Regional and scalable AKS: https://gist.github.com/b068c3eadbc4140aed14b49141790940

##############################
# Destroying What We Created #
##############################

cd ..

kubectl delete namespace go-example