# 내 계정 정보 확인
root@aws-cli:~# aws sts get-caller-identity
{
    "UserId": "AIDA3TVWE5GECY2GHCHMZ",
    "Account": "798172178824",
    "Arn": "arn:aws:iam::798172178824:user/aws8"
}

# 환경변수 설정
root@aws-cli:~# export CLUSTER_NAME=rapa-cluster
root@aws-cli:~# export ACCOUNT_ID=798172178824
root@aws-cli:~# export VPC_ID=vpc-0350d2f798d50f7a1
root@aws-cli:~# export REGION=ap-northeast-2

# OIDC 활성화
root@aws-cli:~# eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve

# AWS의 Role - IRSA 생성
root@aws-cli:~# eksctl create iamserviceaccount   --cluster=$CLUSTER_NAME   --namespace=kube-system   --name=aws-load-balancer-controller   --role-name AmazonEKSLoadBalancerControllerRole   --attach-policy-arn=arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy   --override-existing-serviceaccounts   --approve

