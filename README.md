# letsencrypt-install-elasticbeanstalk-single-instance
.ebextensions script for automatically installing letsencrypt SSL on an Elastic Beanstalk single instance running Ruby + Passenger

# Instructions

1. The domain you wish to use must already have an A record pointing to the Elastic IP of your single instance, or by adding an alias record within Amazon Route 53 to your elastic beanstalk address. As long as the site is resolving on the domain you wish to use, you're good.

2. Copy the contents of .ebextensions folder to your project .ebextensions folder

3. Create the env variables under Configuration - > Software, there create these 3 variables:
- LE_EMAIL (let's encrypt email for notifications)
- LE_INSTALL_SSL_ON_DEPLOY (force to fetch the cert -true or false-)
- LE_SSL_DOMAIN (domain for the app without www)

4. Running `eb deploy` will: 
- If SSL certificate is already installed does nothing.
- Checks to see if the SSL certificate already exists on the S3 bucket used for storing applications. If it does, it downloads and installs from S3.
- Check to see if /etc/letsencrypt/live/ebcert/privkey.pem exists already and if not, attempts to install certificate
- Allow incoming traffic on port 443
- Allow pinging to the server
- Wait until new ec2 instance domain name resolves - important in the case of a server being replaced or type changed.
- Install certbot
- Setup and download a certificate from letsencrypt
- Copy passenger-standalone.json into the app directory to enable SSL 
- Restart Passenger
- Install weekly cron to auto-update certificate
- Install weekly cron to copy updated certificate to S3

5. After setup, you may force install the SSL certificate again by changing `LE_INSTALL_SSL_ON_DEPLOY` to `true`.


## Get files from command line


```
wget https://raw.githubusercontent.com/gugaiz/letsencrypt-install-elasticbeanstalk-single-instance/master/.ebextensions/9-ssl-letsencrypt-single-instance.config
wget https://raw.githubusercontent.com/gugaiz/letsencrypt-install-elasticbeanstalk-single-instance/master/.ebextensions/9-letsencrypt-ssl-install.sh
wget https://raw.githubusercontent.com/gugaiz/letsencrypt-install-elasticbeanstalk-single-instance/master/.ebextensions/passenger-standalone.json
wget https://raw.githubusercontent.com/gugaiz/letsencrypt-install-elasticbeanstalk-single-instance/master/.ebextensions/9-post-renew-cp-s3.sh
```
