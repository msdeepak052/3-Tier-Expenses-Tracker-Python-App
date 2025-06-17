#  **Expense Tracker App**


## 📁 Project Structure


```

expense-tracker/
├── frontend/
│   ├── app.py
│   ├── templates/
│   │   └── index.html
│   ├── requirements.txt
│   └── Dockerfile
backend/
├── Dockerfile
├── requirements.txt
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── models.py
│   ├── schemas.py
│   ├── crud.py
│   ├── database.py
│   └── tests/
│       └── test_api.py
├── jenkins/
│   ├── frontend/Jenkinsfile
│   └── backend/Jenkinsfile
├── k8s/
│   ├── frontend-deployment.yaml
│   ├── backend-deployment.yaml
│   ├── service-frontend.yaml
│   ├── service-backend.yaml
│   └── configmap-secret.yaml
└── 
```

## Docker Setup Instructions

### 1. Build Docker Images

From the root folder (`expense-tracker`):

```sh
docker build -t devopsdktraining/expense-tracker-app-frontend:1 ./frontend
docker build -t devopsdktraining/expense-tracker-app-backend:1 ./backend
```

### Docker Push

```bash

docker login
docker push devopsdktraining/expense-tracker-app-backend:1
docker push devopsdktraining/expense-tracker-app-frontend:1

```

### Images on Dockerhub details

#### Frontend & BAckend Image

