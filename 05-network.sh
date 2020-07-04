# Source: https://gist.github.com/455b0321879da7abf4d358a1334fd705

######################
# Creating A Cluster #
######################

# Docker Desktop: https://gist.github.com/f753c0093a0893a1459da663949df618 (docker.sh)
# Minikube: https://gist.github.com/ddc923c137cd48e18a04d98b5913f64b (minikube.sh)
# GKE: https://gist.github.com/2351032b5031ba3420d2fb9a1c2abd7e (gke.sh)
# EKS: https://gist.github.com/be32717b225891b69da2605a3123bb33 (eks.sh)
# AKS: https://gist.github.com/c7c9a8603c560eaf88d28db16b14768c (aks.sh)

#################################
# Installing Istio Service Mesh #
#################################

# If Docker Desktop and if kept the cluster from the previous section
kubectl delete \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/provider/cloud-generic.yaml

# If Docker Desktop and if kept the cluster from the previous section
kubectl delete \
    --filename https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/mandatory.yaml

istioctl manifest apply \
    --skip-confirmation

kubectl --namespace istio-system \
    get service istio-ingressgateway

# Confirm that `EXTERNAL-IP` is not `pending`, unless using Minikube. Repeat if it is.

# If Minikube
export INGRESS_PORT=$(kubectl \
    --namespace istio-system \
    get service istio-ingressgateway \
    --output jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')

# If Minikube
export INGRESS_HOST=$(minikube ip):$INGRESS_PORT

# If Docker Desktop
export INGRESS_HOST=127.0.0.1

# If GKE or AKS als for kind
export INGRESS_HOST=$(kubectl \
    --namespace istio-system \
    get service istio-ingressgateway \
    --output jsonpath="{.status.loadBalancer.ingress[0].ip}")

# If EKS
export INGRESS_HOST=$(kubectl \
    --namespace istio-system \
    get service istio-ingressgateway \
    --output jsonpath="{.status.loadBalancer.ingress[0].hostname}")

echo $INGRESS_HOST

#####################
# Deploying The App #
#####################

cd go-demo-8

git pull

kubectl create namespace go-demo-8

kubectl label namespace go-demo-8 \
    istio-injection=enabled

cat k8s/health/app/*

kubectl --namespace go-demo-8 \
    apply --filename k8s/health/app/

kubectl --namespace go-demo-8 \
    rollout status deployment go-demo-8

kubectl --namespace go-demo-8 \
    get pods

cat k8s/network/istio.yaml

kubectl --namespace go-demo-8 \
    apply --filename k8s/network/istio.yaml

cat k8s/network/repeater/*

kubectl --namespace go-demo-8 \
    apply --filename k8s/network/repeater

kubectl --namespace go-demo-8 \
    rollout status deployment repeater

curl -H "Host: repeater.acme.com" \
    "http://$INGRESS_HOST?addr=http://go-demo-8"

############################
# Discovering Istio Plugin #
############################
    
pip3 install -U chaostoolkit-istio

chaos discover chaostoolkit-istio

cat discovery.json

#############################
# Aborting Network Requests #
#############################

cat chaos/network.yaml

chaos run chaos/network.yaml

###############################
# Rolling Back Abort Failures #
###############################

for i in {1..10}; do 
    curl -H "Host: repeater.acme.com" \
        "http://$INGRESS_HOST?addr=http://go-demo-8"
    echo ""
done

kubectl --namespace go-demo-8 \
    describe virtualservice go-demo-8

kubectl --namespace go-demo-8 \
    apply --filename k8s/network/istio.yaml

kubectl --namespace go-demo-8 \
    describe virtualservice go-demo-8

cat chaos/network-rollback.yaml

diff chaos/network.yaml \
    chaos/network-rollback.yaml

chaos run chaos/network-rollback.yaml

for i in {1..10}; do 
    curl -H "Host: repeater.acme.com" \
        "http://$INGRESS_HOST?addr=http://go-demo-8"
done

kubectl --namespace go-demo-8 \
    describe virtualservice go-demo-8

########################################################
# Making The App Resilient To Partial Network Failures #
########################################################

cat k8s/network/istio-repeater.yaml

# If Windows, open the address manually in your favorite browser
open https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter#x-envoy-retry-on

kubectl --namespace go-demo-8 \
    apply --filename k8s/network/istio-repeater.yaml

chaos run chaos/network-rollback.yaml

##############################
# Increasing Network Latency #
##############################

cat chaos/network-delay.yaml

diff chaos/network-rollback.yaml \
    chaos/network-delay.yaml

chaos run chaos/network-delay.yaml

cat k8s/network/istio-delay.yaml

diff k8s/network/istio-repeater.yaml \
    k8s/network/istio-delay.yaml

kubectl --namespace go-demo-8 \
    apply --filename k8s/network/istio-delay.yaml

chaos run chaos/network-delay.yaml

# It might fail if (randomly) too many requests fall into delay or abort state

#########################
# Aborting All Requests #
#########################

cat chaos/network-abort-100.yaml

diff chaos/network-rollback.yaml \
    chaos/network-abort-100.yaml

chaos run chaos/network-abort-100.yaml

########################################
# Simulating Denial Of Service Attacks #
########################################

kubectl --namespace go-demo-8 \
    run siege \
    --image yokogawa/siege \
    --generator run-pod/v1 \
    -it --rm \
    -- --concurrent 50 --time 20S "http://go-demo-8"

cat main.go

kubectl --namespace go-demo-8 \
    run siege \
    --image yokogawa/siege \
    --generator run-pod/v1 \
    -it --rm \
    -- --concurrent 50 --time 20S "http://go-demo-8/limiter"

#####################################
# Running Denial Of Service Attacks #
#####################################

cat chaos/network-dos.yaml

chaos run chaos/network-dos.yaml

cat chaostoolkit.log

# What is the fix?

##############################
# Destroying What We Created #
##############################

cd ..

kubectl delete namespace go-demo-8