# Deploying Expense Tracker Application on AWS EKS with RDS

Here's a comprehensive guide to deploy your application on AWS EKS with RDS PostgreSQL:

## Prerequisites
1. AWS Account with appropriate permissions
2. AWS CLI installed and configured
3. eksctl installed
4. kubectl installed
5. Docker installed (for any local testing)

## Step 1: Create an RDS PostgreSQL Database

1. **Go to AWS RDS Console**:
   - Navigate to https://console.aws.amazon.com/rds/

2. **Create Database**:
   - Click "Create database"
   - Choose "Standard create"
   - Select "PostgreSQL"
   - Choose version (recommend 13.x to match your docker setup)
   - Select "Free tier" template (for testing) or appropriate production template
   - Set DB instance identifier: `expense-tracker-db`
   - Set master username: `user`
   - Set master password: `pass` (use a stronger password in production)
   - DB instance class: db.t3.micro (free tier eligible)
   - Storage: 20GB General Purpose SSD
   - Under "Connectivity":
     - Choose "Don't connect to an EC2 compute resource"
     - Public access: Yes (for testing, No for production)
     - Create new VPC security group: `expense-tracker-db-sg`
     - Add inbound rule to allow your IP or all IPs (for testing)
   - Database name: `expenses_db`
   - Click "Create database"

3. **Note the Endpoint**:
   - Once created, note the RDS endpoint (will look like `expense-tracker-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com`)

## Step 2: Create an EKS Cluster

1. **Create EKS Cluster**:
   ```bash
   eksctl create cluster \
     --name expense-tracker-cluster \
     --region us-east-1 \
     --nodegroup-name standard-workers \
     --node-type t3.medium \
     --nodes 2 \
     --nodes-min 1 \
     --nodes-max 3 \
     --managed
   ```

2. **Update kubeconfig**:
   ```bash
   aws eks --region us-east-1 update-kubeconfig --name expense-tracker-cluster
   ```

3. **Verify cluster**:
   ```bash
   kubectl get nodes
   ```

## Step 3: Prepare Kubernetes Manifests

Create the following files:

### 1. `backend-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
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
        image: devopsdktraining/expense-tracker-app-backend:2
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@expense-tracker-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com:5432/expenses_db"
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /expenses/
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /expenses/
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
```

### 2. `backend-service.yaml`
```yaml
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
```

### 3. `frontend-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: devopsdktraining/expense-tracker-app-frontend:1
        ports:
        - containerPort: 5000
        env:
        - name: API_URL
          value: "http://backend:8000"
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 10
```

### 4. `frontend-service.yaml`
```yaml
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

### 5. `init-db-job.yaml` (One-time job to initialize DB)
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-init
spec:
  template:
    spec:
      containers:
      - name: db-init
        image: devopsdktraining/expense-tracker-app-backend:2
        command: ["/bin/sh", "-c"]
        args:
          - >
            sleep 20;
            python -c "
            import time
            from app.database import engine
            from app.models import Base
            from sqlalchemy import exc

            for _ in range(10):
                try:
                    engine.connect()
                    break
                except exc.OperationalError:
                    print('Waiting for database...')
                    time.sleep(2)
            else:
                raise RuntimeError('Could not connect to database')

            Base.metadata.drop_all(bind=engine)
            Base.metadata.create_all(bind=engine)
            print('Tables initialized successfully')
            "
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@expense-tracker-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com:5432/expenses_db"
      restartPolicy: Never
  backoffLimit: 2