![image](https://github.com/user-attachments/assets/5f2912ca-50e1-443b-af80-eab32ab81573)



---

### 2. Create Docker Network

Create a network so containers can communicate:

```sh
docker network create expense-tracker-net
```

---

### 3. Start PostgreSQL with Volume

```sh
docker run -d \
  --name expense-db \
  --network expense-tracker-net \
  --restart unless-stopped \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=pass \
  -e POSTGRES_DB=expenses_db \
  -e PGDATA=/var/lib/postgresql/data/pgdata \
  -v pgdata:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:13-alpine \
  -c shared_buffers=256MB \
  -c max_connections=200
```


---

### 4. Wait for DB Initialization

```sh
sleep 20
```

---

### 5. Start Backend (with healthcheck)

```sh
docker run -d \
  --name backend \
  --network expense-tracker-net \
  --restart unless-stopped \
  -e DATABASE_URL=postgresql://user:pass@expense-db:5432/expenses_db \
  -p 8000:8000 \
  devopsdktraining/expense-tracker-app-backend:2
```

#### (Optional) Recreate Tables

```sh
docker exec -it backend python -c "
import time
from app.database import engine
from app.models import Base
from sqlalchemy import exc

# Wait for database to be ready
for _ in range(10):
    try:
        engine.connect()
        break
    except exc.OperationalError:
        print('Waiting for database...')
        time.sleep(2)
else:
    raise RuntimeError('Could not connect to database')

# Recreate tables
Base.metadata.drop_all(bind=engine)
Base.metadata.create_all(bind=engine)
print('Tables initialized successfully')
"
```

---

### 6. Start Frontend

```sh
docker run -d \
  --name frontend \
  --network expense-tracker-net \
  --restart unless-stopped \
  -e API_URL=http://backend:8000 \
  -p 5000:5000 \
  devopsdktraining/expense-tracker-app-frontend:2
```

---
Optionally, insert a test record and check the table:

```sh
docker exec -it expense-db psql -U user -d expenses_db -c "INSERT INTO expenses (category, amount) VALUES ('Manual', 100.00); SELECT * FROM expenses;"
```
### 7. Connect to PostgreSQL Container

```sh
docker exec -it expense-db psql -U user -d expenses_db
```

Inside `psql`:

```
\dt                -- Should show "expenses" table
SELECT * FROM expenses;
\q
```

Or, from outside:

```sh
docker exec -it expense-db psql -U user -d expenses_db -c "SELECT * FROM expenses;"
```

---

### 8. Access the Application

- Backend: [http://localhost:8000/expenses/](http://localhost:8000/expenses/)
- Frontend: [http://localhost:5000](http://localhost:5000)

![image](https://github.com/user-attachments/assets/d21cdd03-f9f6-414d-9bb3-b55983a7e809)


#### Deleting the Transport entry

![image](https://github.com/user-attachments/assets/27ae22f8-93ef-43f9-b277-a37c7b0d4f9b)

![image](https://github.com/user-attachments/assets/32fae2d5-d318-4f5e-a020-267d3e2a7345)


Yes, the server name (`d78e390cba08`) and IP (`172.19.0.4`) you're seeing are **Docker container details**, not your local machine's hostname or IP. This is expected behavior when running inside Docker.

### Why You See Docker Container Details:
1. **`hostname`** inside a Docker container returns the container ID (like `d78e390cba08`).
2. **`socket.gethostbyname()`** returns the container's internal Docker network IP (`172.19.0.4`), not your machine's LAN/WAN IP.

---

### How to Validate if This is a Docker IP:
Run these commands to check:

#### 1. **List all Docker networks and containers:**
```bash
docker network inspect expense-tracker-net
```
This will show all containers (`frontend`, `backend`, `expense-db`) and their assigned IPs (like `172.19.0.4`).

#### 2. **Check your container's IP directly:**
```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' frontend
```
This should return `172.19.0.4` (or similar).

#### 3. **Ping the IP from your host machine:**
```bash
ping 172.19.0.4
```
If it responds, it confirms the IP belongs to a Docker container.

---

### If You Want to Show Your Local Machine's IP Instead:
Modify `get_server_info()` in `frontend/app.py` to use your host IP:

#### Option 1: Get LAN IP (Recommended)
```python
def get_server_info():
    hostname = socket.gethostname()
    # Get LAN IP (works on Linux/macOS/Windows)
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Doesn't need to be reachable
        s.connect(('10.255.255.255', 1))
        ip_address = s.getsockname()[0]
    except Exception:
        ip_address = socket.gethostbyname(hostname)
    finally:
        s.close()
    return {
        'hostname': hostname,
        'ip_address': ip_address
    }
```

#### Option 2: Get Public IP (Requires Internet)
```python
def get_server_info():
    hostname = socket.gethostname()
    try:
        ip_address = requests.get('https://api.ipify.org').text
    except:
        ip_address = "Not available"
    return {
        'hostname': hostname,
        'ip_address': ip_address
    }
```

#### Option 3: Show Both Docker and Host IPs
```python
def get_server_info():
    docker_hostname = socket.gethostname()
    docker_ip = socket.gethostbyname(docker_hostname)
    
    # Get host machine LAN IP
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        host_ip = s.getsockname()[0]
    except Exception:
        host_ip = "Not available"
    finally:
        s.close()
    
    return {
        'docker_hostname': docker_hostname,
        'docker_ip': docker_ip,
        'host_ip': host_ip
    }
```
Then update the template to show both:
```html
<div class="server-info">
    <strong>Container:</strong> {{ server_info.docker_hostname }} ({{ server_info.docker_ip }})<br>
    <strong>Host Machine:</strong> {{ server_info.host_ip }}
</div>
```

---


---

# End-to-End Connectivity Guide for Expense Tracker App on EKS

Let me explain how the frontend, backend, and database connect in this architecture when deployed on EKS.

## 1. Database Connection (Backend to RDS)

**Where it's configured:**
- `backend/app/database.py` contains the database connection logic
- The connection string comes from the environment variable `DATABASE_URL`

**Key points:**
```python
DATABASE_URL = os.getenv("DATABASE_URL")  # Format: postgresql://user:password@host:port/dbname
engine = create_engine(DATABASE_URL)
```

**When deploying to EKS:**
1. You'll need to create an RDS PostgreSQL instance
2. Store the connection details in a Kubernetes Secret:
   ```yaml
   # k8s/configmap-secret.yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: backend-secrets
   type: Opaque
   data:
     DATABASE_URL: <base64-encoded-connection-string>
   ```
3. Mount this secret to your backend deployment

## 2. Frontend to Backend Connection

**Where it's configured:**
- `frontend/app.py` has the backend API URL configuration:
  ```python
  API_URL = "http://backend:8000"  # 'backend' is the Kubernetes service name
  ```

**Key points:**
1. The frontend connects to backend using the Kubernetes service name (`backend`)
2. Port 8000 is the default FastAPI port (configured in backend's Dockerfile)

**When deploying to EKS:**
1. You'll need:
   - A backend Service (ClusterIP) exposing port 8000
   - A frontend Service (LoadBalancer) exposing port 5000

Example service definitions:
```yaml
# k8s/service-backend.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000

# k8s/service-frontend.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
```

## 3. Network Flow in EKS

```
Internet User → AWS ALB (via frontend Service) → Frontend Pod (port 5000)
Frontend Pod → Backend Service (DNS name "backend") → Backend Pod (port 8000)
Backend Pod → RDS Endpoint (from DATABASE_URL secret)
```

## 4. Port Configuration Summary

| Component | Container Port | Service Port | Exposed As |
|-----------|----------------|--------------|------------|
| Frontend  | 5000           | 80 (Service) | ALB (port 80) |
| Backend   | 8000           | 8000         | Cluster-internal (backend:8000) |

## 5. Required Kubernetes Manifests

You'll need these essential manifests:

1. **Deployments** (frontend-deployment.yaml, backend-deployment.yaml)
   - Ensure backend has the secret mounted
   - Both should have proper liveness/readiness probes

2. **Services** (service-frontend.yaml, service-backend.yaml)
   - Frontend as LoadBalancer
   - Backend as ClusterIP

3. **ConfigMap/Secret** (configmap-secret.yaml)
   - Contains DATABASE_URL and any other configs

4. **Ingress** (optional, if using ALB)
   - To route traffic to frontend service

## 6. DNS Resolution in EKS

- Frontend accesses backend via Kubernetes DNS:
  - Service name `backend` resolves to ClusterIP
  - Port 8000 is the backend service port
- Backend accesses RDS via the full RDS endpoint URL from the secret


The error indicates your backend application is failing because it can't connect to the PostgreSQL database. The key error is:

```
sqlalchemy.exc.ArgumentError: Expected string or URL object, got None
```

This means the `DATABASE_URL` environment variable is not set in your Kubernetes pod. Let's fix this:

### Solution: Properly Configure the Backend Deployment

1. **First, check your existing database service**:
```bash
kubectl get svc expense-db
```
(If you don't see it, you'll need to deploy PostgreSQL first)

2. **Create a Kubernetes Secret for database credentials**:
```bash
kubectl create secret generic db-credentials \
  --from-literal=POSTGRES_USER=user \
  --from-literal=POSTGRES_PASSWORD=pass \
  --from-literal=POSTGRES_DB=expenses_db
```

3. **Create a proper deployment YAML** (`backend-deployment.yaml`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: your-backend-image
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@expense-db:5432/expenses_db"
        ports:
        - containerPort: 8000
---
apiVersion: v1
kind: Service
metadata:
  name: expense-db
spec:
  selector:
    app: postgres
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
```

4. **Apply the configuration**:
```bash
kubectl apply -f backend-deployment.yaml
```

### If You Need to Deploy PostgreSQL First:

1. **Create PostgreSQL deployment** (`postgres-deployment.yaml`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:13-alpine
        envFrom:
        - secretRef:
            name: db-credentials
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-data
        persistentVolumeClaim:
          claimName: postgres-pvc
```

2. **Create Persistent Volume Claim** (`postgres-pvc.yaml`):
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

3. **Apply all configurations**:
```bash
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f backend-deployment.yaml
```

### Verify Everything Works:

1. Check pods:
```bash
kubectl get pods
```

2. Check backend logs:
```bash
kubectl logs <backend-pod-name>
```

3. Access your application:
```bash
kubectl port-forward svc/backend 8000:8000
```
Then visit http://localhost:8000

### Key Points:
1. The database URL must be accessible from the backend pod
2. All environment variables must be properly set
3. The database service must be running before the backend starts
4. Use `kubectl describe pod <pod-name>` to debug startup issues

Would you like me to:
1. Show how to add liveness/readiness probes?
2. Add configuration for the frontend service?
3. Set up database backups?

