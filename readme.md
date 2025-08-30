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
    --scopes /subscriptions/123456/resourceGroups/aks-microservices-rg \
    --sdk-auth

## Loki Logging System Deployment

### 1. Deploy Loki Stack
```bash
# Apply Loki configuration
kubectl apply -f monitoring/loki-config.yaml -n monitoring

# Deploy Loki with persistent storage
kubectl apply -f monitoring/loki-pvc.yaml -n monitoring
kubectl apply -f monitoring/loki-deployment.yaml -n monitoring
kubectl apply -f monitoring/loki-service.yaml -n monitoring

# Deploy Promtail log collector
kubectl apply -f monitoring/promtail-config.yaml -n monitoring
kubectl apply -f monitoring/promtail-daemonset.yaml -n monitoring
```

### 2. Verification Commands
```bash
# Check Loki status
kubectl get pods -n monitoring -l app=loki

# View Loki logs
kubectl logs -n monitoring -l app=loki --tail=50

# Check Promtail status
kubectl get pods -n monitoring -l app=promtail

# Verify Promtail is scraping logs
kubectl port-forward pod/$(kubectl get pod -n monitoring -l app=promtail -o jsonpath='{.items[0].metadata.name}') 9080:9080 &
curl http://localhost:9080/targets | jq .
```

### 3. Port Forwarding for Access
```bash
# Access Loki API
kubectl port-forward svc/loki -n monitoring 3100:3100 &

# Access Grafana UI
kubectl port-forward svc/grafana -n monitoring 3000:3000 &
```

### 4. Maintenance Commands
```bash
# Restart components
kubectl rollout restart deployment/loki -n monitoring
kubectl rollout restart daemonset/promtail -n monitoring

# Delete all Loki resources
kubectl delete -f monitoring/loki-config.yaml -f monitoring/loki-pvc.yaml \
  -f monitoring/loki-deployment.yaml -f monitoring/loki-service.yaml -n monitoring
```

### 5. Sample Queries
```bash
# Query Loki via CLI
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={namespace="app"}' | jq .

# Test log ingestion
echo '{"streams":[{"stream":{"test":"readme"},"values":[[ "'$(date +%s)'000000000", "test log from README" ]]}]}' | \
curl -H "Content-Type: application/json" -X POST --data-binary @- http://localhost:3100/loki/api/v1/push
```

### Grafana Configuration
1. Add Loki datasource: `http://loki.monitoring.svc.cluster.local:3100`
2. Sample queries:
   - `{namespace="app"}`
   - `{container="your-container"}`
   - `{test="readme"}`

### Troubleshooting
```bash
# Check storage utilization
kubectl exec -it -n monitoring $(kubectl get pods -n monitoring -l app=loki -o jsonpath='{.items[0].metadata.name}') -- df -h /var/loki

# Verify log ingestion rate
curl -s http://localhost:3100/metrics | grep log_entries_total
```