```

## Step 4: Deploy to EKS

1. **Apply the configurations**:
   ```bash
   kubectl apply -f init-db-job.yaml
   kubectl apply -f backend-deployment.yaml
   kubectl apply -f backend-service.yaml
   kubectl apply -f frontend-deployment.yaml
   kubectl apply -f frontend-service.yaml
   ```

2. **Check the status**:
   ```bash
   kubectl get pods
   kubectl get services
   ```

3. **Get the frontend LoadBalancer URL**:
   ```bash
   kubectl get service frontend
   ```
   - Note the EXTERNAL-IP (it may take a few minutes to provision)

## Step 5: Update the Footer in Frontend

Since you want to add the copyright footer without changing the UI, we'll create a new deployment with a modified frontend image:

1. **Create a new Dockerfile for frontend**:
   ```dockerfile
   FROM devopsdktraining/expense-tracker-app-frontend:1

   # Modify the template
   RUN sed -i '/<\/body>/i <footer style="text-align: center; padding: 20px; margin-top: 30px; color: #666;">© 2025, Devops with Deepak - Copyright</footer>' /app/templates/index.html
   ```

2. **Build and push the image** (you'll need Docker Hub or ECR access):
   ```bash
   docker build -t yourusername/expense-frontend:with-footer .
   docker push yourusername/expense-frontend:with-footer
   ```

3. **Update frontend-deployment.yaml** to use the new image:
   ```yaml
   # In frontend-deployment.yaml, change the image to:
   image: yourusername/expense-frontend:with-footer
   ```

4. **Apply the updated deployment**:
   ```bash
   kubectl apply -f frontend-deployment.yaml
   ```

## Step 6: Verify the Application

1. Access the frontend using the LoadBalancer URL
2. Verify the footer is displayed at the bottom
3. Test adding and deleting expenses

## Step 7: Cleanup (When Needed)

```bash
# Delete the EKS cluster
eksctl delete cluster --name expense-tracker-cluster --region us-east-1

# Delete the RDS instance (via AWS Console)
```

## Additional Recommendations for Production

1. **Use Secrets for Database Credentials**:
   - Store DB credentials in Kubernetes Secrets instead of plain text in deployment files

2. **Configure Auto-scaling**:
   - Add Horizontal Pod Autoscaler (HPA) for both frontend and backend

3. **Set up Monitoring**:
   - Configure CloudWatch or Prometheus for monitoring

4. **Implement CI/CD Pipeline**:
   - Use AWS CodePipeline or GitHub Actions for automated deployments

5. **Configure Proper Security**:
   - Restrict RDS access to only EKS nodes
   - Use IAM roles for service accounts

6. **Add HTTPS**:
   - Configure an ALB with SSL certificate for secure connections

Would you like me to elaborate on any specific part of this deployment process?

# Implementing Secrets for Database Credentials in EKS

To properly secure your database credentials, we'll use Kubernetes Secrets and ConfigMaps instead of hardcoding them in the deployment files. Here's how to implement this:

## Step 1: Create Kubernetes Secrets for Database Credentials

1. **Create a secret for the database credentials**:
```bash
kubectl create secret generic db-credentials \
  --from-literal=username=user \
  --from-literal=password=pass
```

## Step 2: Create a ConfigMap for the Database Configuration

1. **Create a configmap for the non-sensitive database configuration**:
```bash
kubectl create configmap db-config \
  --from-literal=host=expense-tracker-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com \
  --from-literal=name=expenses_db \
  --from-literal=port="5432"
```

## Step 3: Update the Backend Deployment

Modify your `backend-deployment.yaml` to use these secrets:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
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
        image: devopsdktraining/expense-tracker-app-backend:2
        ports:
        - containerPort: 8000
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: host
        - name: DB_NAME
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: name
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: port
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        - name: DATABASE_URL
          value: "postgresql://$(DB_USERNAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)"
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        # ... rest of the configuration remains the same ...
```

## Step 4: Update the DB Initialization Job

Modify your `init-db-job.yaml` similarly:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-init
spec:
  template:
    spec:
      containers:
      - name: db-init
        image: devopsdktraining/expense-tracker-app-backend:2
        command: ["/bin/sh", "-c"]
        args:
          - >
            sleep 20;
            python -c "
            import time
            from app.database import engine
            from app.models import Base
            from sqlalchemy import exc

            for _ in range(10):
                try:
                    engine.connect()
                    break
                except exc.OperationalError:
                    print('Waiting for database...')
                    time.sleep(2)
            else:
                raise RuntimeError('Could not connect to database')

            Base.metadata.drop_all(bind=engine)
            Base.metadata.create_all(bind=engine)
            print('Tables initialized successfully')
            "
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: host
        - name: DB_NAME
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: name
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: port
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        - name: DATABASE_URL
          value: "postgresql://$(DB_USERNAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)"
      restartPolicy: Never
  backoffLimit: 2
