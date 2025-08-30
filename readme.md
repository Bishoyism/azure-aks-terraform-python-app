# Microservices Deployment on AKS

## Prerequisites
- Azure CLI (`az`)
- kubectl
- Docker
- Terraform
- Helm (for monitoring stack)

## 1. Infrastructure Setup (Terraform)
```bash
# Initialize Terraform
cd terraform/
terraform init

# Plan and apply
terraform plan
terraform apply -auto-approve

# Get AKS credentials
az aks get-credentials --resource-group aks-microservices-rg --name aks-microservices-cluster
```

## 2. Build & Push Docker Image
```bash
# Build (for AKS compatibility)
docker build --platform linux/amd64 -t bishoyflaskregistry.azurecr.io/microservices-app:latest .

# Login to ACR
az acr login --name bishoyflaskregistry

# Push to ACR
docker push bishoyflaskregistry.azurecr.io/microservices-app:latest
```

## 3. Kubernetes Deployment
```bash
# Create namespaces
kubectl create namespace app
kubectl create namespace monitoring

# Deploy microservice
kubectl apply -f kubernetes/ -n app

# Deploy monitoring stack
kubectl apply -f monitoring/ -n monitoring
```

## 4. Monitoring Access
```bash
# Port-forward Grafana
kubectl port-forward svc/grafana -n monitoring 3000:80

# Port-forward Prometheus
kubectl port-forward svc/prometheus -n monitoring 9090:9090
```

## 5. CI/CD (GitHub Actions)
```yaml
# See .github/workflows/deploy.yaml
# Requires AZURE_CREDENTIALS secret in GitHub
```

## Essential Maintenance Commands
```bash
# Restart deployment
kubectl rollout restart deployment microservice-deployment -n app

# View logs
kubectl logs -f <pod-name> -n app

# Check pod status
kubectl get pods -n app -w

# Scale deployment
kubectl scale deployment microservice-deployment --replicas=3 -n app
```

## Cleanup
```bash
# Delete all resources
terraform destroy

# Or delete Kubernetes resources
kubectl delete all --all -n app
kubectl delete all --all -n monitoring
```

## Project Structure
├── app/ - Python microservice code
├── kubernetes/ - K8s deployment files
│ ├── deployment.yaml
│ ├── service.yaml
│ └── ingress.yaml
├── monitoring/ - Prometheus/Grafana configs
├── terraform/ - Infrastructure as Code
└── .github/workflows/ - CI/CD pipeline


# Troubleshooting
- **Image pull errors**: Run `az aks update --attach-acr bishoyflaskregistry`
- **Permission issues**: Add `--platform linux/amd64` to Docker builds
- **Monitoring setup**: Ensure Prometheus Operator is installed via Helm


# Create Azure Service Principal
az ad sp create-for-rbac --name github-actions-sp \
    --role contributor \
    --scopes /subscriptions/f7bce28b-d2d9-474f-99cc-5c05fc272c89/resourceGroups/aks-microservices-rg \
    --sdk-auth

