#!/bin/bash 
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
docker run -p 8080:80 -d --name nginx1 nginx