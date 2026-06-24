function login(){
    #Check sourcing
    : ${PCLOUDPASS:?non defini}

    #get a new token
    local RESPONSE=$(curl -fsSL -G \
    "https://eapi.pcloud.com/login" \
    --data-urlencode "username=${PCLOUDUSER:?Non define}" \
    --data-urlencode "password=${PCLOUDPASS:?Non define}")

    local RESULT=$(echo ${RESPONSE} | jq -r '.result')

    [[ "$RESULT" -eq 0 ]] || {
      local ERROR=$(echo $RESPONSE | jq -r '.error')
      : ${EXCEPTION:?Login failed → result: $RESULT | $ERROR}    
    }
    TOKEN=$(echo $RESPONSE | jq -r '.auth')
    echo "Token obtained : ${TOKEN:0:10}..."
}

function upload() {
    local LOCAL_FILE="${1}" #a charger depuis une vraiable d'environnement
    echo "Uploading file: ${LOCAL_FILE}"
    local LOCAL_FILENAME=$(basename "${LOCAL_FILE}")

    local PROGRESS_HASH="$(uuidgen)" # hash unique pour suivre la progression de l'upload
    local TMPFILE="/tmp/${PROGRESS_HASH}" # fichier temporaire pour stocker la réponse de l'upload
    touch "${TMPFILE}"

    #envoi du fichier en soit
    curl -fsSL \
    "https://eapi.pcloud.com/uploadfile" \
    -F "auth=${TOKEN}" \
    -F "folderid=0" \
    -F "progresshash=${PROGRESS_HASH}" \
    -F "filename=${LOCAL_FILENAME}" \
    -F "file=@${LOCAL_FILE}" > "${TMPFILE}" &
    local UPLOAD_PID=$!  # on recupère le PID du curl en background

    echo "transfering ${LOCAL_FILENAME} : ${PROGRESS_HASH}"
    #sleep 2 # attendre un peu avant de vérifier la progression

    while kill -0 ${UPLOAD_PID} 2>/dev/null; do # tant que le processus d'upload est actif
      local UPLOADPROGRESS="$(curl -fsSL -G "https://eapi.pcloud.com/uploadprogress" \
        --data-urlencode "auth=$TOKEN" \
        --data-urlencode "progresshash=$PROGRESS_HASH")"
    
      local UPR="$(jq -r '.result' <<< "${UPLOADPROGRESS}")"

      if [[ "${UPR}" -eq 1900 ]]; then
        echo "Transfer initiating"
      else
        local TOTAL=$(jq -r '.total' <<< "${UPLOADPROGRESS}")
        local TOTAL_MB=$(( "${TOTAL}" / 1024 / 1024 ))
        local UPLOADED=$(jq -r '.uploaded' <<< "${UPLOADPROGRESS}")
        local UPLOADED_MB=$(( "${UPLOADED}" / 1024 / 1024 ))
        local PERCENTAGE=$(( "${UPLOADED}" * 100 / "${TOTAL}" ))
        echo "Upload progress: ${PERCENTAGE}% (${UPLOADED_MB}/${TOTAL_MB} MB)"
      fi
      sleep 2
    done

    wait ${UPLOAD_PID}  # attend la fin proprement
    local CURL_EXIT=${?}

    [[ ${CURL_EXIT} -eq 0 ]] || : ${EXCEPTION:?curl a échoué → exit code: ${CURL_EXIT}}
    
    local RESPONSE=$(cat "${TMPFILE}")
    rm -f "$TMPFILE"

    local RESULT=$(echo "${RESPONSE}" | jq '.result')

    [[ "$RESULT" -eq 0 ]] || {
      local ERROR=$(echo $RESPONSE | jq -r '.error')
      cat << EOF
Upload KO → $ERROR
---------------------------------
Code	Description
---------------------------------
1000	Log in required.
2000	Log in failed.
2001	Invalid file/folder name.
2003	Access denied. You do not have permissions to preform this operation.
2005	Directory does not exist.
2008	User is over quota.
2041	Connection broken.
4000	Too many login tries from this IP address.
5000	Internal error. Try again later.
5001	Internal upload error.
EOF
      return 1
    }
      
    local FILEID=$( jq -r '.fileids[0]' <<< "${RESPONSE}" )
    echo "Upload OK → fileid: $FILEID"

}

function logout() {
    local LOGOUTREQ="$(curl -fsSL -G \
    "https://eapi.pcloud.com/logout" \
    --data-urlencode "auth=$TOKEN")"

    local LOGOUTRESULT="$(echo ${LOGOUTREQ} | jq -r '.result')"
    [[ "$LOGOUTRESULT" -eq 0 ]] && echo "Logout successful." || {
      local ERROR="$(jq -r '.error' <<< "${LOGOUTREQ}")"
      echo "Logout failed → $ERROR" >&2
    }
}

function get_quota() {

    local USERINFO="$(curl -fsSlG "https://eapi.pcloud.com/userinfo" \
    --data-urlencode "auth=${TOKEN:?Non define}")"
    QUOTA="$(jq '.quota' <<< "${USERINFO}")"
    USEDQUOTA="$(jq '.usedquota' <<< "${USERINFO}")"
    FREEQUOTA=$(( $QUOTA - $USEDQUOTA ))
    FREEQUOTA_MB=$(( $FREEQUOTA / 1024 / 1024 ))
    local QUOTA_MB=$(( $QUOTA / 1024 / 1024 ))
    local USEDQUOTA_MB=$(( $USEDQUOTA / 1024 / 1024 ))
    echo "Quota: ${USEDQUOTA_MB}/${QUOTA_MB} MB used, ${FREEQUOTA_MB} MB free"
}
