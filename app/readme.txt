






gcloud auth configure-docker
docker build -t gcr.io/tom-riddle-diary1/streamlit-tom-app -f streamlit.dockerfile .
docker push gcr.io/tom-riddle-diary1/streamlit-tom-app

