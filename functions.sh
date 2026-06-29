function login(){
    #Check sourcing
    : ${PCLOUDPASS:?non defini}

    #get a new token
    local RESPONSE=$(curl -fsSL -G \
    "https://eapi.pcloud.com/login" \
    --data-urlencode "username=${PCLOUDUSER:?Non defini}" \
    --data-urlencode "password=${PCLOUDPASS:?Non defini}")

    local RESULT=$(echo ${RESPONSE} | jq -r '.result')

    [[ "$RESULT" -eq 0 ]] || {
      local ERROR=$(echo $RESPONSE | jq -r '.error')
      : ${EXCEPTION:?Login failed → result: $RESULT | $ERROR}    
    }
    TOKEN=$(echo $RESPONSE | jq -r '.auth')
    echo "Token obtenu : ${TOKEN:0:10}..."
}

function upload() {
    local LOCAL_FILE="${1}" #a charger depuis une vraiable d'environnement
    echo "Upload du fichier: ${LOCAL_FILE}"
    local LOCAL_FILENAME=$(basename "${LOCAL_FILE}")

    local PROGRESS_HASH="$(uuidgen)" # hash unique pour suivre la progression de l'upload
    local TMPFILE="/tmp/${PROGRESS_HASH}" # fichier temporaire pour stocker la réponse de l'upload
    touch "${TMPFILE}"

    #envoi du fichier en soit
    curl -fsSL \
    "https://eapi.pcloud.com/uploadfile" \
    -F "auth=${TOKEN}" \
    -F "folderid=${FOLDERID}" \
    -F "progresshash=${PROGRESS_HASH}" \
    -F "filename=${LOCAL_FILENAME}" \
    -F "file=@${LOCAL_FILE}" > "${TMPFILE}" &
    local UPLOAD_PID=$!  # on recupère le PID du curl en background

    echo "Upload ${LOCAL_FILENAME} : ${PROGRESS_HASH}"
    sleep 15 # attendre un peu avant de vérifier la progression

    while kill -0 ${UPLOAD_PID} 2>/dev/null; do # tant que le processus d'upload est actif
      local UPLOADPROGRESS="$(curl -fsSL -G "https://eapi.pcloud.com/uploadprogress" \
        --data-urlencode "auth=$TOKEN" \
        --data-urlencode "progresshash=$PROGRESS_HASH")"
    
      local UPR="$(jq -r '.result' <<< "${UPLOADPROGRESS}")"

      if [[ "${UPR}" -eq 1900 ]]; then
        echo "Suivi du transfert indisponible : "${UPR}"" # uploadprogress marche pas bien pour les gros fichiers, on ne peut pas suivre la progression
      else
        local TOTAL=$(jq -r '.total' <<< "${UPLOADPROGRESS}")
        local TOTAL_MB=$(( TOTAL / 1024 / 1024 ))
        local UPLOADED=$(jq -r '.uploaded' <<< "${UPLOADPROGRESS}")
        local UPLOADED_MB=$(( UPLOADED / 1024 / 1024 ))
        local PERCENTAGE=$(( UPLOADED * 100 / TOTAL ))
        echo "Transfert: ${PERCENTAGE}% (${UPLOADED_MB}/${TOTAL_MB} MB)"
      fi
      sleep 30
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
    [[ "${LOGOUTRESULT}" -eq 0 ]] && echo "Déconnexion réussie." || {
      local ERROR="$(jq -r '.error' <<< "${LOGOUTREQ}")"
      echo "Déconnexion echouée → $ERROR" >&2
    }
}

function get_quota() {

    local USERINFO="$(curl -fsSlG "https://eapi.pcloud.com/userinfo" \
    --data-urlencode "auth=${TOKEN:?Non defini}")"
    local QUOTA="$(jq '.quota' <<< "${USERINFO}")"
    local USEDQUOTA="$(jq '.usedquota' <<< "${USERINFO}")"
    FREEQUOTA=$(( QUOTA - USEDQUOTA )) #pas local car on s'en sert dans main.sh
    local FREEQUOTA_MB=$(( FREEQUOTA / 1024 / 1024 ))
    local QUOTA_MB=$(( QUOTA / 1024 / 1024 ))
    local USEDQUOTA_MB=$(( USEDQUOTA / 1024 / 1024 ))
    echo "Quota: ${USEDQUOTA_MB}/${QUOTA_MB} MB utilisés, ${FREEQUOTA_MB} MB libre"
}

