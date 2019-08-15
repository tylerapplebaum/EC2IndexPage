#!/bin/bash

# Get Apache squared away
sudo yum -y install httpd
usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo systemctl restart httpd.service
sudo systemctl enable httpd.service

# Fetch data from metadata service
public_ipv4=$(curl -s "http://169.254.169.254/latest/meta-data/public-ipv4")
instance_id=$(curl -s "http://169.254.169.254/latest/meta-data/instance-id")
instance_type=$(curl -s "http://169.254.169.254/latest/meta-data/instance-type")

# Populate item.json for DynamoDB PUT
curl -O https://raw.githubusercontent.com/tylerapplebaum/EC2IndexPage/master/item.json
sed -i "s/i-xxxxxxxxxxxxxxxxx/$instance_id/g" item.json
sed -i "s/x.x.x.x/$public_ipv4/g" item.json
sed -i "s/zzinstance/$instance_type/g" item.json

# PUT to DynamoDB - need to validate success (v2.0)
aws dynamodb put-item --table-name InstanceTable --item file://item.json --region us-west-2

# Do we need to save these to a file anymore? No longer using AJAX, so...
sudo echo $publicipv4 > ~/publicipv4.txt
sudo echo $instanceid > ~/instanceid.txt

# Prepare index.html
cd /var/www/html
curl -O https://raw.githubusercontent.com/tylerapplebaum/EC2IndexPage/master/index.html
sed -i "s/i-xxxxxxxxxxxxxxxxx/$instance_id/g" index.html

# Let's use our original variable instead
# iid=$(cat instanceid.txt)

# At this point, index.html is populated with this EC2 instance's ID
# The instance ID will act as a primary key for reading from the DynamoDB instance
sudo systemctl restart httpd.service
