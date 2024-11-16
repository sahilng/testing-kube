#!/bin/bash

sudo apt install socat -y
echo ""
echo "Relaying port 80 on the current machine to the flask-service in the minikube cluster..."
echo "socat TCP-LISTEN:80,fork TCP:$(minikube ip):30080"
sudo socat TCP-LISTEN:80,fork TCP:$(minikube ip):30080