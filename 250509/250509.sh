# Jenkins

# NAT GATEWAY 생성 & Routing Table 연결

# 클러스터 생성
export PRI_SUBNET1_ID=subnet-0b0e6e20720b77039
export PRI_SUBNET2_ID=subnet-09a7c7c69e57a1345
export CLUSTER_NAME=pri1-cluster
export ACCOUNT_ID=798172178824
export VPC_ID=vpc-0350d2f798d50f7a1
export REGION=ap-northeast-2

eksctl create cluster --vpc-private-subnets $PRI_SUBNET1_ID,$PRI_SUBNET2_ID --name pri-cluster --region ap-northeast-2 --version 1.32 --nodegroup-name pricng --node-type t3.small --nodes 3 --nodes-min 2 --nodes-max 5 --node-private-networking

# LB Controller
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


