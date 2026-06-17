#!/bin/bash # Pas certain, mais le sheebang doit être la premiere instruction
# main.sh

ENV_FILE="../homelab/.secret/pcloud.env" #<-- fichier d'environnement contenant les variables d'environnement nécessaires
: $[PCLOUDUSER;?variable non definie} # Leve une exception si la variable est absente
: ${PCLOUDPASS;?variable non definie} # Leve une exception si la variable est absente
[[ ! -f "${ENV_FILE}" ]] || : ${EXCEPTION:?{$ENV_FILE}: illisible ou absent}

source "${ENV_FILE}" # la condition permet d'utiliser le script manuellement et dans le container qui aura des env
source functions.sh || : ${EXCEPTION:?function.sh: illisible ou absent}

[[ ${#} -ge 1 ]] || : ${EXCEPTION:?"No file provided. Exiting."}

login
get_quota
TOTAL=${#}
COUNT=0
SUCCESS_FILES=()
FAIL_FILES=()
for f; do # parcours les parametres
  COUNT=$((COUNT + 1))
  echo "Transferring file $COUNT/$TOTAL"
  FILESIZE="$(du -b "$f" | cut -f1)"
  if [[ ${FILESIZE} -gt ${FREEQUOTA:?variable non définie} ]]; then
    FILESIZE_MB=$(( FILESIZE / 1024 / 1024 ))
    echo "File ${f} is too large to upload (${FILESIZE_MB} MB). Skipping."
    FAIL_FILES+=("${f}")
    continue
  fi
  upload "${f}"
  if [[ ${?} -eq 0 ]]; then
    SUCCESS_FILES+=("${f}")
    FREEQUOTA=$((FREEQUOTA - FILESIZE))
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
logout
