# Linux
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start
minikube start

# Verify
kubectl get nodes

####################################
## Install steps for linux

# Step 1 — Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    kubectl version --client

# Step 2 — Install Minikube
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    minikube version

# Step 3 — Install Docker (Minikube needs a driver)
    # Update packages
    sudo apt-get update

    # Install Docker
    sudo apt-get install -y docker.io

    # Start Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # Add your user to docker group (so minikube can use it without sudo)
    sudo usermod -aG docker $USER

    # IMPORTANT — apply group change
    newgrp docker

    # Verify
    docker ps

# Step 4 — Start Minikube
    minikube start --driver=docker
        # You'll see something like:
            * minikube v1.33.0 on Ubuntu
            * Using the docker driver based on user configuration
            * Starting control plane node minikube in cluster minikube
            * Pulling base image ...
            * Preparing Kubernetes v1.30.0 on Docker 26.0.0 ...
            * Done! kubectl is now configured to use "minikube" cluster

Step 5 — Verify everything works
    # Check node
    kubectl get nodes

    # Should show:
    # NAME       STATUS   ROLES           AGE   VERSION
    # minikube   Ready    control-plane   1m    v1.30.x

    # Check cluster info
    kubectl cluster-info

Step 6 — Useful Minikube commands to know
    minikube start        # start the cluster
    minikube stop         # stop (saves state)
    minikube status       # check if running
    minikube delete       # delete cluster completely
    minikube dashboard    # open K8s web UI in browser

# One thing different from killercoda on local
    ==> On killercoda, NodePort was accessible directly. On Minikube for NodePort/Ingress access you use:
        # Access a service by name
        minikube service SERVICE-NAME

        # Get minikube IP
        minikube ip


# step 1 to step 5 output
    kubectl version --client
    Client Version: v1.35.4
    Kustomize Version: v5.7.1
    siva@yottta:~$ minikube version
    minikube version: v1.38.1
    commit: c93a4cb9311efc66b90d33ea03f75f2c4120e9b0
    siva@yottta:~$ docker ps
    CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
    siva@yottta:~$ minikube start --driver=docker
    😄  minikube v1.38.1 on Ubuntu 22.04
    ✨  Using the docker driver based on existing profile
    👍  Starting "minikube" primary control-plane node in "minikube" cluster
    🚜  Pulling base image v0.0.50 ...
    🔄  Restarting existing docker container for "minikube" ...
    🐳  Preparing Kubernetes v1.35.1 on Docker 29.2.1 ...
    🔎  Verifying Kubernetes components...
        ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
    🌟  Enabled addons: storage-provisioner, default-storageclass
    🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
    siva@yottta:~$ kubectl get nodes
    NAME       STATUS   ROLES           AGE   VERSION
    minikube   Ready    control-plane   29d   v1.35.1
    siva@yottta:~$ kubectl cluster-info
    Kubernetes control plane is running at https://192.168.49.2:8443
    CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.


## Mini-project start
# Step 1 — Create project folder
    mkdir k8s-project && cd k8s-project

# Step 2 — Namespace
cat > 1-namespace.yaml << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
EOF

kubectl apply -f 1-namespace.yaml
kubectl get namespaces | grep myapp

# Step 3 — ConfigMap
cat > 2-configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: myapp
data:
  APP_NAME: "MyKubernetesApp"
  APP_ENV: "production"
  APP_VERSION: "1.0.0"
  DB_HOST: "mysql-service.myapp.svc.cluster.local"
  LOG_LEVEL: "info"
EOF

kubectl apply -f 2-configmap.yaml
kubectl get configmap -n myapp

# Step 4 — Secret
# Encode values first — see base64 output
echo -n "admin" | base64
echo -n "supersecret123" | base64

cat > 3-secret.yaml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
  namespace: myapp
type: Opaque
data:
  DB_USER: YWRtaW4=
  DB_PASSWORD: c3VwZXJzZWNyZXQxMjM=
EOF

kubectl apply -f 3-secret.yaml
kubectl get secrets -n myapp

# Step 5 — Deployment
cat > 4-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  namespace: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: APP_NAME
          valueFrom:
            configMapKeyRef:
              name: myapp-config
              key: APP_NAME
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: myapp-config
              key: APP_ENV
        - name: APP_VERSION
          valueFrom:
            configMapKeyRef:
              name: myapp-config
              key: APP_VERSION
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: myapp-config
              key: DB_HOST
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: myapp-config
              key: LOG_LEVEL
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: myapp-secret
              key: DB_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: myapp-secret
              key: DB_PASSWORD
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            cpu: "100m"
            memory: "64Mi"
          limits:
            cpu: "200m"
            memory: "128Mi"
EOF

kubectl apply -f 4-deployment.yaml
kubectl get pods -n myapp -w

# Step 6 — Service
cat > 5-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
  namespace: myapp
