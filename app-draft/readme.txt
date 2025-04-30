






gcloud auth configure-docker
docker build -t gcr.io/tom-riddle-diary1/streamlit-tom-app -f streamlit.dockerfile .
docker push gcr.io/tom-riddle-diary1/streamlit-tom-app





docker build -t us-central1-docker.pkg.dev/tom-riddle-diary1/repo/streamlit-draft:latest -f streamlit-draft.dockerfile .
gcloud auth configure-docker us-central1-docker.pkg.dev
docker push us-central1-docker.pkg.dev/tom-riddle-diary1/repo/streamlit-draft:latest



