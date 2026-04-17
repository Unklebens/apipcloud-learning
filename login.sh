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
    echo "tokenfile not exist, continue"
fi

#get a new token
TOKEN=$(curl -fsSL -G \
  "https://eapi.pcloud.com/login" \
  --data-urlencode "username=$PCLOUDUSER" \
  --data-urlencode "password=$PCLOUDPASS" \
  | jq -r '.auth')

  
if [ -z "$TOKEN" ]; then
  echo "Failed to obtain token. Please check your credentials."
  exit 1
else
  echo "Token obtained :${TOKEN:0:10}..." 
fi

#store tocken
if [ ! -f "tokenfile" ]
then 
    echo "$TOKEN" > "tokenfile"
fi