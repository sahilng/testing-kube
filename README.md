# Testing Kube

A demo minikube cluster that launches 3 flask pods and 1 postgres pod. 

The flask app is then made available and shows the distribution of requests (stored in postgres) to the flask pods as a bar chart.

## Usage

- Install Docker, `kubectl`, `minikube`, and `psql`
- Start Docker
- `./run.sh`

When shutting down, exit the running script and then run `minikube stop` or `minikube delete` (if you'd like to prevent the cluster from retaining its state for the next `minikube start`).