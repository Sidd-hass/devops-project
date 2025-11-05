# 🚀 Flask DevOps Project with Kubernetes, NGINX Ingress, Basic Auth & Terraform

This guide explains how to deploy a **Flask application** on **Kubernetes** with:
- NGINX Ingress Controller  
- Basic Authentication  
- LoadBalancer Service  
- Terraform integration for automation  

---

## 🧩 Prerequisites
Before starting, ensure you have the following installed:

- Docker  
- Minikube or K3s (or any Kubernetes cluster)  
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
      containers:
      - name: flask-devops
        image: flask-devops:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
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

## 🌐 Step 3: Install NGINX Ingress Controller

Using Helm:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

Verify installation:
```bash
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

---

## 🔐 Step 4: Setup Basic Authentication

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

## 🌍 Step 5: Configure Ingress Resource

`k8s/flask-ingress.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: flask-ingress
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
spec:
  ingressClassName: nginx
  rules:
  - host: flask.<external-ip>.nip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: flask-service
            port:
              number: 80
```

Apply it:
```bash
kubectl apply -f k8s/flask-ingress.yaml
```

Verify:
```bash
kubectl get ingress
```

Example Output:
```
NAME            CLASS   HOSTS                        ADDRESS         PORTS   AGE
flask-ingress   nginx   flask.74.220.25.209.nip.io   74.220.25.209   80      12m
```

---

## ☁️ Step 6: Expose Flask Service via LoadBalancer

Patch the existing service:
```bash
kubectl patch service flask-service -p '{"spec":{"type":"LoadBalancer"}}'
```

Verify:
```bash
kubectl get svc flask-service
```

Example Output:
```
NAME            TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
flask-service   LoadBalancer   10.43.83.31   74.220.25.49    80:32617/TCP   4m18s
```

---

## ✅ Step 7: Test Access

Access the app in your browser or via curl:
```bash
curl -u admin:<your_password> http://flask.<external-ip>.nip.io
```

If authentication works, you’ll see your Flask app response.

---

## ⚒️ Step 8: Automate with Terraform

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

## 🧭 Step 9: Validate Deployment
Check all resources:
```bash
kubectl get pods,svc,ingress
```

Expected:
- Flask app running  
- LoadBalancer service created  
- Ingress accessible via `http://flask.74.220.25.209.nip.io/`  
- Basic Auth enabled  

---

## 🎯 Conclusion
You’ve successfully:
- Deployed Flask app to Kubernetes  
- Secured it with Basic Auth  
- Exposed it via NGINX Ingress + LoadBalancer  
- Automated setup with Terraform  

---

🧑‍💻 **Author:** Siddhant Kumar Pandey  
📘 **Tech Stack:** Flask, Docker, Kubernetes, NGINX, Terraform  


