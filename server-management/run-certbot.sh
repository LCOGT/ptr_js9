############################# 
###   SSL Certificates    ### 
############################# 
 
SERVER_URL="https://js9.photonranch.org" 
SERVER_NAME="js9.photonranch.org" 
default_user="ubuntu"
 
# Obtain ssl certificates with the help of certbot 
# Note: certbot should automatically renew certificates before they expire. 
certbot -n --apache --domains $SERVER_NAME --agree-tos --email photonadmin@lco.global 
 
# Copy ssl certificates and grant $default_user access (so we don't need to mess with  
# the original certificate permissions).  
ssl_dir=/var/www/js9/ssl_copies 
mkdir -p $ssl_dir 
cp /etc/letsencrypt/live/$SERVER_NAME/fullchain.pem /var/www/js9/ssl_copies/ 
cp /etc/letsencrypt/live/$SERVER_NAME/privkey.pem /var/www/js9/ssl_copies/ 
chown $default_user "$ssl_dir"/*.pem 
 
# Instruct the node helper where to find the ssl certificates. 
echo '{ 
        "key": "'$ssl_dir'/privkey.pem", 
        "cert": "'$ssl_dir'/fullchain.pem" 
}' > /var/www/js9/js9Secure.json 

# Restart the node helper by sending a SIGUSR2 signal
su - $default_user -c "kill -USR2 `ps guwax | egrep js9Helper | egrep -v egrep | awk '{print $2}'`"
