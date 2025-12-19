#!/bin/bash

# Configuration
STACK_NAME="facerec-114"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_PREFIX="facerec-inp-${ACCOUNT_ID}"
IN_BUCKET="${BUCKET_PREFIX}-in"
OUT_BUCKET="${BUCKET_PREFIX}-out"
FUNCTION_NAME="FaceRecFunction"
ROLE_NAME="FaceRecLambdaRole"
POLICY_NAME="FaceRecPolicy"

echo "--- Configuration ---"
echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"
echo "Input Bucket: $IN_BUCKET"
echo "Output Bucket: $OUT_BUCKET"
echo "Function Name: $FUNCTION_NAME"
echo "---------------------"

# 1. Create S3 Buckets
echo "[1/8] Creating S3 Buckets..."
if aws s3 ls "s3://$IN_BUCKET" 2>&1 | grep -q 'NoSuchBucket'; then
  aws s3 mb "s3://$IN_BUCKET" --region "$REGION"
  echo "Created $IN_BUCKET"
else
  echo "Bucket $IN_BUCKET already exists"
fi

if aws s3 ls "s3://$OUT_BUCKET" 2>&1 | grep -q 'NoSuchBucket'; then
  aws s3 mb "s3://$OUT_BUCKET" --region "$REGION"
  echo "Created $OUT_BUCKET"
else
  echo "Bucket $OUT_BUCKET already exists"
fi

# 2. & 3. IAM Role Handling
echo "[2/8] Checking IAM Role..."

if aws iam get-role --role-name "LabRole" >/dev/null 2>&1; then
  echo "Found Admin/LabRole. Using it."
  ROLE_NAME="LabRole"
else
  echo "LabRole not found. Creating $ROLE_NAME..."
  
  TRUST_POLICY='{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

  if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo "Role $ROLE_NAME already exists"
  else
    aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document "$TRUST_POLICY"
    echo "Created role $ROLE_NAME"
  fi

  # Attach Policies only if we created/own the role
  echo "[3/8] Attaching Policies..."
  aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  CUSTOM_POLICY='{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "s3:GetObject",
                  "s3:PutObject",
                  "rekognition:RecognizeCelebrities"
              ],
              "Resource": "*"
          }
      ]
  }'
  aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name "$POLICY_NAME" --policy-document "$CUSTOM_POLICY"
  echo "Attached policies to $ROLE_NAME"
fi


# Wait for role propagation
echo "Waiting for role propagation (10s)..."
sleep 10

# 4. Build and Package
echo "[4/8] Building and Packaging..."
npm install
npm run build

echo "Packaging..."
if [ -d "package_build" ]; then rm -rf package_build; fi
mkdir package_build
cp -r dist/* package_build/
cp package.json package_build/
cd package_build
npm install --production
zip -r ../function.zip .
cd ..
rm -rf package_build

# 5. Create/Update Lambda
echo "[5/8] Deploying Lambda..."
ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)

if aws lambda get-function --function-name "$FUNCTION_NAME" >/dev/null 2>&1; then
  aws lambda update-function-code --function-name "$FUNCTION_NAME" --zip-file fileb://function.zip
  echo "Updated function code"
else
  # Wait loop for role to be assumable
  echo "Waiting for role to be fully ready..."
  sleep 5
  
  aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime "nodejs20.x" \
    --role "$ROLE_ARN" \
    --handler "index.handler" \
    --zip-file fileb://function.zip \
    --timeout 30 \
    --memory-size 128
  echo "Created function $FUNCTION_NAME"
fi

# 6. Configure Permissions
echo "[6/8] Adding S3 Invoke Permission..."
aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id "AllowS3Invoke" \
  --action "lambda:InvokeFunction" \
  --principal s3.amazonaws.com \
  --source-arn "arn:aws:s3:::$IN_BUCKET" \
  --output text 2>/dev/null || echo "Permission probably already exists"

# 7. Configure S3 Notification
echo "[7/8] Configuring S3 Trigger..."
LAMBDA_ARN=$(aws lambda get-function --function-name "$FUNCTION_NAME" --query 'Configuration.FunctionArn' --output text)
NOTIFICATION_CONFIG='{
  "LambdaFunctionConfigurations": [
    {
      "LambdaFunctionArn": "'"$LAMBDA_ARN"'",
      "Events": ["s3:ObjectCreated:*"]
    }
  ]
}'
aws s3api put-bucket-notification-configuration \
  --bucket "$IN_BUCKET" \
  --notification-configuration "$NOTIFICATION_CONFIG"

echo "Success! Deployment complete."
