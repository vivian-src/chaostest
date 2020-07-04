SHELL = /bin/sh
ISTIO_VERSION := 1.6.4

cluster:
	kind create cluster \
	--config kind/config.yaml \
	--kubeconfig ~/.kube/kind-cluster \
	--name cluster

multinodecluster:
	kind create cluster \
	--config kind/multinodeconfig.yaml \
	--kubeconfig ~/.kube/kind-multinodecluster \
	--name multinodecluster

test-cluster:
	kind create cluster \
	--config kind/km-config.yaml \
	--kubeconfig ~/.kube/kind-multinodeconfig \
	--name kindmultinodeconfig

destroy:
	kind delete cluster --name poc-istio

init-istio:
	./scripts/istio-init.sh ${ISTIO_VERSION}

install-istio:
	./scripts/install-istio.sh ${ISTIO_VERSION}

portforward-grafana:
	kubectl port-forward -n istio-system deployment/grafana 3000:3000

portforward-prometheus:
	kubectl port-forward -n istio-system deployment/prometheus 9090:9090

enable-metallb:
	kubectl apply -f metallb/namespace.yaml && kubectl apply -f metallb/metallb.yaml && kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" && kubectl apply -f metallb/configmap.yaml
