#!/bin/bash
set -euo pipefail
TOKEN=$(cat tokenfile)

LOCAL_FILE="testfile.txt"


# curl -fsSl -G "https://eapi.pcloud.com/listfolder"\
#   --data-urlencode "auth=$TOKEN" \
#     --data-urlencode "folderid=0" \

# curl -fsSl "https://eapi.pcloud.com/uploadfile"\
#   -F "auth=$TOKEN" \
#   -F "folderid=0" \
#   -F "filename=$LOCAL_FILE" \
#   -F "file=@$LOCAL_FILE"

RESPONSE=$(curl -fsSL \
  "https://eapi.pcloud.com/uploadfile" \
  -F "auth=$TOKEN" \
  -F "folderid=0" \
  -F "filename=$LOCAL_FILE" \
  -F "file=@$LOCAL_FILE")

RESULT=$(echo $RESPONSE | jq '.result')

if [ "$RESULT" -eq 0 ]; then
  FILEID=$(echo $RESPONSE | jq '.fileids[0]')
  echo "Upload OK → fileid: $FILEID"
else
  ERROR=$(echo $RESPONSE | jq -r '.error')
  echo "Upload KO → $ERROR"
  echo "---------------------------------"
  echo "Code	Description"
  echo "---------------------------------"
  echo "1000	Log in required."
  echo "2000	Log in failed."
  echo "2001	Invalid file/folder name."
  echo "2003	Access denied. You do not have permissions to preform this operation."
  echo "2005	Directory does not exist."
  echo "2008	User is over quota."
  echo "2041	Connection broken."
  echo "4000	Too many login tries from this IP address."
  echo "5000	Internal error. Try again later."
  echo "5001	Internal upload error."
  exit 1
fi