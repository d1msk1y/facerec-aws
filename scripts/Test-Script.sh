#!/bin/bash

# Configuration
STACK_NAME="facerec-114"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_PREFIX="facerec-inp-${ACCOUNT_ID}"
IN_BUCKET="${BUCKET_PREFIX}-in"
OUT_BUCKET="${BUCKET_PREFIX}-out"
TEST_IMAGE="test_image.jpg"

echo "--- Test Configuration ---"
echo "Input Bucket: $IN_BUCKET"
echo "Output Bucket: $OUT_BUCKET"
echo "test Image: $TEST_IMAGE"
echo "--------------------------"

# 0. Check if image exists
if [ ! -f "$TEST_IMAGE" ]; then
    echo "Error: $TEST_IMAGE not found. Downloading a sample..."
    echo "Please provide a 'test_image.jpg' in the current directory."
    exit 1
fi

# 1. Upload Image
echo "Uploading $TEST_IMAGE to $IN_BUCKET..."
aws s3 cp "$TEST_IMAGE" "s3://$IN_BUCKET/$TEST_IMAGE"

# 2. Wait
echo "Waiting 10 seconds for Lambda processing..."
sleep 10

# 3. Check Result
RESULT_KEY="${TEST_IMAGE%.*}.json"
echo "Checking for $RESULT_KEY in $OUT_BUCKET..."

if aws s3 ls "s3://$OUT_BUCKET/$RESULT_KEY"; then
    echo "Result found! Downloading..."
    aws s3 cp "s3://$OUT_BUCKET/$RESULT_KEY" result.json
    echo "--- Result Content ---"
    cat result.json
    echo ""
    echo "----------------------"
    
    # Extract Name and Confidence using grep/sed (since jq might not be available)
    NAME=$(grep -o '"Name":"[^"]*"' result.json | cut -d'"' -f4)
    CONFIDENCE=$(grep -o '"MatchConfidence":[^,}]*' result.json | cut -d':' -f2)

    echo "Detected: $NAME (Confidence: $CONFIDENCE%)"
    echo " Test Passed."
else
    echo "Error: Result file not found in output bucket."
    echo "Check Lambda CloudWatch logs for details."
    exit 1
fi
