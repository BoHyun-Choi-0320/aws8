# 1. RDS 생성

# 2. 클러스터 생성
export PRI_SUBNET1_ID=subnet-0b0e6e20720b77039
export PRI_SUBNET2_ID=subnet-09a7c7c69e57a1345
eksctl create cluster --vpc-private-subnets $PRI_SUBNET1_ID,$PRI_SUBNET2_ID --name rapa-cluster --region ap-northeast-2 --version 1.32 --nodegroup-name rapacng --node-type t3.small --nodes 1 --nodes-min 1 --nodes-max 3 --node-private-networking

root@aws-cli:~/mani/exam/was# export PRI_SUBNET1_ID=subnet-0b0e6e20720b77039
root@aws-cli:~/mani/exam/was# export PRI_SUBNET2_ID=subnet-09a7c7c69e57a1345
root@aws-cli:~/mani/exam/was# eksctl create cluster --vpc-private-subnets $PRI_SUBNET1_ID,$PRI_SUBNET2_ID --name rapa-cluster --region ap-northeast-2 --version 1.32 --nodegroup-name rapacng --node-type t3.small --nodes 1 --nodes-min 1 --nodes-max 3 --node-private-networking
2025-05-02 00:50:04 [ℹ]  eksctl version 0.207.0
2025-05-02 00:50:04 [ℹ]  using region ap-northeast-2
2025-05-02 00:50:05 [✔]  using existing VPC (vpc-0350d2f798d50f7a1) and subnets (private:map[ap-northeast-2a:{subnet-0b0e6e20720b77039 ap-northeast-2a 10.20.2.0/24 0 } ap-northeast-2c:{subnet-09a7c7c69e57a1345 ap-northeast-2c 10.20.12.0/24 0 }] public:map[])

# 4. LB Controller 설치
aws sts get-caller-identity

export ACCOUNT_ID=798172178824
export VPC_ID=vpc-0350d2f798d50f7a1
export REGION=ap-northeast-2
export CLUSTER_NAME=rapa-cluster

root@aws-cli:~# eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve
2025-05-02 01:08:11 [ℹ]  will create IAM Open ID Connect provider for cluster "rapa-cluster" in "ap-northeast-2"
2025-05-02 01:08:12 [✔]  created IAM Open ID Connect provider for cluster "rapa-cluster" in "ap-northeast-2"

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

# 3. ECR 이미지 업로드
# [was]
root@aws-cli:~/mani/exam/was# aws ecr create-repository --repository-name was-tomcat-alb --region ap-northeast-2
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:ap-northeast-2:798172178824:repository/was-tomcat-alb",
        "registryId": "798172178824",
        "repositoryName": "was-tomcat-alb",
        "repositoryUri": "798172178824.dkr.ecr.ap-northeast-2.amazonaws.com/was-tomcat-alb",
        "createdAt": "2025-05-02T00:41:13.344000+00:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
root@aws-cli:~/mani/exam/was# aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 798172178824.dkr.ecr.ap-northeast-2.amazonaws.com


WARNING! Your credentials are stored unencrypted in '/root/.docker/config.json'.
Configure a credential helper to remove this warning. See
https://docs.docker.com/go/credential-store/

Login Succeeded

root@aws-cli:~/mani/exam/was# export ECR=798172178824.dkr.ecr.ap-northeast-2.amazonaws.com

docker build -t was-tomcat-alb:3 .
docker tag was-tomcat-alb:3 $ECR/was-tomcat-alb:2
docker push $ECR/was-tomcat-alb:2

kubectl create deploy was --image=798172178824.dkr.ecr.ap-northeast-2.amazonaws.com/was-tomcat-alb:2 --replicas=1
kubectl expose deploy was --target-port 8080 --port 8080

root@aws-cli:~/mani/exam/was# vi was-ingress.yml 

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: "was-ingress"
  labels:
    app.kubernetes.io/name: "was-ingress"
  annotations:
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip

spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - pathType: Prefix
            path: /
            backend:
              service:
                name: was
                port:
                  number: 8080

root@aws-cli:~/mani/exam/was# kubectl apply -f was-ingress.yml 
ingress.networking.k8s.io/was-ingress created

# [web]

aws ecr create-repository --repository-name web-apache-alb --region ap-northeast-2

docker build -t web-apache-alb:4 .
docker tag web-apache-alb:4 $ECR/web-apache-alb:4
docker push $ECR/web-apache-alb:4

kubectl create deploy web --image=798172178824.dkr.ecr.ap-northeast-2.amazonaws.com/web-apache-alb:4 --replicas=1
kubectl expose deploy web --target-port 80 --port 80

vi web-ingress.yml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: "web-ingress"
  labels:
    app.kubernetes.io/name: "web-ingress"
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip

spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - pathType: Prefix
            path: /
            backend:
              service:
                name: web
                port:
                  number: 80
            path: /h
            backend:
              service:
                name: hnginx
                port:
                  number: 80
            path: /ip
            backend:
              service:
                name: ipnginx
                port:
                  number: 80

# 사설 레지스트리 보안 허용
vi /etc/docker/daemon.json

# [ipnginx]

vi Dockerfile 

FROM 61.254.18.30:5000/ipnginx

# ECR Repository 생성
aws ecr create-repository --repository-name ipnginx --region ap-northeast-2

docker build -t ipnginx:1 .
docker tag ipnginx:1 $ECR/ipnginx:1
docker push $ECR/ipnginx:1

kubectl create deploy ipnginx --image=798172178824.dkr.ecr.ap-northeast-2.amazonaws.com/ipnginx:1 --replicas=1
kubectl expose deploy ipnginx --target-port 80 --port 80

# [hnginx]
root@aws-cli:~/mani/exam/hnginx# vi Dockerfile

FROM 61.254.18.30:5000/hnginx

# ECR Repository 생성
aws ecr create-repository --repository-name hnginx --region ap-northeast-2

docker build -t hnginx:1 .
docker tag hnginx:1 $ECR/hnginx:1
docker push $ECR/hnginx:1

kubectl create deploy hnginx --image=798172178824.dkr.ecr.ap-northeast-2.amazonaws.com/hnginx:1 --replicas=1
kubectl expose deploy hnginx --target-port 80 --port 80

aws eks update-nodegroup-config \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name rapacng \
  --scaling-config minSize=1,maxSize=5,desiredSize=3
