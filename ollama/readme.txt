






gcloud auth configure-docker
docker build -t gcr.io/tom-riddle-diary1/ollama -f ollama.dockerfile .
docker push gcr.io/tom-riddle-diary1/ollama



docker build -t myollama -f ollama.dockerfile .
docker run -p 8080:8080 myollama
docker push myollama




