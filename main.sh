# main.sh
#!/bin/bash
set -euo pipefail
ENV_FILE="../homelab/.secret/pcloud.env" #<-- fichier d'environnement contenant les variables d'environnement nécessaires
#PCLOUDUSER=
#PCLOUDPASS=
source "$ENV_FILE"
source functions.sh

: ${LOCAL_FILE:?"LOCAL_FILE est obligatoire"} #le check avant même d'appeler les fonctions

login
upload "$LOCAL_FILE"
logout
