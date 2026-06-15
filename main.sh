# main.sh
#!/bin/bash
#set -euo pipefail on enlève ca car on le veut pas que le script s'arrête si une commande échoue, on veut juste afficher l'erreur et continuer
ENV_FILE="../homelab/.secret/pcloud.env" #<-- fichier d'environnement contenant les variables d'environnement nécessaires
#PCLOUDUSER=
#PCLOUDPASS=
source "$ENV_FILE"
source functions.sh

#: ${LOCAL_FILE:?"LOCAL_FILE est obligatoire"} #le check avant même d'appeler les fonctions

if [ $# -lt 1 ]; then
    echo "No arguments provided. Exiting."
    exit 1

else 
    login
    TOTAL=$#
    COUNT=0
    for f in "$@"; do
        COUNT=$((COUNT + 1))
        echo "Transferring file $COUNT/$TOTAL"
        upload "$f"
    done
    logout
fi


