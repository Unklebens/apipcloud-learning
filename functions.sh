function login(){
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

}

function upload() {
    TOKEN=$(cat tokenfile)

    LOCAL_FILE="$1"
    LOCAL_FILENAME=$(basename "$LOCAL_FILE")

    PROGRESS_HASH=$(uuidgen) # hash unique pour suivre la progression de l'upload
    TMPFILE=/tmp/$PROGRESS_HASH # fichier temporaire pour stocker la réponse de l'upload
    touch $TMPFILE

    #envoi du fichier en soit
    curl -fsSL \
    "https://eapi.pcloud.com/uploadfile" \
    -F "auth=$TOKEN" \
    -F "folderid=0" \
    -F "progresshash=$PROGRESS_HASH" \
    -F "filename=$LOCAL_FILENAME" \
    -F "file=@$LOCAL_FILE" > "$TMPFILE" &
    UPLOAD_PID=$!  # on recupère le PID du curl en background

    echo "transfering $LOCAL_FILENAME : $PROGRESS_HASH"
    #sleep 2 # attendre un peu avant de vérifier la progression

    while kill -0 $UPLOAD_PID 2>/dev/null; do # tant que le processus d'upload est actif
    UPLOADPROGRESS=$(curl -fsSL -G "https://eapi.pcloud.com/uploadprogress" \
        --data-urlencode "auth=$TOKEN" \
        --data-urlencode "progresshash=$PROGRESS_HASH")
    
    UPR=$(echo $UPLOADPROGRESS | jq -r '.result')

    if [ "$UPR" -eq 1900 ]; then
        echo "Transfer initiating"
        else
        TOTAL=$(echo $UPLOADPROGRESS | jq -r '.total')
        TOTAL_MB=$(( TOTAL / 1024 / 1024 ))
        UPLOADED=$(echo $UPLOADPROGRESS | jq -r '.uploaded')
        UPLOADED_MB=$(( UPLOADED / 1024 / 1024 ))
        PERCENTAGE=$((UPLOADED * 100 / TOTAL))
        echo "Upload progress: $PERCENTAGE% ($UPLOADED_MB/$TOTAL_MB MB)"
    fi
    sleep 2
    done

    wait $UPLOAD_PID  # attend la fin proprement

    RESPONSE=$(cat "$TMPFILE")
    rm -f "$TMPFILE"

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

}

function logout() {
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
}