function list_folder() {

    local LISTFOLDER="$(curl -fsSLG "https://eapi.pcloud.com/listfolder" \
    --data-urlencode "auth=${TOKEN:?Non defini}" \
    --data-urlencode "folderid=${FOLDERID:?Non defini}")"
    #echo "${LISTFOLDER}"

    local RESULT="$(jq -r '.result' <<< "${LISTFOLDER}")"
    [[ "${RESULT}" -eq 0 ]] || {
      local ERROR="$(jq -r '.error' <<< "${LISTFOLDER}")"
      : ${EXCEPTION:?List folder failed → result: $RESULT | $ERROR}
    }

    FILECOUNT="$(jq -r '.metadata.contents | length' <<< "${LISTFOLDER}")"
    echo "Repertoire ${FOLDERID} contiens ${FILECOUNT} fichiers."

    FILESPRESENT=()
    local FILELIST="$(jq -r '.metadata.contents | sort_by(.name) | .[] | select(.isfolder == false) | [.name, (.fileid | tostring)] | join(":")' <<< "${LISTFOLDER}")"
    readarray -t FILESPRESENT <<< "${FILELIST}"

    echo "Fichiers dans le repoertoire ${FOLDERID}:"
    for f in "${FILESPRESENT[@]}"; do
        echo "  - $f"
    done

}

function delete_file() {

  : ${1:?Fichier a supprimer non defini} 
  local FTD=$(cut -d ':' -f 1 <<< "${1}") # nom du fichier à supprimer
  local IDTD=$(cut -d ':' -f 2 <<< "${1}")
  local FILEDELETION="$(curl -fsSLG "https://eapi.pcloud.com/deletefile" \
    --data-urlencode "auth=${TOKEN:?Non defini}" \
    --data-urlencode "fileid=${IDTD:?Non defini}")"

    local RESULT="$(jq -r '.result' <<< "${FILEDELETION}")"
    [[ "${RESULT}" -eq 0 ]] && echo "Fichier "${FTD}" supprimé avec succès." && FILESPRESENT=("${FILESPRESENT[@]:1}") && (( FILECOUNT-- )) || {
      local ERROR="$(jq -r '.error' <<< "${FILEDELETION}")"
      : ${EXCEPTION:?Delete file failed → result: $RESULT | $ERROR}
    }
}

function empty_trash() {
    #empty trash
    local EMPTYTRASH="$(curl -fsSLG "https://eapi.pcloud.com/trash_clear" \
    --data-urlencode "auth=${TOKEN:?Non defini}" \
    --data-urlencode "folderid=0")"

    local RESULTTRASH="$(jq -r '.result' <<< "${EMPTYTRASH}")"
    [[ "$RESULTTRASH" -eq 0 ]] || {
      local ERROR="$(jq -r '.error' <<< "${EMPTYTRASH}")"
      : ${EXCEPTION:?Empty trash failed → result: $RESULTTRASH | $ERROR}
    }

    [[ "${RESULTTRASH}" -eq 0 ]] && echo "Corbeille vidée avec succès."

}

function multiple_upload(){

  TOTAL=${#}
  COUNT=0
  SUCCESS_FILES=()
  FAIL_FILES=()

  for f; do # parcours les parametres
    [[ -f "${f}" ]] || { echo "Fichier ${f} introuvable. Fichier ignoré." >&2; FAIL_FILES+=("${f}"); continue; }
    COUNT=$((COUNT + 1))
    echo "Transferring file $COUNT/$TOTAL"
    FILESIZE="$(du -b "$f" | cut -f1)"
    if [[ ${FILESIZE} -gt ${FREEQUOTA:?variable non définie} ]]; then
      FILESIZE_MB=$(( FILESIZE / 1024 / 1024 ))
      echo "Le fichier  ${f} a une taille trop importante (${FILESIZE_MB} MB). Fichier ignoré."
      FAIL_FILES+=("${f}")
      continue
    fi
    upload "${f}"
    if [[ ${?} -eq 0 ]]; then
      SUCCESS_FILES+=("${f}")
      FREEQUOTA=$(( FREEQUOTA - FILESIZE ))
    else
      echo "Le fichier  ${f} a échoué. Fichier ignoré."
      FAIL_FILES+=("${f}")
    fi
  done
  echo "Upload terminé : ${#SUCCESS_FILES[@]} OK, ${#FAIL_FILES[@]} échoué(s)"

  if [[ ${#FAIL_FILES[@]} -gt 0 ]]; then
    echo "Fichiers échoués :"
    for f in "${FAIL_FILES[@]}"; do
      echo "  - $f"
    done
  fi
}