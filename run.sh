#!/bin/bash

# Set variables

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found. Please create one with your Docker username."
    exit 1
fi

# Verify that DOCKER_USERNAME is set
if [ -z "$DOCKER_USERNAME" ]; then
    echo "DOCKER_USERNAME is not set in .env file."
    exit 1
fi

IMAGE_NAME="flask-app-image"
NAMESPACE="default"

# 1. Start Minikube
echo "Starting Minikube..."
minikube start --driver=docker

# 2. Configure Docker to use Minikube’s Docker daemon
echo "Configuring Docker to use Minikube’s Docker environment..."
eval $(minikube -p minikube docker-env)

# 3. Build Docker image
echo "Building Docker image..."
docker build -t $DOCKER_USERNAME/$IMAGE_NAME:latest flask_app

# 4. Push Docker image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push $DOCKER_USERNAME/$IMAGE_NAME:latest

# 5. Revert to the local Docker environment
echo "Reverting to the local Docker environment..."
eval $(minikube docker-env -u)

# 6. Apply Kubernetes configurations
echo "Applying Kubernetes configurations..."
kubectl apply -f postgres-deployment.yaml
kubectl apply -f flask-deployment.yaml

# Wait for PostgreSQL pod to be ready
echo "Waiting for PostgreSQL pod to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# 7. Port-forward to access PostgreSQL locally
echo "Port-forwarding PostgreSQL service to local port 5432..."
kubectl port-forward svc/postgres-service 5432:5432 &

# Wait a few seconds for port-forwarding to take effect
sleep 5

# 8. Create the `pod_requests` table in PostgreSQL
echo "Creating pod_requests table in PostgreSQL..."
psql -h localhost -U yourusername -d yourdb << EOF
CREATE TABLE IF NOT EXISTS pod_requests (
    id SERIAL PRIMARY KEY,
    pod_name VARCHAR(100) NOT NULL,
    request_count INTEGER NOT NULL DEFAULT 1
);
EOF

# 9. Verify that the Flask app pods are running
echo "Waiting for Flask app pods to be ready..."
kubectl wait --for=condition=ready pod -l app=flask --timeout=120s

# Display the status of all resources
echo "Setup complete. Displaying status of resources:"
kubectl get all -n $NAMESPACE

# Show Minikube service URL for the Flask app
echo "Access the Flask app at the following URL:"
minikube service flask-service --url

echo "Setup finished successfully."
