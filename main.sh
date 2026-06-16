# main.sh
#!/bin/bash

ENV_FILE="../homelab/.secret/pcloud.env" #<-- fichier d'environnement contenant les variables d'environnement nécessaires
#PCLOUDUSER=
#PCLOUDPASS=
source "$ENV_FILE"
source functions.sh

if [ $# -lt 1 ]; then
    echo "No file provided. Exiting."
    exit 1

else 
    login
    get_quota
    TOTAL=$#
    COUNT=0
    SUCCESS_FILES=()
    FAIL_FILES=()
    for f in "$@"; do
        COUNT=$((COUNT + 1))
        echo "Transferring file $COUNT/$TOTAL"
        FILESIZE=$(du -b "$f" | cut -f1)
        if [ $FILESIZE -gt $FREEQUOTA ]; then
            FILESIZE_MB=$(( FILESIZE / 1024 / 1024 ))
            echo "File $f is too large to upload ($FILESIZE_MB MB). Skipping."
            FAIL_FILES+=("$f")
            continue
        fi
        upload "$f"
        if [ $? -eq 0 ]; then
            SUCCESS_FILES+=("$f")
            FREEQUOTA=$((FREEQUOTA - FILESIZE))
        else
            FAIL_FILES+=("$f")
        fi
    done
    echo "Upload terminé : ${#SUCCESS_FILES[@]} OK, ${#FAIL_FILES[@]} échoué(s)"

    if [ ${#FAIL_FILES[@]} -gt 0 ]; then
        echo "Fichiers échoués :"
        for f in "${FAIL_FILES[@]}"; do
            echo "  - $f"
        done
    fi
    get_quota
    logout
fi


