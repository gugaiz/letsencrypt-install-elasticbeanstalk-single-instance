#!/usr/bin/env bash
# Bash script to install lets encrypt SSL certificate as a POST HOOK
# For use with Single instance PHP Elastic Beanstalk
set -e
# Loadvars
. /opt/elasticbeanstalk/support/envvars

# Check if there is certificate on S3 that we can use

ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
REGION=$(curl http://169.254.169.254/latest/dynamic/instance-identity/document|grep region|awk -F\" '{print $4}')

echo $ACCOUNT_ID
echo $REGION
echo "bonjour"

URL="s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/privkey.pem"

count=$(aws s3 ls $URL | wc -l)
if [ $count -gt 0 ]
then
  echo "SSL Already Exists on S3"
  # Copy from S3 bucket

  if [ ! -f /etc/letsencrypt/live/ebcert/privkey.pem ] ; then

    echo "copying from bucket"
    aws s3 cp s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/privkey.pem /etc/letsencrypt/live/${LE_SSL_DOMAIN}/privkey.pem
    aws s3 cp s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/fullchain.pem /etc/letsencrypt/live/${LE_SSL_DOMAIN}/fullchain.pem

    ln -snf /etc/letsencrypt/live/${LE_SSL_DOMAIN} /etc/letsencrypt/live/ebcert

    # restart
    sudo cp /opt/passenger-standalone.json /var/app/current/
    sudo service passenger restart
  fi
else
  echo "does not exist on s3 - $URL"
fi

# Install if no SSL certificate installed or SSL install on deploy is true

if [[ ("$LE_INSTALL_SSL_ON_DEPLOY" = true) || (! -f /etc/letsencrypt/live/ebcert/privkey.pem) ]] ; then

  SECONDS=0

  # Wait until domain is resolving to ec2 instance
  echo "Pinging $LE_SSL_DOMAIN until online..."
  while ! timeout 0.2 ping -c 1 -n $LE_SSL_DOMAIN &> /dev/null
  do
    SECONDS=$[$SECONDS +1]
    if [ $SECONDS -gt 30 ]
    then
      echo "$SECONDS seconds timeout waiting to ping, lets exit";
      exit 1;
    fi
  done
  echo "Pinging $LE_SSL_DOMAIN successful"
  
  echo "installing the certificate"
  # Install certbot
  sudo mkdir -p /certbot
  cd /certbot || exit
  sudo wget https://dl.eff.org/certbot-auto && sudo chmod a+x certbot-auto

  # Create certificate and authenticate
  sudo ./certbot-auto certonly --debug --non-interactive --email ${LE_EMAIL} --agree-tos --standalone -d ${LE_SSL_DOMAIN} -d www.${LE_SSL_DOMAIN} --keep-until-expiring --pre-hook "service passenger stop" --post-hook "service passenger start"

  ln -snf /etc/letsencrypt/live/${LE_SSL_DOMAIN} /etc/letsencrypt/live/ebcert

  # Install crontab
  sudo crontab /tmp/cronjob
  echo 'copying certificate to S3'

  aws s3 cp /etc/letsencrypt/live/${LE_SSL_DOMAIN}/privkey.pem s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/privkey.pem
  aws s3 cp /etc/letsencrypt/live/${LE_SSL_DOMAIN}/fullchain.pem s3://elasticbeanstalk-$REGION-$ACCOUNT_ID/ssl/$LE_SSL_DOMAIN/fullchain.pem
fi

