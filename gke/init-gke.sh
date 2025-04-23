#!/bin/bash

cd ~/Documents/04-tom_riddles_diary/

set -o allexport; source .env; set +o allexport


gcloud artifacts repositories create tom-riddles-repo \
  --repository-format=docker \
  --location=us \
  --description="Docker repo for tOM Riddles Diary"

gcloud auth configure-docker us-docker.pkg.dev

gcloud artifacts repositories list --location=us

# docker build -t us-docker.pkg.dev/$PROJECT_ID/streamlit-app:latest -f ./app/streamlit.dockerfile ./app
docker build -t us-docker.pkg.dev/$PROJECT_ID/tom-riddles-repo/streamlit-app:latest -f ./app/streamlit.dockerfile ./app

# docker push gcr.io/$PROJECT_ID/streamlit-app:latest
# docker push us-docker.pkg.dev/$PROJECT_ID/tom-riddles-repo/streamlit-app
docker push us-docker.pkg.dev/$PROJECT_ID/tom-riddles-repo/streamlit-app:latest


gcloud container clusters create gke-cluster-trd \
  --machine-type=e2-standard-4 \
  --num-nodes=1 \
  --disk-type=pd-standard \
  --region=$PROJECT_REGION

# gcloud container clusters get-credentials my-gke-cluster \
#     --region=$PROJECT_REGION

kubectl config view


gcloud container clusters get-credentials gke-cluster --region=$PROJECT_REGION














docker build -t streamlit-app:latest -f app/streamlit.dockerfile app/
docker tag streamlit-app:latest guigo13/streamlit-app:latest
docker push guigo13/streamlit-app:latest


















































