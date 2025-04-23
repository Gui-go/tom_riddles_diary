#!/bin/bash

set -o allexport; source .env; set +o allexport

gcloud auth login

gcloud projects create $PROJECT_ID --name=$PROJECT_NAME --labels=owner=guilhermeviegas,environment=dev --enable-cloud-apis
gcloud beta billing projects link $PROJECT_ID --billing-account=$BILLING_ACC
gcloud config set project $PROJECT_ID

# gcloud services enable compute.googleapis.com --project=$PROJECT_ID
gcloud services enable dns.googleapis.com --project=$PROJECT_ID
gcloud services enable iam.googleapis.com --project=$PROJECT_ID
# gcloud services enable cloudresourcemanager.googleapis.com --project=$PROJECT_ID

gcloud projects list
gcloud config get-value project
gcloud config list
gcloud beta billing projects describe $(gcloud config get-value project)


# terraform
terraform init
terraform apply -auto-approve

gcloud auth configure-docker
docker build -t gcr.io/tom-riddle-diary1/streamlit-tom-app -f streamlit.dockerfile .
docker push gcr.io/tom-riddle-diary1/streamlit-tom-app
