# Source: https://gist.github.com/6be19a176b5cbe0261c81aefc86d516b

######################
# Creating A Cluster #
######################

# Docker Desktop: https://gist.github.com/f753c0093a0893a1459da663949df618 (docker.sh)
# Minikube: https://gist.github.com/ddc923c137cd48e18a04d98b5913f64b (minikube.sh)
# GKE: https://gist.github.com/2351032b5031ba3420d2fb9a1c2abd7e (gke.sh)
# EKS: https://gist.github.com/be32717b225891b69da2605a3123bb33 (eks.sh)
# AKS: https://gist.github.com/c7c9a8603c560eaf88d28db16b14768c (aks.sh)

#############################
# Deploying The Application #
#############################

cd go-example

git pull

kubectl create namespace go-example

cat k8s/terminate-pods/app/*

kubectl --namespace go-example \
    apply --filename k8s/terminate-pods/app

kubectl --namespace go-example \
    rollout status deployment go-example

##############################
# Validating The Application #
##############################

kubectl --namespace go-example \
    get ingress

kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/mandatory.yaml

# If Minikube
minikube addons enable ingress

# If Docker Desktop, GKE, or AKS
kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/provider/cloud-generic.yaml

# If EKS
kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/provider/aws/service-l4.yaml

# If EKS
kubectl apply \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/provider/aws/patch-configmap-l4.yaml

# If Minikube
export INGRESS_HOST=$(minikube ip)

# If Docker Desktop or EKS
export INGRESS_HOST=$(kubectl \
    --namespace ingress-nginx \
    get service ingress-nginx \
    --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

# If GKE or AKS
export INGRESS_HOST=$(kubectl \
    --namespace ingress-nginx \
    get service ingress-nginx \
    --output jsonpath="{.status.loadBalancer.ingress[0].ip}")

echo $INGRESS_HOST

# Repeat the `export` command if the output is empty

cat k8s/health/ingress.yaml

kubectl --namespace go-example \
    apply --filename k8s/health/ingress.yaml

curl -H "Host: go-example.acme.com" \
    "http://$INGRESS_HOST"

#################################
# Validating Application Health #
#################################

cat chaos/health.yaml

chaos run chaos/health.yaml

kubectl --namespace go-example \
    get pods

cat chaos/health-pause.yaml

diff chaos/health.yaml \
    chaos/health-pause.yaml

chaos run chaos/health-pause.yaml

kubectl --namespace go-example \
    get pods

#######################################
# Validating Application Availability #
#######################################

cat chaos/health-http.yaml

diff chaos/health-pause.yaml \
    chaos/health-http.yaml

chaos run chaos/health-http.yaml

cat k8s/health/hpa.yaml

kubectl apply --namespace go-example \
    --filename k8s/health/hpa.yaml

kubectl --namespace go-example \
    get hpa

# Repeat if the number of replicas is not `2`

chaos run chaos/health-http.yaml

########################################
# Terminating Application Dependencies #
########################################

cat chaos/health-db.yaml

diff chaos/health-http.yaml \
    chaos/health-db.yaml

chaos run chaos/health-db.yaml

##############################
# Destroying What We Created #
##############################

cd ..

kubectl delete namespace go-example