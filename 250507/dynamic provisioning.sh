export CLUSTER_NAME=pri-cluster
export ACCOUNT_ID=798172178824
export VPC_ID=vpc-0350d2f798d50f7a1
export REGION=ap-northeast-2
export ROLE_NAME=AmazonEKS_EFS_CSI_DriverRole

eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve

eksctl create iamserviceaccount \
    --name efs-csi-controller-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --role-name $ROLE_NAME \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy \
    --approve
2025-05-07 02:32:57 [ℹ]  1 iamserviceaccount (kube-system/efs-csi-controller-sa) was included (based on the include/exclude rules)
2025-05-07 02:32:57 [!]  serviceaccounts in Kubernetes will not be created or modified, since the option --role-only is used
2025-05-07 02:32:57 [ℹ]  1 task: { create IAM role for serviceaccount "kube-system/efs-csi-controller-sa" }
2025-05-07 02:32:57 [ℹ]  building iamserviceaccount stack "eksctl-pri-cluster-addon-iamserviceaccount-kube-system-efs-csi-controller-sa"
2025-05-07 02:32:57 [ℹ]  deploying stack "eksctl-pri-cluster-addon-iamserviceaccount-kube-system-efs-csi-controller-sa"
2025-05-07 02:32:57 [ℹ]  waiting for CloudFormation stack "eksctl-pri-cluster-addon-iamserviceaccount-kube-system-efs-csi-controller-sa"
2025-05-07 02:33:28 [ℹ]  waiting for CloudFormation stack "eksctl-pri-cluster-addon-iamserviceaccount-kube-system-efs-csi-controller-sa"

TRUST_POLICY=$(aws iam get-role --role-name $ROLE_NAME --output json --query 'Role.AssumeRolePolicyDocument' |     sed -e 's/efs-csi-controller-sa/efs-csi-*/' -e 's/StringEquals/StringLike/')

eksctl create addon --cluster $CLUSTER_NAME --name  aws-efs-csi-driver --version latest \
    --service-account-role-arn arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME --force

vi sc.yml

kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-0539f21700c9368cf
  directoryPerms: "700"

