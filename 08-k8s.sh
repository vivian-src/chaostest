# Source: https://gist.github.com/015845b599beca995cdd8e67a7ec99db

######################
# Creating A Cluster #
######################

# Docker Desktop with Istio: https://gist.github.com/9a9752cf5355f1b8095bd34565b80aae (docker-istio.sh)
# Minikube with Istio: https://gist.github.com/a5870806ae6f21de271bf9214e523b53 (minikube-istio.sh)
# Regional and scalable GKE with Istio: https://gist.github.com/88e810413e2519932b61d81217072daf (gke-istio-full.sh)
# Regional and scalable EKS with Istio: https://gist.github.com/d73fb6f4ff490f7e56963ca543481c09 (eks-istio-full.sh)
# Regional and scalable AKS with Istio: https://gist.github.com/b068c3eadbc4140aed14b49141790940 (aks-istio-full.sh)

# NOTE: Remember to declare `INGRESS_HOST`

#####################
# Deploying The App #
#####################

cd go-example

git pull

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

##########################################
# Setting Up Chaos Toolkit In Kubernetes #
##########################################

cat k8s/chaos/experiments.yaml

# NOTE: We could create a ConfigMap through a command and include all the files. But that's not GitOps.

kubectl --namespace go-example \
    apply --filename k8s/chaos/experiments.yaml

kubectl --namespace go-example \
    describe configmap chaostoolkit-experiments

cat k8s/chaos/sa.yaml

kubectl --namespace go-example \
    apply --filename k8s/chaos/sa.yaml

################################
# Running One-Shot Experiments #
################################

cat k8s/chaos/once.yaml

# If Windows, open the address in your favorite browser manually
open "https://github.com/vfarcic/chaostoolkit-container-image"

kubectl --namespace go-example \
    apply --filename k8s/chaos/once.yaml

kubectl --namespace go-example \
    get pods \
    --selector app=go-example-chaos

# Repeat the previous command until `STATUS` is `Completed`

kubectl --namespace go-example \
    logs --selector app=go-example-chaos \
    --tail -1

kubectl --namespace go-example \
    delete --filename k8s/chaos/once.yaml

#################################
# Running Scheduled Experiments #
#################################

cat k8s/chaos/periodic.yaml

kubectl --namespace go-example \
    apply --filename k8s/chaos/periodic.yaml

kubectl --namespace go-example \
    get cronjobs

# Repeat the previous command until `LAST SCHEDULE` is NOT `<none>`

kubectl --namespace go-example \
    get jobs

# Repeat the previous command until `COMPLETIONS` is `1/1`

kubectl --namespace go-example \
    get pods

########################################
# Running Failed Scheduled Experiments #
########################################

kubectl --namespace go-example \
    delete deployment go-example

kubectl --namespace go-example \
    get pods \
    --selector app=go-example-chaos

# Repeat the previous command until the new Pod `STATUS` is `Error`

# You can see the logs of the failed Pod

kubectl get pv

# We could generate and extract a report based on journal files in that PersistentVolume

kubectl --namespace go-example \
    apply --filename k8s/app-full

kubectl --namespace go-example \
    rollout status deployment go-example

####################################
# Sending Experiment Notifications #
####################################

# We could send a notification to any HTTP endpoint or to Slack

# Join the DevOps20 (http://slack.devops20toolkit.com/) Slack workspace

cat k8s/chaos/settings.yaml

# NOTE: Might want to replace with your own Slack token

cat k8s/chaos/settings.yaml \
    | sed -e "s|@||g" \
    | kubectl --namespace go-example \
    apply --filename -

cat k8s/chaos/periodic-slack.yaml

diff k8s/chaos/periodic.yaml \
    k8s/chaos/periodic-slack.yaml

kubectl --namespace go-example \
    apply --filename k8s/chaos/periodic-slack.yaml

# Watch the #tests channel in Slack (join it if you haven't already). You might see notifications from others.

kubectl --namespace go-example \
    get pods \
    --selector app=go-example-chaos

###################################
# Sending Selective Notifications #
###################################

cat k8s/chaos/settings-failure.yaml

diff k8s/chaos/settings.yaml \
    k8s/chaos/settings-failure.yaml

cat k8s/chaos/settings-failure.yaml \
    | sed -e "s|@||g" \
    | kubectl --namespace go-example \
    apply --filename -

kubectl --namespace go-example \
    get pods \
    --selector app=go-example-chaos

# Observe that there were no new notification in Slack (not from you at least)

kubectl --namespace go-example \
    delete deployment go-example

# Watch the #tests channel in Slack.

##############################
# Destroying What We Created #
##############################

cd ..

kubectl delete namespace go-example