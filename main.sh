# main.sh
#!/bin/bash
set -euo pipefail

source ../homelab/.secret/pcloud.env
source functions.sh

login
upload "$1"
logout