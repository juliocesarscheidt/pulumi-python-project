# Pulumi AWS Python Project

Trying out Pulumi with Python to deploy resources on AWS

> Build the image locally or pull from docker hub

```bash
# build pulumi python image
docker image build \
  --tag juliocesarmidia/pulumi-aws-python:v1.0.0 \
  -f Pulumi.Dockerfile .

# pulling from docker hub
docker image pull juliocesarmidia/pulumi-aws-python:v1.0.0
```

> Running the pulumi python container

```bash
# aws credentials to inject into container
export AWS_ACCESS_KEY_ID='AWS_ACCESS_KEY_ID'
export AWS_SECRET_ACCESS_KEY='AWS_SECRET_ACCESS_KEY'
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-'us-east-1'}

docker volume create py-venv-modules

docker container run --rm -it \
  --name pulumi-aws-python \
  -v $PWD/:/usr/src/app \
  -v py-venv-modules:/usr/src/app/venv \
  --env AWS_ACCESS_KEY_ID \
  --env AWS_SECRET_ACCESS_KEY \
  --env AWS_DEFAULT_REGION \
  juliocesarmidia/pulumi-aws-python:v1.0.0
```

> Running commands inside the container to provision the stack

```bash
# login local (not recommended)
pulumi login --local

# check aws identity
aws sts get-caller-identity

# or create a S3 bucket to login remote
export BACKEND_BUCKET="pulumi-backend-bucket-$AWS_DEFAULT_REGION"
aws s3api create-bucket \
  --bucket $BACKEND_BUCKET \
  --region $AWS_DEFAULT_REGION --acl private

# login remote with bucket
pulumi login s3://$BACKEND_BUCKET

# check local files for pulumi
ls -lth /home/pulumi/.pulumi/
cat /home/pulumi/.pulumi/credentials.json

# stack name used by pulumi
export STACK='s3-custom-bucket'
# passphrase to encrypt the stack
export PULUMI_CONFIG_PASSPHRASE="SOME_PASSPHRASE"
# bucket name to be created
export BUCKET_NAME="s3-bucket-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | tr '[:upper:]' '[:lower:]' | head -n 1)"
echo $BUCKET_NAME

# starting the stack and configs
pulumi stack init $STACK
pulumi config set aws:region $AWS_DEFAULT_REGION --stack $STACK
pulumi config set s3-custom-bucket:data '{"active": "true", "bucket_name": "'$BUCKET_NAME'"}' --stack $STACK

# deploying the stack
pulumi up --stack $STACK --show-config --yes

# list backend files
aws s3 ls s3://$BACKEND_BUCKET/.pulumi/

# updating stack
pulumi update

# show logs
pulumi logs -f

pulumi stack output
pulumi stack output bucket_id

# list newly created bucket
aws s3 ls $(pulumi stack output bucket_id)

# destroying / cleanup
pulumi destroy --yes
pulumi stack rm s3-custom-bucket --yes

docker volume rm -f py-venv-modules
docker container rm -f pulumi-aws-python
```
