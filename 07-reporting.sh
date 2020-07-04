# Source: https://gist.github.com/d81f114a887065a375279635a66ccac2

######################
# Creating A Cluster #
######################

# NOTE: A new and improved cluster creation Gists for GKE, EKS, and AKS

# Docker Desktop with Istio: https://gist.github.com/9a9752cf5355f1b8095bd34565b80aae (docker-istio.sh)
# Minikube with Istio: https://gist.github.com/a5870806ae6f21de271bf9214e523b53 (minikube-istio.sh)
# Regional and scalable GKE with Istio: https://gist.github.com/88e810413e2519932b61d81217072daf (gke-istio-full.sh)
# Regional and scalable EKS with Istio: https://gist.github.com/d73fb6f4ff490f7e56963ca543481c09 (eks-istio-full.sh)
# Regional and scalable AKS with Istio: https://gist.github.com/b068c3eadbc4140aed14b49141790940 (aks-istio-full.sh)

# NOTE: Remember to declare `INGRESS_HOST`

#####################
# Deploying The App #
#####################





kubectl create namespace go-example

kubectl label namespace go-example \
    istio-injection=enabled

kubectl --namespace go-example \
    apply --filename k8s/app-full

kubectl --namespace go-example \
    rollout status deployment go-example

curl -H "Host: repeater.acme.com" \
    "http://$INGRESS_HOST?addr=http://go-example"

#################################
# Exploring Experiments Journal #
#################################

cat chaos/health-http.yaml

chaos run chaos/health-http.yaml \
    --journal-path journal-health-http.json

cat journal-health-http.json

##############################
# Creating Experiment Report #
##############################

# Start a local Docker daemon

docker container run \
    --user $(id -u) \
    --volume $PWD:/tmp/result \
    -it \
    chaostoolkit/reporting \
     -- report \
     --export-format=pdf \
    journal-health-http.json \
    report.pdf

# If Windows, open the `report.pdf` file manually
open report.pdf

######################################
# Creating A Multi-Experiment Report #
######################################

cat chaos/network-delay.yaml

chaos run chaos/network-delay.yaml \
    --journal-path journal-network-delay.json

docker container run \
    --user $(id -u) \
    --volume $PWD:/tmp/result \
    -it \
    chaostoolkit/reporting \
     -- report \
     --export-format=pdf \
    journal-health-http.json \
    journal-network-delay.json \
    report.pdf

# If Windows, open the `report.pdf` file manually
open report.pdf

##############################
# Destroying What We Created #
##############################



kubectl delete namespace go-example

# NOTE: Stop Docker daemon