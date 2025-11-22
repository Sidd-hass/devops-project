# 🚀 Flask DevOps Project with Kubernetes, NGINX Ingress, Basic Auth, Terraform & Monitoring

This guide explains how to deploy a **Flask application** on **Kubernetes** with:
- NGINX Ingress Controller  
- Basic Authentication  
- LoadBalancer Service  
- Terraform integration for automation  
- Prometheus & Grafana monitoring  

---

## 🧩 Prerequisites
Before starting, ensure you have the following installed:

- Docker  
- Minikube, K3s, or any Kubernetes cluster  
- kubectl  
- Helm  
- Terraform  

---

## ⚙️ Step 1: Setup Kubernetes Cluster

If using **K3s**:
```bash
curl -sfL https://get.k3s.io | sh -
sudo kubectl get nodes
```

If using **Minikube**:
```bash
minikube start --driver=docker
kubectl get nodes
```

---

## 🐍 Step 2: Deploy Flask Application

### Create Deployment
`k8s/flask-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-devops
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask-devops
  template:
    metadata:
      labels:
        app: flask-devops
    spec:
      imagePullSecrets:
        - name: dockerhub-secret
      containers:
        - name: flask-devops
          image: sidd24/devops-assignment:latest
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 5000
          livenessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 5000
            initialDelaySeconds: 5
            periodSeconds: 5
          env:
            - name: FLASK_DEBUG
              value: "false"
```

### Create Service
`k8s/flask-service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-service
spec:
  selector:
    app: flask-devops
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  type: ClusterIP
```

Apply the files:
```bash
kubectl apply -f k8s/flask-deployment.yaml
kubectl apply -f k8s/flask-service.yaml
```

---

## 💥 Step 3: Test Auto-Restart (Crash Simulation)

To simulate a crash and verify Kubernetes self-healing:

```bash
curl -u admin:password http://flask.74.220.25.209.nip.io/crash
```

You’ll get:
```
Pod will be marked unhealthy soon
```

Then check the pod status:
```bash
kubectl get pods -l app=flask-devops -w
```

You’ll see something like:
```
flask-devops-84b89c586b-gpj4s   0/1   Running   1 (5s ago)   3m25s
```
The **RESTARTS** count confirms Kubernetes restarted your container.

---

## 🌐 Step 4: Install NGINX Ingress Controller

Using Helm:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx   --namespace ingress-nginx --create-namespace
```

Verify installation:
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

---

## 🔐 Step 5: Setup Basic Authentication

Create username and password using `htpasswd`:
```bash
sudo apt install apache2-utils -y
htpasswd -c auth admin
# Enter password when prompted
```

Create Kubernetes secret:
```bash
kubectl create secret generic basic-auth --from-file=auth
kubectl get secret basic-auth -o yaml
```

---

## 🌍 Step 6: Configure Ingress Resource for Flask, Grafana & Prometheus

`k8s/ingress.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: devops-ingress
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
spec:
  ingressClassName: nginx
  rules:
    - host: flask.74.220.25.209.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: flask-service
                port:
                  number: 80
    - host: grafana.74.220.25.209.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 80
    - host: prometheus.74.220.25.209.nip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-server
                port:
                  number: 80
```

Apply it:
```bash
kubectl apply -f k8s/ingress.yaml
```

Verify:
```bash
kubectl get ingress
```

---

## ⚒️ Step 7: Automate with Terraform

### Folder structure:
```
terraform/
├── main.tf
├── provider.tf
├── variables.tf
├── outputs.tf
```

### Example `provider.tf`
```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}
```

### Example `main.tf`
```hcl
resource "kubernetes_deployment" "flask" {
  metadata {
    name = "flask-devops"
    labels = { app = "flask-devops" }
  }

  spec {
    replicas = 2
    selector {
      match_labels = { app = "flask-devops" }
    }
    template {
      metadata {
        labels = { app = "flask-devops" }
      }
      spec {
        container {
          name  = "flask-devops"
          image = "flask-devops:latest"
          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "flask_service" {
  metadata {
    name = "flask-service"
  }
  spec {
    selector = { app = "flask-devops" }
    port {
      port        = 80
      target_port = 5000
    }
    type = "LoadBalancer"
  }
}
```

### Run Terraform:
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

---

## 📊 Step 8: Monitoring with Prometheus & Grafana

### Install using Helm
```bash
# Add Helm repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace

# Install Grafana
helm install grafana grafana/grafana --namespace monitoring
```

Grafana and Prometheus are accessible publicly via:
- Grafana: [http://grafana.74.220.25.209.nip.io/](http://grafana.74.220.25.209.nip.io/)  
- Prometheus: [http://prometheus.74.220.25.209.nip.io/](http://prometheus.74.220.25.209.nip.io/)

Configure Grafana data source:
- Go to **Configuration → Data Sources → Add → Prometheus**  
- URL: `http://prometheus-server.monitoring.svc.cluster.local:80`  
- Save & Test  

Import a Kubernetes monitoring dashboard:
- **Create → Import → Dashboard ID 315** (Kubernetes Cluster Monitoring)

---

## 🧭 Step 9: Validate Deployment & Monitoring
Check all resources:
```bash
kubectl get pods,svc,ingress -n default
kubectl get pods,svc -n monitoring
```

Verify:
- Flask app running & accessible via Ingress + Basic Auth  
- Prometheus scraping metrics  
- Grafana dashboards show Pod CPU/Memory, Restarts, and Liveness/Readiness probe status  

---

## 🎯 Conclusion
You’ve successfully:
- Deployed Flask app to Kubernetes  
- Configured Liveness & Readiness probes for auto-healing  
- Secured it with Basic Auth  
- Exposed via NGINX Ingress + LoadBalancer  
- Automated setup with Terraform  
- Set up monitoring with Prometheus & Grafana (publicly accessible)  

---

🧑‍💻 **Author:** Siddhant Kumar Pandey  
📘 **Tech Stack:** Flask, Docker, Kubernetes, NGINX, Terraform, Prometheus, Grafana
