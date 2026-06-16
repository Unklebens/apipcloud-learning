function login(){
    #Check sourcing
    if [ -z "${PCLOUDPASS:-}" ]; then
    echo "PCLOUDPASS non défini"
    exit 1
    fi

    #get a new token
    local RESPONSE=$(curl -fsSL -G \
    "https://eapi.pcloud.com/login" \
    --data-urlencode "username=$PCLOUDUSER" \
    --data-urlencode "password=$PCLOUDPASS")

    local RESULT=$(echo $RESPONSE | jq -r '.result')

    if [ "$RESULT" -eq 0 ]; then
    TOKEN=$(echo $RESPONSE | jq -r '.auth')
    echo "Token obtained : ${TOKEN:0:10}..."
    else
    local ERROR=$(echo $RESPONSE | jq -r '.error')
    echo "Login failed → result: $RESULT | $ERROR"
    exit 1
    fi

    #store token
    if [ ! -f "tokenfile" ]
    then 
        echo "$TOKEN" > "tokenfile"
    fi

}

function upload() {
    local LOCAL_FILE="$1" #a charger depuis une vraiable d'environnement
    echo "Uploading file: $LOCAL_FILE"
    local LOCAL_FILENAME=$(basename "$LOCAL_FILE")

    local PROGRESS_HASH=$(uuidgen) # hash unique pour suivre la progression de l'upload
    local TMPFILE=/tmp/$PROGRESS_HASH # fichier temporaire pour stocker la réponse de l'upload
    touch $TMPFILE

    #envoi du fichier en soit
    curl -fsSL \
    "https://eapi.pcloud.com/uploadfile" \
    -F "auth=$TOKEN" \
    -F "folderid=0" \
    -F "progresshash=$PROGRESS_HASH" \
    -F "filename=$LOCAL_FILENAME" \
    -F "file=@$LOCAL_FILE" > "$TMPFILE" &
    local UPLOAD_PID=$!  # on recupère le PID du curl en background

    echo "transfering $LOCAL_FILENAME : $PROGRESS_HASH"
    #sleep 2 # attendre un peu avant de vérifier la progression

    while kill -0 $UPLOAD_PID 2>/dev/null; do # tant que le processus d'upload est actif
    local UPLOADPROGRESS=$(curl -fsSL -G "https://eapi.pcloud.com/uploadprogress" \
        --data-urlencode "auth=$TOKEN" \
        --data-urlencode "progresshash=$PROGRESS_HASH")
    
    local UPR=$(echo $UPLOADPROGRESS | jq -r '.result')

    if [ "$UPR" -eq 1900 ]; then
        echo "Transfer initiating"
        else
        local TOTAL=$(echo $UPLOADPROGRESS | jq -r '.total')
        local TOTAL_MB=$(( TOTAL / 1024 / 1024 ))
        local UPLOADED=$(echo $UPLOADPROGRESS | jq -r '.uploaded')
        local UPLOADED_MB=$(( UPLOADED / 1024 / 1024 ))
        local PERCENTAGE=$((UPLOADED * 100 / TOTAL))
        echo "Upload progress: $PERCENTAGE% ($UPLOADED_MB/$TOTAL_MB MB)"
    fi
    sleep 2
    done

    wait $UPLOAD_PID  # attend la fin proprement
    local CURL_EXIT=$?

    if [ $CURL_EXIT -ne 0 ]; then
    echo "curl a échoué → exit code: $CURL_EXIT"
    return 1
    fi
    
    local RESPONSE=$(cat "$TMPFILE")
    rm -f "$TMPFILE"

    local RESULT=$(echo $RESPONSE | jq '.result')

    if [ "$RESULT" -eq 0 ]; then
    local FILEID=$(echo $RESPONSE | jq '.fileids[0]')
    echo "Upload OK → fileid: $FILEID"
    else
    local ERROR=$(echo $RESPONSE | jq -r '.error')
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
    return 1
    fi

}

function logout() {
    local LOGOUTREQ=$(curl -fsSL -G \
    "https://eapi.pcloud.com/logout" \
    --data-urlencode "auth=$TOKEN")

    local LOGOUTRESULT=$(echo $LOGOUTREQ | jq '.result')
    if [ "$LOGOUTRESULT" -eq 0 ]; then
    echo "Logout successful."
    else
    local ERROR=$(echo $LOGOUTREQ | jq -r '.error')
    echo "Logout failed → $ERROR"
    fi
}

function get_quota() {

    local USERINFO=$(curl -fsSlG "https://eapi.pcloud.com/userinfo" \
    --data-urlencode "auth=$TOKEN")
    local QUOTA=$(echo $USERINFO | jq '.quota')
    local QUOTA_MB=$(( QUOTA / 1024 / 1024 ))
    local USEDQUOTA=$(echo $USERINFO | jq '.usedquota')
    local USEDQUOTA_MB=$(( USEDQUOTA / 1024 / 1024 ))
    echo "Quota: $USEDQUOTA_MB/$QUOTA_MB MB"
}