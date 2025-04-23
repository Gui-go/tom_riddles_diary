













python3 -m venv venv
source venv/bin/activate
pip install -r app/requirements.txt




sudo docker exec -it ollama-container ollama pull phi:latest
sudo docker compose up --build


systemctl stop ollama




guilhermeviegas1993@gmail.com
---





gcloud projects list
gcloud config set project tom-riddle-diary1



--------------------

gcloud projects get-iam-policy tom-riddle-diary1 --filter="bindings.members:streamlit-ollama-service1-sa@tom-riddle-diary1.iam.gserviceaccount.com"




gcloud projects add-iam-policy-binding tom-riddle-diary1 \
  --member "serviceAccount:streamlit-ollama-service1-sa@tom-riddle-diary1.iam.gserviceaccount.com" \
  --role "roles/artifactregistry.writer"  # Allows pushing images
gcloud projects add-iam-policy-binding tom-riddle-diary1 \
  --member "serviceAccount:streamlit-ollama-service1-sa@tom-riddle-diary1.iam.gserviceaccount.com" \
  --role "roles/run.admin"  # For Cloud Run deployment
gcloud projects add-iam-policy-binding tom-riddle-diary1 \
  --member "serviceAccount:streamlit-ollama-service1-sa@tom-riddle-diary1.iam.gserviceaccount.com" \
  --role "roles/iam.serviceAccountUser"  # To act as service accounts




cd ~/Documents/04-tom_riddles_diary/app
docker build -t us-central1-docker.pkg.dev/tom-riddle-diary1/repo/streamlit:latest -f streamlit.dockerfile .
docker push us-central1-docker.pkg.dev/tom-riddle-diary1/repo/streamlit:latest