```

## Step 5: Apply the Updated Configurations

1. **Delete the old resources** (if they exist):
```bash
kubectl delete -f init-db-job.yaml
kubectl delete -f backend-deployment.yaml
```

2. **Apply the new configurations**:
```bash
kubectl apply -f init-db-job.yaml
kubectl apply -f backend-deployment.yaml
```

## Step 6: Verify the Deployment

1. **Check the logs of a backend pod to ensure it's connecting properly**:
```bash
kubectl get pods
kubectl logs <backend-pod-name>
```

2. **Verify the secret is being used correctly**:
```bash
kubectl exec -it <backend-pod-name> -- env | grep DB_
```

## Additional Security Recommendations

1. **Use AWS Secrets Manager or Parameter Store** (for better secret management):
   - Create an IAM policy for accessing the secret
   - Use an IAM role for service accounts (IRSA) to allow pods to access secrets

2. **Rotate Secrets Regularly**:
   - Implement a secret rotation policy
   - Update the Kubernetes secret when credentials change

3. **Restrict Access to Secrets**:
   - Use RBAC to limit who can access the secrets
   ```bash
   kubectl create role secret-access-role --resource=secrets --verb=get,list
   kubectl create rolebinding secret-access-binding --role=secret-access-role --serviceaccount=default:default
   ```

4. **Consider Using External Secrets Operator**:
   - This provides a better integration with AWS Secrets Manager
   - Automatically syncs secrets from AWS to Kubernetes

Would you like me to provide details on implementing any of these additional security measures?

# Creating Secrets and ConfigMap via YAML Files

Here are the YAML files to create your database configuration resources instead of using `kubectl create` commands:

## 1. Database Credentials Secret (`db-secret.yaml`)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  labels:
    app: expense-tracker
type: Opaque
stringData:
  username: user
  password: pass
```

**Important Security Note:**  
While we're using `stringData` here for clarity, in production you should:
1. Use base64-encoded values in `data` field instead
2. Store this file securely or use a secrets management tool
3. Consider using AWS Secrets Manager with External Secrets Operator

## 2. Database Configuration ConfigMap (`db-configmap.yaml`)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-config
  labels:
    app: expense-tracker
data:
  host: "expense-tracker-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com"
  name: "expenses_db"
  port: "5432"
```

## 3. Updated Backend Deployment (`backend-deployment.yaml`)

Here's how your backend deployment should reference these resources:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
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
        image: devopsdktraining/expense-tracker-app-backend:2
        ports:
        - containerPort: 8000
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: host
        - name: DB_NAME
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: name
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: port
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        - name: DATABASE_URL
          value: "postgresql://$(DB_USERNAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)"
        # ... rest of your configuration ...
```

## 4. Applying the Configuration

1. First apply the secret and configmap:
```bash
kubectl apply -f db-secret.yaml
kubectl apply -f db-configmap.yaml
```

2. Then apply your updated deployments:
```bash
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml
```

## Alternative: Base64-encoded Secret (More Secure)

For better security, you can encode the values in the secret:

1. Encode your values:
```bash
echo -n "user" | base64
echo -n "pass" | base64
```

2. Create `db-secret-encoded.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  username: dXNlcg==  # Replace with your encoded username
  password: cGFzcw==  # Replace with your encoded password
```

## Verification

To verify everything was created correctly:

```bash
# Check secrets
kubectl get secrets
kubectl describe secret db-credentials

# Check configmaps
kubectl get configmaps
kubectl describe configmap db-config

# Check environment variables in a pod
kubectl exec -it <backend-pod-name> -- env | grep DB_
```

Would you like me to provide any additional details about this configuration or show you how to implement more advanced secret management strategies?

# Base64 Encoded Secret YAML File

