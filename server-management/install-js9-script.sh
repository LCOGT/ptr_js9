#!/bin/bash

# This script is written for Ubuntu Server 18.04 LTS on an AWS EC2 instance
# It will install JS9 and required dependencies, configure apache, and start
# a Node helper to enable server-side analysis. 

# Go to ec2 console -> select our instance 
#                   -> security groups
#                   -> inbound
#                   -> edit, add (type:http, protocol:tcp, port:80, source:0.0.0.0/0)

# For the domain name to work (presumably js9.photonranch.org), make sure it is
# defined in aws route53. Go to route53 console -> hosted zones
# -> create record set -> create with name=js9, type=A(IPv4 address), alias=no, 
# and value=x.x.x.x (the instance's public IPv4 address)

# Regular ownership of ptr_js9 directory
chown -R ubuntu:ubuntu /home/ubuntu/ptr_js9

#############################
###    Variables          ###
#############################

# IP address with format x.x.x.x
PUBLIC_IPV4="$(curl http://169.254.169.254/latest/meta-data/public-ipv4)"

HOSTED_ZONE_ID="ZREMYMWMI0QBT"

SERVER_URL="https://js9.photonranch.org"
SERVER_NAME="js9.photonranch.org"

default_user="ubuntu"


#############################
### Download Dependencies ###
#############################

# install required depenencies
apt update -y
apt install gcc -y
apt install make -y	 
apt install nodejs -y	# server side helper 
apt install apache2 -y	# web server
apt install funtools -y	# server side analysis tools
apt install python3-pip -y
apt install virtualenv -y
apt install awscli -y
apt install tree -y

# install certbot (to make ssl certs)
apt-get install software-properties-common -y
add-apt-repository universe -y
add-apt-repository ppa:certbot/certbot -y
apt-get update -y
apt-get install certbot python-certbot-apache -y


#############################
###  Update Record Sets   ###
#############################

aws route53 change-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --change-batch '{
	"Comment": "Changing js9.photonranch.org to point this ec2 instance.", 
	"Changes": [
	  {
	    "Action": "UPSERT",
	    "ResourceRecordSet": {
	      "Name": "js9.photonranch.org",
	      "Type": "A",
	      "TTL": 300,
	      "ResourceRecords": [
		{
		  "Value": "'$PUBLIC_IPV4'"
		}
	      ]
	    }
	  }
	]
	}'



#############################
###      Install JS9      ###
#############################

# get the js9 code
cd /home/ubuntu/
git clone https://github.com/ericmandel/js9
git clone https://github.com/ericmandel/js9data
git clone https://github.com/healpy/cfitsio

# Create js9 install directory and change ownership to self
mkdir /var/www/js9
chown -R ubuntu:ubuntu /var/www/js9

# create additional helper directories
mkdir /soft
chown -R ubuntu:ubuntu /soft
mkdir /soft/saord

# install cfitsio
cd /home/ubuntu/cfitsio
./configure --prefix=/soft/saord
make
make install
cd /home/ubuntu/

