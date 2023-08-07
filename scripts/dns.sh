#!/bin/bash -ex

aws configure get region || aws configure set region $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

DNS_RECORD=$(aws ssm get-parameter --name DNS_RECORD | jq -r .Parameter.Value)
DNS_ID=$(aws ssm get-parameter --name DNS_ID | jq -r .Parameter.Value)

INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
CURRENT_IP=$(dig +short $DNS_RECORD)

###

if [ "x$CURRENT_IP" == "x$INSTANCE_IP" ]; then
        echo "already valid"
        exit 0
fi

API_ENDPOINT=$(aws ssm get-parameter --name API_ENDPOINT | jq -r .Parameter.Value)
API_TOKEN=$(aws ssm get-parameter --name API_TOKEN | jq -r .Parameter.Value)

TG_TOKEN=$(aws ssm get-parameter --name TG_TOKEN --with-decryption | jq -r .Parameter.Value)
#TG_ENDPOINT=$(aws ssm get-parameter --name TG_ENDPOINT | jq -r .Parameter.Value | envsubst)
TG_ENDPOINT="https://api.telegram.org/bot${TG_TOKEN}/sendMessage"
TG_CHAT_ID=$(aws ssm get-parameter --name TG_CHAT_ID | jq -r .Parameter.Value)
TG_MSG_OK="The OpenVPN IP address has been changed to \`$INSTANCE_IP\`. Please hold on until the change propagades."
TG_MSG_FAIL="Failed to change OpenVPN IP address. Please reach out to @strngrname."
TG_MSG=$TG_MSG_OK

echo "Instance IP: $INSTANCE_IP"
echo "Current IP: $CURRENT_IP"

API_RESPONSE=$(curl $API_ENDPOINT \
        -H "Authorization: $API_TOKEN" \
        -d "subdomain_id=$DNS_ID&data=$INSTANCE_IP")
_ret=$?

if [ $_ret -ne 0 ] ; then
    TG_MSG=$TG_MSG_FAIL$'\n\n''```'$API_RESPONSE'```'
fi

curl -X POST $TG_ENDPOINT -d chat_id=$TG_CHAT_ID -d text="$TG_MSG" -d parse_mode=markdown
