#!/bin/sh

set -e

if [ -z "$AWS_S3_BUCKET" ]; then
  echo "AWS_S3_BUCKET is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "AWS_ACCESS_KEY_ID is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "AWS_SECRET_ACCESS_KEY is not set. Quitting."
  exit 1
fi

if [ -z "$AWS_LAMBDA_NAME" ]; then
  echo "AWS_LAMBDA_NAME is not set. Quitting."
  exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "GITHUB_TOKEN is not set. Quitting."
  exit 1
fi


# Default to us-west-2 if AWS_REGION not set.
if [ -z "$AWS_REGION" ]; then
  AWS_REGION="us-west-2"
fi

# Override default AWS endpoint if user sets AWS_S3_ENDPOINT.
if [ -n "$AWS_S3_ENDPOINT" ]; then
  ENDPOINT_APPEND="--endpoint-url $AWS_S3_ENDPOINT"
fi

# Create a dedicated profile for this action to avoid conflicts
# with past/future actions.
# https://github.com/jakejarvis/s3-sync-action/issues/1
aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

sh -c "echo '=== Uploading Artifacts to S3 ==='"
# Sync using our dedicated profile and suppress verbose messages.
# All other flags are optional via the `args:` directive.
sh -c "aws s3 sync ${SOURCE_DIR:-.} s3://${AWS_S3_BUCKET}/${DEST_DIR} \
              --profile s3-sync-action \
              --no-progress \
              ${ENDPOINT_APPEND} --exclude '.git/*' --delete"

sh -c "echo '=== Running Analysis ==='"

aws lambda invoke --profile s3-sync-action --function-name "${AWS_LAMBDA_NAME}" "${SOURCE_DIR}/response.json"

if [[ $(wc -w < ${SOURCE_DIR}/response.json) -le 2 ]]; then 
  echo "*** DG completed without findings ***"
  ./comment.sh "*** DG completed without findings ***" true
  exit 0; 
else 
  echo "*** DG found an issue in the code. See raw output below ***"
  cat "${SOURCE_DIR}/response.json" | xargs printf '%b\n'
  ./comment.sh $(cat "${SOURCE_DIR}/response.json") true
  exit 1; 
fi

# Clear out credentials after we're done.
# We need to re-run `aws configure` with bogus input instead of
# deleting ~/.aws in case there are other credentials living there.
# https://forums.aws.amazon.com/thread.jspa?threadID=148833
aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
null
null
null
text
EOF
