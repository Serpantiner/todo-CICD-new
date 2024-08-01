#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <environment> <image_tag>"
    exit 1
fi

ENVIRONMENT=$1
IMAGE_TAG=$2

# Set the namespace and hostname based on the environment
if [ "$ENVIRONMENT" == "prod" ]; then
    NAMESPACE="todo-prod"
    HOSTNAME="todo-prod.local"
elif [ "$ENVIRONMENT" == "dev" ]; then
    NAMESPACE="todo-dev"
    HOSTNAME="todo-dev.local"
else
    echo "Invalid environment. Use 'prod' or 'dev'."
    exit 1
fi

# Ensure the namespace exists
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply the database deployment
kubectl apply -f todo-db-deployment.yaml -n $NAMESPACE

# Apply the todo app deployment
sed -e "s|\${DOCKERHUB_USERNAME}|$DOCKERHUB_USERNAME|g" \
    -e "s|\${IMAGE_TAG}|$IMAGE_TAG|g" \
    todo-deployment.yaml | kubectl apply -f - -n $NAMESPACE

# Apply the ingress with the correct hostname
sed "s/\${HOSTNAME}/$HOSTNAME/" ingress.yaml | kubectl apply -f - -n $NAMESPACE

# Wait for the deployment to be ready
kubectl rollout status deployment/todo-app -n $NAMESPACE

echo "Deployment to $ENVIRONMENT environment completed."
echo "Application should be accessible at http://$HOSTNAME"

# Optional: Display the Minikube IP if running locally
if command -v minikube &> /dev/null; then
    MINIKUBE_IP=$(minikube ip)
    echo "Minikube IP: $MINIKUBE_IP"
    echo "Don't forget to add the following to your /etc/hosts file:"
    echo "$MINIKUBE_IP $HOSTNAME"
fi