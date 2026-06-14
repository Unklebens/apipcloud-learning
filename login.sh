#!/bin/bash
set -euo pipefail #le script s'arrête proprement sur n'importe quelle erreur.

source ../homelab/.secret/pcloud.env

#Check sourcing
if [ -z "${PCLOUDPASS:-}" ]; then
  echo "PCLOUDPASS non défini"
  exit 1
fi

#check tokenfile
if [ -f "tokenfile" ]
then 
    echo "tokenfile exist, removing it"
    rm -f "tokenfile"
else
    echo "tokenfile does not exist, continue"
fi

#get a new token
RESPONSE=$(curl -fsSL -G \
  "https://eapi.pcloud.com/login" \
  --data-urlencode "username=$PCLOUDUSER" \
  --data-urlencode "password=$PCLOUDPASS")

RESULT=$(echo $RESPONSE | jq -r '.result')

if [ "$RESULT" -eq 0 ]; then
  TOKEN=$(echo $RESPONSE | jq -r '.auth')
  echo "Token obtained : ${TOKEN:0:10}..."
else
  ERROR=$(echo $RESPONSE | jq -r '.error')
  echo "Login failed → result: $RESULT | $ERROR"
  exit 1
fi

#store token
if [ ! -f "tokenfile" ]
then 
    echo "$TOKEN" > "tokenfile"
fi
