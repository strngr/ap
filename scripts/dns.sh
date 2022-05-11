#!/bin/bash -ex

aws configure get region || aws configure set region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

DNS_RECORD=$(aws ssm get-parameter --name DNS_RECORD | jq -r .Parameter.Value)
DNS_ID=$(aws ssm get-parameter --name DNS_ID | jq -r .Parameter.Value)

INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
CURRENT_IP=$(dig +short $DNS_RECORD)

if [ "x$CURRENT_IP" == "x$INSTANCE_IP" ]; then
        echo "already valid"
        exit 0
fi

API_ENDPOINT=$(aws ssm get-parameter --name API_ENDPOINT | jq -r .Parameter.Value)
API_TOKEN=$(aws ssm get-parameter --name API_TOKEN | jq -r .Parameter.Value)

echo "Instance IP: $INSTANCE_IP"
echo "Current IP: $CURRENT_IP"

curl $API_ENDPOINT \
        -H "Authorization: $API_TOKEN" \
        -d "subdomain_id=$DNS_ID&data=$INSTANCE_IP"