# move js9 data to the web install directory
cp -r /home/ubuntu/js9data/* /var/www/js9

# Specify initial js9 preferences
echo 'var JS9Prefs = {
  "globalOpts": {"helperType":	     "nodejs",
  		 "helperPort":       2718, 
		 "helperCGI":        "./cgi-bin/js9/js9Helper.cgi",
		 "helperURL":	     "'"$SERVER_URL"'",
		 "installDir": 	     "'"$SERVER_URL"'/js9",
		 "fits2png":         false,
		 "debug":	     0,
		 "loadProxy":	     true,
		 "workDir":	     "./tmp",
		 "workDirQuota":     1000,
		 "dataPath":	     "$HOME/Desktop:$HOME/data",
		 "analysisPlugins":  "/home/ubuntu/ptr_js9/analysis-plugins",
		 "analysisWrappers": "/home/ubuntu/ptr_js9/analysis-wrappers"},
  "imageOpts":  {"colormap":	     "grey",
  		 "scale":     	     "log"}
}' > /home/ubuntu/js9/js9prefs.js

echo '{
  "globalOpts": {"helperType":	     "nodejs",
  		 "helperPort":       2718, 
		 "helperURL":	     "'"$SERVER_URL"'",
		 "installDir": 	     "'"$SERVER_URL"'/js9",
		 "helperCGI":        "./cgi-bin/js9/js9Helper.cgi",
		 "fits2png":         false,
		 "debug":	     0,
		 "loadProxy":	     true,
		 "workDir":	     "./tmp",
		 "workDirQuota":     1000,
		 "dataPath":	     "$HOME/Desktop:$HOME/data",
		 "analysisPlugins":  "/home/ubuntu/ptr_js9/analysis-plugins",
		 "analysisWrappers": "/home/ubuntu/ptr_js9/analysis-wrappers"},
  "imageOpts":  {"colormap":	     "grey",
  		 "scale":     	     "log"}
}' > /home/ubuntu/js9/js9Prefs.json

# install js9
cd /home/ubuntu/js9
./configure --with-webdir=/var/www/js9 \
            --with-cfitsio=/soft/saord \
            --with-helper=nodejs \
            --prefix=/soft/saord \
            CC=gcc $*
make
make install
make install-gzip
make clean

# Move the index.html up one level (so the DocumentRoot serves the index page)
mv /var/www/js9/index.html /var/www


#############################
### Apache2 Configuration ###
#############################

# make sure to set 'DocumentRoot /var/www' in /etc/apache2/sites-available/000-default.conf
sed -i 's/DocumentRoot .*$/DocumentRoot \/var\/www\/\n\tServerName '"$SERVER_NAME"'/' \
	/etc/apache2/sites-available/000-default.conf

### Enable CORS: edit /etc/apache2/apache2.conf, and inside <Directory>, add:
# `Header set Access-Control-Allow-Origin "*"` 
# https://stackoverflow.com/questions/29150384/how-to-allow-cross-domain-request-in-apache2
# then: `a2enmod headers` and `sudo service apache2 restart`.
sed -i \
	's/<Directory \/var\/www\/>/<Directory \/var\/www\/>\n\tHeader set Access-Control-Allow-Origin \"\*\"/' \
	/etc/apache2/apache2.conf
a2enmod headers
service apache2 restart


#############################
###   SSL Certificates    ###
#############################

SERVER_URL="https://js9.photonranch.org"
SERVER_NAME="js9.photonranch.org"

# Obtain ssl certificates with the help of certbot
# Note: certbot should automatically renew certificates before they expire.
certbot -n --apache --domains $SERVER_NAME --agree-tos --email photonadmin@lco.global

# Copy ssl certificates and grant $default_user access (so we don't need to mess with 
# the original certificate permissions). 
ssl_dir=/var/www/js9/ssl_copies
mkdir $ssl_dir
cp /etc/letsencrypt/live/$SERVER_NAME/fullchain.pem /var/www/js9/ssl_copies/
cp /etc/letsencrypt/live/$SERVER_NAME/privkey.pem /var/www/js9/ssl_copies/
chown $default_user "$ssl_dir"/*.pem

# Instruct the node helper where to find the ssl certificates.
echo '{
	"key": "'$ssl_dir'/privkey.pem",
	"cert": "'$ssl_dir'/fullchain.pem"
}' > /var/www/js9/js9Secure.json


#############################
###   NodeJS Helper       ###
#############################

# Create a logs folder for the node helper
mkdir /home/ubuntu/logs
chown -R ubuntu:ubuntu /home/ubuntu/logs

# Add the funcnts scripts to the path
# Add start/reload node helper shortcuts
cat >> /home/ubuntu/.bashrc <<'EOF'
PATH=$PATH:/soft/saord/bin:/soft/saord
alias nodeHelperStart="node /var/www/js9/js9Helper.js 1>/home/ubuntu/logs/js9node.log 2>&1 &"
alias nodeHelperReload="kill -USR2 `ps guwax | egrep js9Helper | egrep -v egrep | awk '{print $2}'`"

if [ -f ~/.bash_aliases ]; then
.  ~/.bash_aliases
fi
EOF
source /home/ubuntu/.bashrc
su - ubuntu -c 'source /home/ubuntu/.bashrc'

# Start the node helper as the default (non-root) user
su - ubuntu -c 'node /var/www/js9/js9Helper.js 1>/home/ubuntu/logs/js9node.log 2>&1 &'


#############################
###   Custom Scripts      ###
#############################

# Make the virtual environment to run custom python scripts
su - ubuntu -c 'virtualenv -p /usr/bin/python3 /home/ubuntu/ptr_js9/python-scripts/venv'
# Activate the virtual environment and pip install dependencies. 
su - ubuntu -c 'source /home/ubuntu/ptr_js9/python-scripts/venv/bin/activate && pip3 install -r /home/ubuntu/ptr_js9/python-scripts/requirements.txt'