spec:
  type: NodePort
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF

kubectl apply -f 5-service.yaml
kubectl get service -n myapp

# Step 7 — Access the app in browser
minikube service myapp-service -n myapp # This opens the app in your browser automatically!

# OR get the URL manually:
minikube ip
# Then open: http://MINIKUBE-IP:30080

# Step 8 — Verify everything end to end
# See all resources in myapp namespace
kubectl get all -n myapp

# Verify ConfigMap + Secret injected into a pod
kubectl exec -it -n myapp \
  $(kubectl get pod -n myapp -l app=myapp -o jsonpath='{.items[0].metadata.name}') \
  -- env | grep -E "APP_NAME|APP_ENV|DB_HOST|DB_USER|DB_PASSWORD"

######### command ########
# Verification 1 — Go inside a pod (with correct namespace flag)
kubectl exec -it myapp-deployment-77dd579b85-7k5mg -n myapp -- bash
root@myapp-deployment-77dd579b85-7k5mg:/# ls
bin  boot  dev  docker-entrypoint.d  docker-entrypoint.sh  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
root@myapp-deployment-77dd579b85-7k5mg:/# echo $DB_PASSWORD
supersecret123
root@myapp-deployment-77dd579b85-7k5mg:/# curl localhost:80
<!DOCTYPE html>
<html>
<head>

# Verification 2 — Prove self-healing (delete a pod and watch it come back)
# Delete one pod
kubectl delete pod myapp-deployment-77dd579b85-7k5mg -n myapp

# Watch immediately — Deployment auto-creates replacement
kubectl get pods -n myapp -w

# Verification 3 — Update ConfigMap and rolling restart
# Update APP_VERSION in ConfigMap
kubectl patch configmap myapp-config -n myapp \
  --patch '{"data":{"APP_VERSION":"2.0.0"}}'

# Restart deployment to pick up new config
kubectl rollout restart deployment/myapp-deployment -n myapp

# Watch rolling update happen
kubectl get pods -n myapp -w

==> Then verify new version is picked up:
kubectl exec -it -n myapp \
  $(kubectl get pod -n myapp -l app=myapp -o jsonpath='{.items[0].metadata.name}') \
  -- env | grep APP_VERSION



##########

Question 1 — Check each pod IP and test directly
# See IP of every pod
kubectl get pods -n myapp -o wide
# sample-output
NAME                                READY   STATUS    IP
myapp-deployment-66b58c7c5d-2fzwn   1/1     Running   172.17.0.5
myapp-deployment-66b58c7c5d-rjght   1/1     Running   172.17.0.6
myapp-deployment-66b58c7c5d-rrk5r   1/1     Running   172.17.0.7

Option 1 — Jump inside a pod and curl other pod IPs
bash# Go inside pod 1
kubectl exec -it myapp-deployment-66b58c7c5d-2fzwn -n myapp -- bash
Now inside the pod, curl the OTHER pods directly by IP:
bash# Curl pod 2 directly by IP
curl 10.244.0.11:80

# Curl pod 3 directly by IP
curl 10.244.0.10:80

# Curl the Service by ClusterIP (load balanced)
curl 10.100.126.189:80

# Curl the Service by DNS name (how microservices talk!)
curl myapp-service.myapp.svc.cluster.local:80

exit

Option 2 — Use minikube ssh (access Minikube VM directly)
bash# SSH into minikube node
minikube ssh

# Now curl any pod IP directly
curl 10.244.0.12:80
curl 10.244.0.11:80
curl 10.244.0.10:80

# Exit minikube ssh
exit


# Or test via Service (load balanced — hits random pod each time):
curl 10.100.126.189:80    # your ClusterIP

# Pod IPs only work from inside the Minikube network. If curl doesn't work from your terminal, run it from inside a pod:
# Jump into a pod and curl another pod's IP directly
kubectl exec -it myapp-deployment-66b58c7c5d-2fzwn -n myapp -- bash

# Inside pod — curl another pod by IP
curl 172.17.0.6:80

# Curl the Service by name
curl myapp-service.myapp.svc.cluster.local:80

# Exit
exit


#####3
# Question 2 — Can you create another project without deleting this one?
Yes! 100%. Just use a different namespace. Both projects run in the same cluster simultaneously — fully isolated.

# See both namespaces running together
kubectl get all -n myapp
kubectl get all -n myapp2

# Or see everything at once
kubectl get all --all-namespaces


### Cleanup when done
# Delete everything in one command
kubectl delete namespace myapp

# Verify — all resources gone
kubectl get all -n myapp


Laptop/User
   |
   | Access NodeIP:30080
   v
Kubernetes Node (NodePort)
   |
   v
Service object
   |
   | Service Port: 80
   v
Pod IP
   |
   | targetPort: 80
   v
Nginx container listening on :80