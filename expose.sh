#!/bin/bash

sudo apt install socat -y
echo ""
echo "Relaying port 80 on the current machine to the flask-service in the minikube cluster..."
sudo socat TCP-LISTEN:80,fork TCP:192.168.49.2:30080