# argo:1 Dockerfile

vi Dockerfile

FROM nginx:latest
WORKDIR /usr/share/nginx/html
RUN echo 'CD is difficult:(' > index.html

# ECR 레포지토리 생성
aws ecr create-repository --repository-name argo --region ap-northeast-2

aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com

export ECR=$ACCOUNT_ID.dkr.ecr.ap-northeast-2.amazonaws.com


# 이미지 빌드 & push
docker build -t argo:1 .
docker tag argo:1 $ECR/argo:1
docker push $ECR/argo:1

# argo:2 Dockerfile

vi Dockerfile 

FROM nginx:latest
WORKDIR /usr/share/nginx/html
RUN echo 'CD is Easy:)' > index.html


# 이미지 빌드 & push
docker build -t argo:2 .
docker tag argo:2 $ECR/argo:2a
docker push $ECR/argo:2




