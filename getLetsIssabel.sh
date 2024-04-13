#!/bin/bash

# Prompt the user to enter the domain name
read -p "Enter your domain name: " domain

# Run Certbot commands with the user-provided domain

service httpd stop
certbot certonly --standalone -d $domain
service httpd start
certbot install --cert-name $domain --apache

mv /etc/asterisk/keys/asterisk.pem /etc/asterisk/keys/asterisk-bk.pem
cat /etc/letsencrypt/archive/$domain/privkey1.pem > /etc/asterisk/keys/asterisk.pem
cat /etc/letsencrypt/archive/$domain/fullchain1.pem >> /etc/asterisk/keys/asterisk.pem
chown asterisk:asterisk /etc/asterisk/keys/asterisk.pem
chmod 664 /etc/asterisk/keys/asterisk.pem


# add lines to "/etc/asterisk/sip_general_custom.conf"

# Define the lines to add to the sip_general_custom.conf file
lines="
tlsenable=yes
tlsbindaddr=0.0.0.0
tlscertfile=/etc/asterisk/keys/asterisk.pem
tlscafile=/etc/asterisk/keys/asterisk.pem
tlsdontverifyserver=no
tlscipher=ALL
tlsclientmethod=ALL
"

# Add the lines to the sip_general_custom.conf file
echo "$lines" | sudo tee -a /etc/asterisk/sip_general_custom.conf


service asterisk reload