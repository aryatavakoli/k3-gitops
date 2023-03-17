helm repo update

kubectl create namespace tigera-operator
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm install calico projectcalico/tigera-operator -f argo/applicationsets/git-generator-directory/apps/tigera-operator/values.yaml --namespace tigera-operator

kubectl create namespace metallb-system
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n metallb-system
sleep 1
kubectl create -f argo/applicationsets/git-generator-directory/apps/metallb/config.yaml -n metallb-system

kubectl create namespace prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n prometheus

kubectl create namespace istio-system
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm install istio-base istio/base -n istio-system --wait
helm install istiod istio/istiod -n istio-system --wait

kubectl label namespace istio-system istio-injection=enabled
helm install istio-ingressgateway istio/gateway -n istio-system --wait

# kubectl create namespace nginx-ingress
# helm repo add nginx-stable https://helm.nginx.com/stable
# helm install nginx-ingress nginx-stable/nginx-ingress --set rbac.create=true -n nginx-ingress

kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --set installCRDs=true -n cert-manager
# kubectl create -f argo/applicationsets/git-generator-directory/apps/cert-manager/letsencrypt-staging-http-challenge.yaml
# kubectl create -f argo/applicationsets/git-generator-directory/apps/cert-manager/letsencrypt-prod-http-challenge.yaml