#!/bin/bash 
#input argument: path to the folder to compare with pCloud

[[ ${#} -eq 1 ]] && [[ -d "${1}" ]] || : ${EXCEPTION:?"Chemin non fourni ou trop d'arguments. EXCEPTION !!!!."}

ENV_FILE="../homelab/.secret/pcloud.env" #<-- fichier d'environnement contenant les variables d'environnement nécessaires
[ -f "${ENV_FILE}" ] && source "${ENV_FILE}"  # source si présent, sinon on suppose que les vars arrivent de l'environnement Docker
source functions.sh || : ${EXCEPTION:?"functions.sh: illisible ou absent"}

: ${PCLOUDUSER:?variable non definie}  # vérifie après le source, peu importe d'où vient la variable
: ${PCLOUDPASS:?variable non definie}

: ${FOLDERID:=24924892347} #<-- dossier de destination sur pCloud
echo "Dossier de destination sur pCloud: ${FOLDERID}"

TRIMMEDPATH=$(echo "${1}" | sed 's:/*$::') #retire le / si présent à la fin du chemin

find "${TRIMMEDPATH}" -maxdepth 1 -type f | xargs -I{} basename {} | sort | tail -n "${RETENTION_DAYS:-3}" | sed '/^$/d' > local

login
get_quota
list_folder
for f in "${FILESPRESENT[@]}"; do
    echo "$f" | cut -d ':' -f 1 >> remote
done

# les fichiers à supprimer sont ceux qui sont dans remote mais pas dans local
arraytd="$(comm -13 local remote)"

if [[ -n "${arraytd}" ]]; then
    FILEDTODELETE=()
    readarray -t FILEDTODELETE <<< "${arraytd}"
    for f in "${FILEDTODELETE[@]}"; do
        echo "Suppression des fichier non présents en local: $f"
        # retrouver la paire nom:fileid dans FILESPRESENT
        for pair in "${FILESPRESENT[@]}"; do
            if [[ "${pair%%:*}" == "$f" ]]; then
                delete_file "${pair}"
                break
            fi
        done
    done
    empty_trash
    get_quota
else
    echo "Rien a supprimer."
fi



readarray -t FILESTOUPLOAD < <(comm -23  local remote | sed "s|^|${1}/|")

if [[ ${#FILESTOUPLOAD[@]} -eq 0 ]]; then
    echo "Rien a uploader."
    logout
    exit 0
else
    multiple_upload "${FILESTOUPLOAD[@]}"
fi

get_quota
list_folder
logout
