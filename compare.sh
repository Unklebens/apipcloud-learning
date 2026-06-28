#!/bin/bash 

[[ ${#} -eq 1 ]] && [[ -d "${1}" ]] || : ${EXCEPTION:?"Chemin non fourni ou trop d'arguments. EXCEPTION !!!!."}

ENV_FILE="../homelab/.secret/pcloud.env" #<-- fichier d'environnement contenant les variables d'environnement nécessaires
[ -f "${ENV_FILE}" ] && source "${ENV_FILE}"  # source si présent, sinon on suppose que les vars arrivent de l'environnement Docker
source functions.sh || : ${EXCEPTION:?"functions.sh: illisible ou absent"}
FOLDERID=24924892347 #<-- dossier de destination sur pCloud

find "${1}" -maxdepth 1 -type f -printf '%f\n' | sort | tail -n 3 | sed '/^$/d' > local

login
get_quota
list_folder
for f in "${FILESPRESENT[@]}"; do
    echo "$f" | cut -d ':' -f 1 >> remote
done

# les fichiers à supprimer sont ceux qui sont dans remote mais pas dans local
arraytd="$(comm -13 --nocheck-order local remote)"

if [[ -n "${arraytd}" ]]; then
    FILEDTODELETE=()
    readarray -t FILEDTODELETE <<< "${arraytd}"
    for f in "${FILEDTODELETE[@]}"; do
        echo "Deleting file not needed on pcloud: $f"
        # retrouver la paire nom:fileid dans FILESPRESENT
        for pair in "${FILESPRESENT[@]}"; do
            if [[ "${pair%%:*}" == "$f" ]]; then
                delete_file "${pair}"
                break
            fi
        done
    done
else
    echo "No files to delete."
fi



readarray -t FILESTOUPLOAD < <(comm -23 --nocheck-order local remote | sed "s|^|${1}/|")

if [[ -z "${FILESTOUPLOAD}" ]]; then
    echo "No new files to upload."
    logout
    exit 0
else
    source main.sh "${FILESTOUPLOAD[@]}"
fi

