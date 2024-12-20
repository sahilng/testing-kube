#!/bin/bash

# Start Minikube
echo "Starting Minikube..."
minikube start --driver=docker

# Apply Kubernetes configurations
echo "Applying Kubernetes configurations..."
kubectl apply -f postgres-deployment.yaml
kubectl apply -f flask-deployment.yaml

# Wait a few seconds for the above to complete
sleep 5

# Wait for PostgreSQL pod to be ready
echo "Waiting for PostgreSQL pod to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s

# Wait a few seconds for service to be ready
sleep 5

# Port-forward to access PostgreSQL locally
echo "Port-forwarding PostgreSQL service to local port 5432..."
kubectl port-forward svc/postgres-service 5432:5432 &

# Wait a few seconds for port-forwarding to take effect
sleep 5

# Create the `pod_requests` table in PostgreSQL
echo "Creating pod_requests table in PostgreSQL..."
psql -h localhost -U yourusername -d yourdb << EOF
CREATE TABLE IF NOT EXISTS pod_requests (
    id SERIAL PRIMARY KEY,
    pod_name VARCHAR(100) NOT NULL,
    request_count INTEGER NOT NULL DEFAULT 1
);
EOF

# Verify that the Flask app pods are running
echo "Waiting for Flask app pods to be ready..."
kubectl wait --for=condition=ready pod -l app=flask --timeout=120s

# Display the status of all resources
echo "Setup complete. Displaying status of resources:"
kubectl get all -n default

# Show Minikube service URL for the Flask app
echo "Access the Flask app at the following URL:"
minikube service flask-service --url

echo "Setup finished successfully."