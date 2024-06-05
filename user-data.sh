#!/bin/bash

sudo yum update
sudo yum install nginx -y
sudo systemctl start nginx

myip=`curl checkip.amazonaws.com`

sudo chmod 2775 /usr/share/nginx/html 
sudo find /usr/share/nginx/html -type d -exec chmod 2775 {} \;
sudo find /usr/share/nginx/html -type f -exec chmod 0664 {} \;

sudo echo "<h3>WebServer with IP: $myip Made with Terraform </h3>" > /usr/share/nginx/html/index.html
