# Source: https://gist.github.com/419032bc714cc31cd2f72d45ebef07c7

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

cat k8s/terminate-pods/pod.yaml

kubectl --namespace go-example \
    apply --filename k8s/terminate-pods/pod.yaml

#################################
# Discovering Kubernetes Plugin #
#################################

pip install -U chaostoolkit-kubernetes

chaos discover chaostoolkit-kubernetes

cat discovery.json

#####################################
# Terminating Application Instances #
#####################################

cat chaos/terminate-pod.yaml

chaos run chaos/terminate-pod.yaml

echo $?

kubectl --namespace go-example \
    get pods

###########################
# Steady State Hypothesis #
###########################

cat chaos/terminate-pod-ssh.yaml

diff chaos/terminate-pod.yaml \
    chaos/terminate-pod-ssh.yaml

chaos run chaos/terminate-pod-ssh.yaml

echo $?

kubectl --namespace go-example \
    apply --filename k8s/terminate-pods/pod.yaml

chaos run chaos/terminate-pod-ssh.yaml

echo $?

kubectl --namespace go-example \
    apply --filename k8s/terminate-pods/pod.yaml

#########################
# Pausing After Actions #
#########################

cat chaos/terminate-pod-pause.yaml

diff chaos/terminate-pod-ssh.yaml \
    chaos/terminate-pod-pause.yaml

chaos run chaos/terminate-pod-pause.yaml

echo $?

kubectl --namespace go-example \
    apply --filename k8s/terminate-pods/pod.yaml

#########################
# Phases And Conditions #
#########################

kubectl --namespace go-example \
    describe pod go-example

cat chaos/terminate-pod-phase.yaml

diff chaos/terminate-pod-pause.yaml \
    chaos/terminate-pod-phase.yaml

chaos run chaos/terminate-pod-phase.yaml

echo $?

kubectl --namespace go-example \
    logs go-example

kubectl --namespace go-example \
    apply --filename k8s/db

kubectl --namespace go-example \
    rollout status \
    deployment go-example-db

kubectl --namespace go-example \
    get pods

# Repeat the previous command until the `go-example` Pod `STATUS` is `Running`

chaos run chaos/terminate-pod-phase.yaml

echo $?

#################################
# Making The App Fault-Tolerant #
#################################

cat k8s/terminate-pods/deployment.yaml

kubectl --namespace go-example \
    apply --filename k8s/terminate-pods/deployment.yaml

kubectl --namespace go-example \
    rollout status \
    deployment go-example

chaos run chaos/terminate-pod-phase.yaml

##############################
# Destroying What We Created #
##############################

cd ..

kubectl delete namespace go-example