#!/bin/bash
set -euo pipefail #le script s'arrête proprement sur n'importe quelle erreur.

source /home/fahim/homelab/.secret/pcloud.env

if [ -z "${PCLOUDPASS:-}" ]; then
  echo "PCLOUDPASS non défini"
  exit 1
fi

TOKEN=$(curl -fsSL "https://eapi.pcloud.com/login?username=$PCLOUDUSER&password=$PCLOUDPASS" | grep -o '"auth": "[^"]*"' | cut -d'"' -f4)
echo $TOKEN
if [ -z "$TOKEN" ]; then
  echo "Failed to obtain token. Please check your credentials."
  exit 1
else
  echo "Token obtained :${TOKEN:0:10}..." 
fi