# 클러스터 생성
export PRI_SUBNET1_ID=subnet-0b0e6e20720b77039
export PRI_SUBNET2_ID=subnet-09a7c7c69e57a1345
export CLUSTER_NAME=pri1-cluster
export ACCOUNT_ID=798172178824
export VPC_ID=vpc-0350d2f798d50f7a1
export REGION=ap-northeast-2

eksctl create cluster --vpc-private-subnets $PRI_SUBNET1_ID,$PRI_SUBNET2_ID --name pri-cluster --region ap-northeast-2 --version 1.32 --nodegroup-name pricng --node-type t3.small --nodes 3 --nodes-min 2 --nodes-max 5 --node-private-networking

eksctl create cluster --vpc-private-subnets $PRI_SUBNET1_ID,$PRI_SUBNET2_ID --name pri1-cluster --region ap-northeast-2 --version 1.32 --nodegroup-name pri1cng --node-type t3.small --nodes 3 --nodes-min 2 --nodes-max 5 --node-private-networking

# LB Controller 생성
aws sts get-caller-identity

eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve

eksctl create iamserviceaccount   --cluster=$CLUSTER_NAME   --namespace=kube-system   --name=aws-load-balancer-controller   --role-name AmazonEKSLoadBalancerControllerRole   --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy   --override-existing-serviceaccounts   --approve

kubectl get sa -n kube-system | grep -i load

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
-n kube-system \
--set clusterName=$CLUSTER_NAME \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller \
--set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller \
--set region=ap-northeast-2 \
--set vpcId=$VPC_ID


# Git Clone
git clone https://github.com/BoHyun-Choi-0320/svelte-fast.git

cd svelte-fast/

ls -al

# [ 결과 ]
total 68
drwxr-xr-x 6 root root 4096 May  8 00:33 .
drwxr-xr-x 6 root root 4096 May  8 00:33 ..
-rw-r--r-- 1 root root 3715 May  8 00:33 alembic.ini
-rw-r--r-- 1 root root  587 May  8 00:33 database.py
-rw-r--r-- 1 root root  301 May  8 00:33 Dockerfile
-rw-r--r-- 1 root root   39 May  8 00:33 .dockerignore
drwxr-xr-x 4 root root 4096 May  8 00:33 domain
-rw-r--r-- 1 root root  136 May  8 00:33 entrypoint.sh
-rw-r--r-- 1 root root   96 May  8 00:33 .env
drwxr-xr-x 5 root root 4096 May  8 00:33 frontend # svelte 앱앱
drwxr-xr-x 8 root root 4096 May  8 00:33 .git
-rw-r--r-- 1 root root 3821 May  8 00:33 .gitignore
-rw-r--r-- 1 root root  675 May  8 00:33 main.py
drwxr-xr-x 3 root root 4096 May  8 00:33 migrations
-rw-r--r-- 1 root root  715 May  8 00:33 models.py
-rw-r--r-- 1 root root  221 May  8 00:33 README.md
-rw-r--r-- 1 root root  705 May  8 00:33 requirements.txt
-rw-r--r-- 1 root root    0 May  8 00:33 test


# ECR
aws ecr create-repository --repository-name cdcd-frontend --region ap-northeast-2

aws ecr create-repository --repository-name cdcd-backend --region ap-northeast-2

aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com

export ECR=$ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com


docker build -t backend:1 .
docker tag backend:1 $ECR/cdcd-backend:1
docker push $ECR/cdcd-backend:1

# back.yml
apiVersion: v1
kind: Service
metadata:
  name: svc-back
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8000
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: back-dep
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      name: backend-pod
      labels:
        app: backend
    spec:
      containers:
      - name: backend-con
        image: 798172178824.dkr.ecr.ap-northeast-2.amazonaws.com/cdcd-backend:1

kubectl apply -f backend.yml                                                                          8000/TCP       11m

# frontend의 .env 파일 수정
vi .env 

VITE_SERVER_URL=http://svc-back
# 백엔드의 주소

docker build -t frontend:4 .
docker tag frontend:4 $ECR/cdcd-frontend:4
docker push $ECR/cdcd-frontend:4


# front.yml
apiVersion: v1
kind: Service
metadata:
  name: svc-front
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 5173
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: front-dep
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      name: frontend-pod
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend-con
        image: 798172178824.dkr.ecr.ap-northeast-2.amazonaws.com/cdcd-frontend:3

kubectl apply -f frontend.yml


kubectl create ns argocd

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

eksctl scale nodegroup --cluster pri1-cluster --nodes 5 --nodes-max 7



kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'