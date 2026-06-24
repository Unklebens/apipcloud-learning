#!/bin/bash 
# main.sh

ENV_FILE="../homelab/.secret/pcloud.env" #<-- fichier d'environnement contenant les variables d'environnement nécessaires
[ -f "${ENV_FILE}" ] && source "${ENV_FILE}"  # source si présent, sinon on suppose que les vars arrivent de l'environnement Docker
source functions.sh || : ${EXCEPTION:?"functions.sh: illisible ou absent"}

: ${PCLOUDUSER:?variable non definie}  # vérifie après le source, peu importe d'où vient la variable
: ${PCLOUDPASS:?variable non definie}

[[ ${#} -ge 1 ]] || : ${EXCEPTION:?"No file provided. Exiting."}

FOLDERID=24924892347 #<-- dossier de destination sur pCloud
FILESTOKEEP=3

login
get_quota
list_folder
TOTAL=${#}
COUNT=0
SUCCESS_FILES=()
FAIL_FILES=()

#purge
[[ "${FILECOUNT}" -gt $(( "${FILETOKEEP}" - 1 )) ]] && delete_file "${FILESPRESENT[0]}"

for f; do # parcours les parametres
  COUNT=$((COUNT + 1))
  echo "Transferring file $COUNT/$TOTAL"
  FILESIZE="$(du -b "$f" | cut -f1)"
  if [[ ${FILESIZE} -gt ${FREEQUOTA:?variable non définie} ]]; then
    FILESIZE_MB=$(( $FILESIZE / 1024 / 1024 ))
    echo "File ${f} is too large to upload (${FILESIZE_MB} MB). Skipping."
    FAIL_FILES+=("${f}")
    continue
  fi
  upload "${f}"
  if [[ ${?} -eq 0 ]]; then
    SUCCESS_FILES+=("${f}")
    FREEQUOTA=$(( $FREEQUOTA - $FILESIZE ))
   else
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
get_quota
list_folder
logout
