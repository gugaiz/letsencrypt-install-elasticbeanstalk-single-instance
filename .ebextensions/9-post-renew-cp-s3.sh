#!/usr/bin/env bash
set -e
# Loadvars
. /opt/elasticbeanstalk/support/envvars

# Check if there is certificate on S3 that we can use

ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
REGION=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}')

echo $ACCOUNT_ID
echo $REGION

echo 'copying certificate'

# Copy cert to S3 regardless of outcome

aws s3 cp  --recursive  /etc/letsencrypt/live/ebcert/ s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/certs
aws s3 cp  --recursive  /etc/letsencrypt/renewal/ s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/renewal
aws s3 cp  --recursive  /etc/letsencrypt/accounts/ s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/accounts


