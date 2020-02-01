#!/bin/bash
TOKEN=<YOUR_CLOUDFLARE_TOKEN>
ZONE_ID=<YOUR_ZONE_ID>
ZONE_NAME=<YOUR_ZONE_NAME>
DNS_RECORD=<YOUR_DNS_RECORD_YOU_WANT_TO_CHANGE>
RECORD_TYPE=<YOUR_DNS_RECORD_TYPE>
RECORD_NAME=<YOUR_DNS_RECORD_NAME>
# More rules
RULE_PROXIABLE=true
RULE_PROXIED=true
RULE_LOCKED=false
STORED_IP=$(cat ipstored)
# put your email here if you want an email update
SEND_UPDATE_EMAIL=


PUBLIC_IP=$(curl  -s 'icanhazip.com')

if [[ $STORED_IP != $PUBLIC_IP ]]
then
  OUTPUT=$(wget --quiet \
    --method PUT \
    --timeout=0 \
    --header 'Content-Type: application/json' \
    --header="Authorization: Bearer $TOKEN" \
    --body-data="{
      \"id\": \"$DNS_RECORD\",
      \"type\": \"$RECORD_TYPE\",
      \"name\": \"$RECORD_NAME\",
      \"content\": \"$PUBLIC_IP\",
      \"proxiable\": $RULE_PROXIABLE,
      \"proxied\": $RULE_PROXIED,
      \"ttl\": 1,
      \"locked\": $RULE_LOCKED,
      \"zone_id\": \"$ZONE_ID\",
      \"zone_name\": \"$ZONE_NAME\",
      \"meta\": {
          \"auto_added\": false,
          \"managed_by_apps\": false,
          \"managed_by_argo_tunnel\": false
      }
  }" \
     -O - "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD")

  IP_UPDATED=$(echo $OUTPUT | jq -r '.result.content')
  echo $IP_UPDATED > ipstored
  RESULT=$(echo $OUTPUT | jq -r '.success')
  if [[ $RESULT == 'true' ]]
  then
    if [[ -z "$SEND_UPDATE_EMAIL" ]]
    then
      echo IP UPDATED TO $IP_UPDATED
    else
      echo "Subject: IP UPDATED TO $IP_UPDATED" | sendmail $SEND_UPDATE_EMAIL
    fi
  else
    echo There was an error updating to $IP_UPDATED
  fi
fi
