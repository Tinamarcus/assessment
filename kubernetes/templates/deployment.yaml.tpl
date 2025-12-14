apiVersion: apps/v1
kind: Deployment
metadata:
  name: tina-deployment
  namespace: tina-ns
  labels:
    app: tasky
spec:
  replicas: 2
  selector:
    matchLabels:
      app: tasky
  template:
    metadata:
      labels:
        app: tasky
    spec:
      serviceAccountName: tina-sa
      containers:
      - name: tasky
        image: ${container_image}
        imagePullPolicy: Always
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: MONGODB_URI
          value: "mongodb://appuser:apppass123@${mongodb_private_ip}:27017/go-mongodb?authSource=go-mongodb&authMechanism=SCRAM-SHA-256"
        - name: SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: tina-secrets
              key: secret-key
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5