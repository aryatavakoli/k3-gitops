kubectl create namespace tigera-operator
helm repo add projectcalico https://docs.tigera.io/calico/charts
helm install calico projectcalico/tigera-operator -f argo/applicationsets/git-generator-directory/apps/tigera-operator/values.yaml --namespace tigera-operator

kubectl create namespace metallb-system
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb -n metallb-system
sleep 2m
kubectl apply -f argo/applicationsets/git-generator-directory/apps/metallb/config.yaml -n metallb-system

kubectl create namespace prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n prometheus

kubectl create namespace nginx-ingress
helm repo add nginx-stable https://helm.nginx.com/stable
helm install nginx-ingress nginx-stable/nginx-ingress --set rbac.create=true -n nginx-ingress

kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager --set installCRDs=true -n cert-manager