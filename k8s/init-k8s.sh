






docker build -t streamlit-app:latest -f app/streamlit.dockerfile app/
docker tag streamlit-app:latest guigo13/streamlit-app:latest
docker push guigo13/streamlit-app:latest



# minikube start --driver=docker --memory=8192 --cpus=4
minikube start --memory=8192 --cpus=4
minikube profile list

kubectl get nodes

# docker build -t streamlit-app:latest -f app/streamlit.dockerfile app/
# minikube image load streamlit-app:latest
# minikube image load streamlit-app:latest
# eval $(minikube docker-env)
# docker build -t streamlit-app:latest -f app/streamlit.dockerfile app/
# eval $(minikube docker-env -u)


docker images | grep streamlit-app

kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/llmodel.yaml
kubectl apply -f k8s/app.yaml

kubectl get pods

kubectl logs -l app=llmodel
kubectl logs -l app=streamlit

kubectl describe pod -l app=llmodel
kubectl describe pod -l app=streamlit

kubectl get svc

# kubectl describe pod app-5c9cc758dc-t22kx

minikube ip
# kubectl port-forward svc/app-service 8501:8501

# minikube stop
# minikube start
# minikube delete

kubectl top pods

# kubectl delete -f k8s/
# minikube stop
# minikube delete

# docker rmi streamlit-app-k8s:latest




# Troubleshooting:
# kubectl logs <pod-name>
# kubectl describe pod <pod-name>

# minikube ssh

# -----------------------


minikube start --memory=8192 --cpus=4

eval $(minikube docker-env)
docker build -t app-image:latest -f ./app/streamlit.dockerfile ./app

kubectl apply -f ollama-deployment.yaml
kubectl apply -f app-deployment.yaml

minikube service streamlit-service

kubectl get pods
kubectl describe pod streamlit-app-64ff8d7558-pkbmq

--

docker build -t streamlit-app -f ./app/streamlit.dockerfile ./app