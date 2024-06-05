#!/bin/bash

sudo yum update
sudo yum install nginx -y
sudo systemctl start nginx

myip='curl checkip.amazonaws.com'

chmod 2775 /usr/share/nginx/html 
find /usr/share/nginx/html -type d -exec chmod 2775 {} \;
find /usr/share/nginx/html -type f -exec chmod 0664 {} \;

echo "<h3>WebServer with IP: $myip</h2> Made with Terraform </h3>" > /usr/share/nginx/html/index.html