Here's the properly formatted secret with base64 encoded values:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  labels:
    app: expense-tracker
type: Opaque
data:
  username: dXNlcg==  # "user" encoded
  password: cGFzcw==  # "pass" encoded
```

## How to Generate the Base64 Values

1. **Encode your values** using these commands:

```bash
# For username
echo -n "user" | base64
# Output: dXNlcg==

# For password
echo -n "pass" | base64
# Output: cGFzcw==
```

2. **Verify the encoding**:

```bash
# Decode to verify
echo "dXNlcg==" | base64 --decode  # Should output "user"
echo "cGFzcw==" | base64 --decode  # Should output "pass"
```

## Important Notes

1. **Security Best Practices**:
   - Never commit this file to version control
   - Use a secrets management tool like AWS Secrets Manager in production
   - Rotate credentials regularly

2. **Using the Secret**:
   - Kubernetes will automatically decode these values when they're mounted or used as environment variables
   - The usage in your deployment remains the same as with `stringData`

3. **Alternative Creation Method**:
   If you prefer to create the secret imperatively but still want base64 encoding:

```bash
kubectl create secret generic db-credentials \
  --from-literal=username=user \
  --from-literal=password=pass \
  --dry-run=client -o yaml > db-secret.yaml
```

This will generate a YAML file with the values already base64 encoded.

Would you like me to provide any additional details about secret management in Kubernetes?

# Integrating Base64 Encoded Secrets in Backend Deployment

Here's how to properly integrate the base64 encoded secrets into your backend YAML files and how Kubernetes handles the decoding:

## 1. Updated `backend-deployment.yaml` with Secret Integration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
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
        image: devopsdktraining/expense-tracker-app-backend:2
        ports:
        - containerPort: 8000
        env:
        # Using ConfigMap for non-sensitive DB config
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: host
        - name: DB_NAME
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: name
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: db-config
              key: port
        # Using Secret for sensitive credentials
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        # Constructing DATABASE_URL from the above variables
        - name: DATABASE_URL
          value: "postgresql://$(DB_USERNAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)"
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /expenses/
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /expenses/
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 10
```

## How Kubernetes Handles the Base64 Decoding

1. **Automatic Decoding Process**:
   - When you apply the secret YAML with base64 encoded values, Kubernetes stores them encoded in etcd
   - When a pod references these secrets via `secretKeyRef`, Kubernetes automatically:
     - Retrieves the encoded values from etcd
     - Decodes them back to plaintext
     - Injects them into the container's environment variables

2. **At Runtime**:
   - Your application will receive the decoded values
   - In your Python code, when you access `os.getenv('DB_USERNAME')`, you'll get "user" (not the encoded version)
   - The DATABASE_URL will be properly constructed with decoded values

## Verification Steps

1. **Check the secret is properly created**:
```bash
kubectl get secret db-credentials -o yaml
```
(You'll see the base64 encoded values)

2. **Check the environment variables in a running pod**:
```bash
# Get a pod name
kubectl get pods

# Check env vars (will show decoded values)
kubectl exec -it <pod-name> -- env | grep DB_
```

3. **Verify database connection**:
```bash
kubectl logs <pod-name>
```
(Look for any database connection errors)

## Important Security Notes

1. **Never expose secrets**:
   - The values are only decoded in memory within your pod
   - They won't appear in pod definitions or when doing `kubectl describe pod`

2. **Secret Updates**:
   - If you update the secret, you'll need to restart your pods to get the new values
   - Consider using a rolling update:
   ```bash
   kubectl rollout restart deployment/backend
   ```

3. **Alternative Approach - Using Volumes**:
   If you prefer to mount secrets as files rather than environment variables:
```yaml
# Alternative volume mount approach
spec:
  containers:
  - name: backend
    volumeMounts:
    - name: db-secret
      mountPath: "/etc/db-secrets"
      readOnly: true
  volumes:
  - name: db-secret
    secret:
      secretName: db-credentials
```

Would you like me to show you how to implement secret rotation or integrate with AWS Secrets Manager for even better security?
