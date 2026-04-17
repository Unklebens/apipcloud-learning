#!/bin/bash
set -euo pipefail #le script s'arrête proprement sur n'importe quelle erreur.

if [ -f "tokenfile" ]
then 
    TOKEN=$(cat "tokenfile")
fi

LOGOUTREQ=$(curl -fsSL -G \
  "https://eapi.pcloud.com/logout" \
  --data-urlencode "auth=$TOKEN")

LOGOUTRESULT=$(echo $LOGOUTREQ | jq '.result')
if [ "$LOGOUTRESULT" -eq 0 ]; then
  echo "Logout successful."
  rm -f "tokenfile"
else
  ERROR=$(echo $LOGOUTREQ | jq -r '.error')
  echo "Logout failed → $ERROR"
fi