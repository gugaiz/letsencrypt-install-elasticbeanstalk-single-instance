#!/usr/bin/env bash
set -e
# Loadvars
. /opt/elasticbeanstalk/support/envvars

# Check if there is certificate on S3 that we can use

ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
REGION=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}')

echo $ACCOUNT_ID
echo $REGION

URL="s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/ssl.conf"

echo 'copying certificate'

# Copy cert to S3 regardless of outcome

aws s3 cp /etc/letsencrypt/live/ebcert/privkey.pem s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/privkey.pem
aws s3 cp /etc/letsencrypt/live/ebcert/fullchain.pem s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/fullchain.pem

