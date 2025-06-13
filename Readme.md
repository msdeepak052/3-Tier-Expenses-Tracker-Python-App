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

![image](https://github.com/user-attachments/assets/468ae542-ac5e-4b5b-8d36-ba2cdc16c2c3)

#### Deleting the Transport entry
![image](https://github.com/user-attachments/assets/11fd3bea-91d2-46a5-8015-b9b7d8a43c53)

![image](https://github.com/user-attachments/assets/2bca1fcb-7f03-4cd7-bf73-af9877839fde)



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

