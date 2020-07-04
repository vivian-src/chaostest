# Source: https://gist.github.com/69bfc361eefd0a64cd92fdc4840f7aed

######################
# Creating A Cluster #
######################

# NOTE: Docker Desktop and Minikube can be used only in some of the exercises

# Docker Desktop with Istio: https://gist.github.com/9a9752cf5355f1b8095bd34565b80aae (docker-istio.sh)
# Minikube with Istio: https://gist.github.com/a5870806ae6f21de271bf9214e523b53 (minikube-istio.sh)
# Regional and scalable GKE with Istio: https://gist.github.com/88e810413e2519932b61d81217072daf (gke-istio-full.sh)
# Regional and scalable EKS with Istio: https://gist.github.com/d73fb6f4ff490f7e56963ca543481c09 (eks-istio-full.sh)
# Regional and scalable AKS with Istio: https://gist.github.com/b068c3eadbc4140aed14b49141790940 (aks-istio-full.sh)

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

# NOTE: If `Connection refused`, wait for a few moments and repeat the `curl` command

####################################
# Deploying Dashboard Applications #
####################################

echo $INGRESS_HOST

# NOTE: Open a second terminal

export INGRESS_HOST=[...] # Replace `[...]` with the output of the `echo` command

while true; do 
    curl -i -H "Host: repeater.acme.com" \
        "http://$INGRESS_HOST?addr=http://go-example/demo/person"
    sleep 1
done

# Go back to the first terminal

istioctl manifest apply \
    --set values.grafana.enabled=true \
    --set values.kiali.enabled=true \
    --skip-confirmation

kubectl --namespace istio-system \
    rollout status deployment grafana

################################
# Exploring Grafana Dashboards #
################################

istioctl dashboard grafana

##############################
# Exploring Kiali Dashboards #
##############################

# NOTE: Cancel with ctrl+c

istioctl dashboard kiali

# NOTE: Cancel with ctrl+c

echo "apiVersion: v1
kind: Secret
metadata:
  name: kiali
  labels:
    app: kiali
type: Opaque
data:
  username: $(echo -n "admin" | base64)
  passphrase: $(echo -n "admin" | base64)" \
    | kubectl --namespace istio-system \
    apply --filename -

kubectl --namespace istio-system \
    rollout restart deployment kiali

istioctl dashboard kiali

# NOTE: Cancel with ctrl+c

##########################################
# Preparing For Termination Of Instances #
##########################################

cat k8s/chaos/experiments-any-pod.yaml

kubectl create namespace chaos

kubectl --namespace chaos apply \
    --filename k8s/chaos/experiments-any-pod.yaml

cat k8s/chaos/sa-cluster.yaml

kubectl --namespace chaos apply \
    --filename k8s/chaos/sa-cluster.yaml

cat k8s/chaos/periodic-fast.yaml

############################################
# Terminating Random Application Instances #
############################################

kubectl --namespace chaos apply \
    --filename k8s/chaos/periodic-fast.yaml

kubectl --namespace chaos get cronjobs

# Repeat the previous command until `LAST SCHEDULE` is NOT `<none>`

kubectl --namespace chaos get jobs

# Repeat the previous command until `COMPLETIONS` is `1/1`

kubectl --namespace chaos get pods

kubectl --namespace go-example \
    get pods

# NOTE: All experiments are passing

istioctl dashboard grafana

# NOTE: Cancel with ctrl+c

istioctl dashboard kiali

# NOTE: Cancel with ctrl+c

kubectl --namespace go-example \
    get pods

kubectl --namespace chaos delete \
    --filename k8s/chaos/periodic-fast.yaml

kubectl --namespace go-example \
    rollout restart deployment go-example

##############################
# Disrupting Network Traffic #
##############################

# NOTE: ChaosToolkit Istio plugin cannot work globally.
# NOTE: We need to specify the virtual service it should disrupt.
# NOTE: Nevertheless, we can disrupt a specific VirtualService and observe the effect it has on the system as a whole.

######################################
# Preparing For Termination Of Nodes #
######################################

cat k8s/chaos/experiments-node.yaml

diff k8s/chaos/experiments-any-pod.yaml \
    k8s/chaos/experiments-node.yaml

# NOTE: It will not work with Minikube or Docker Desktop

kubectl --namespace chaos apply \
    --filename k8s/chaos/experiments-node.yaml

cat k8s/chaos/periodic-node.yaml

############################
# Terminating Random Nodes #
############################

kubectl --namespace chaos apply \
    --filename k8s/chaos/periodic-node.yaml

kubectl --namespace chaos get cronjobs

# Repeat the previous command until `LAST SCHEDULE` is NOT `<none>`

kubectl --namespace chaos get jobs

kubectl --namespace chaos get pods

kubectl get nodes

# Repeat until the `STATUS` is `Ready`

istioctl dashboard grafana

# Stop with ctrl+c

istioctl dashboard kiali

# Stop with ctrl+c

kubectl get nodes

##############################
# Destroying What We Created #
##############################

# Go to the second terminal

# Stop the loop with ctrl+c

# Go to the first terminal



kubectl delete namespace go-example

kubectl delete namespace chaos