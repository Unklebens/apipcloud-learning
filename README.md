# pcloud-backup

Scripts shell pour uploader un ou plusieurs fichiers vers pCloud via leur API REST, avec suivi de progression en temps réel.

Projet d'apprentissage DevOps — API REST, curl, bash, containers éphémères, Jenkins.

---

## Prérequis

- `bash`
- `curl`
- `jq`
- Un compte pCloud (région EU)

---

## Configuration

Créer un fichier d'environnement **hors du repo** :

```bash
mkdir -p ~/.secret
cat > ~/.secret/pcloud.env << 'EOF'
PCLOUDUSER=votre@email.com
PCLOUDPASS=votremotdepasse
EOF
chmod 600 ~/.secret/pcloud.env
```

Adapter le chemin dans `main.sh` si nécessaire :

```
ENV_FILE="../homelab/.secret/pcloud.env"
```

> ⚠️ Ne jamais committer ce fichier. Vérifier que `.gitignore` contient `*.env`.

---

## Utilisation

```bash
# Rendre le script exécutable
chmod +x main.sh

# Sourcer le fichier d'.env (source en bash mais . ~/.secret/pcloud.env en sh via cron)
source ~/.secret/pcloud.env 

# Synchroniser un dossier
./main.sh /chemin/vers/dossier

```

---

## Ce que fait le script V1

```
login()   → authentification pCloud → token de session
upload()  → upload du fichier avec suivi de progression en temps réel
logout()  → invalidation du token
```

Un seul login/logout pour tous les fichiers. La boucle affiche la progression globale :

```
Transferring file 1/2
transfering backup_20260614.tar.gz : a1b2c3d4-...
Upload progress: 12% (734/6144 MB)
Upload progress: 28% (1720/6144 MB)
...
Upload OK → fileid: 92281279695
Transferring file 2/2
...
```

### Sync miroir (compare.sh) V2

Synchronise les N derniers fichiers d'un dossier local avec un dossier pCloud.
Compare les deux états et décide quoi uploader et quoi supprimer.

```bash
chmod +x compare.sh
./compare.sh /chemin/vers/dossier
```

- Conserve les 3 derniers fichiers du dossier local (tri alphabétique — format `YYYY-MM-DD` requis)
- Supprime les fichiers présents sur pCloud mais absents de la sélection locale
- Uploade les fichiers manquants sur pCloud
- `FOLDERID` à configurer dans `compare.sh`

### Conteneurisation

Un dockerfile est disponible pour faire un upload dans un conteneur , les variables peuvent être sourcées ou transmises de façon offusquée si c'est lancé par Jenkins par exemple


```bash
#build the image from inside the repo
docker build . -t pclouduploader:v0 #<10s

docker run --rm \
  -e PCLOUDUSER=$PCLOUDUSER \
  -e PCLOUDPASS=$PCLOUDPASS \
  -v /sourceDirectory:/backups:ro \
  pclouduploader:v2 \
  /backups
```


### Utilisation avec jenkins

je prevois de me service de cette dynamique via Jenkins , un fichier compose est present

Pour l'auth Tailscale au premier démarrage si la TSAUTHKEY n'est dans le compose directement:

```bash
docker compose up -d
docker exec tailscale tailscale up
# → colle le lien affiché dans ton navigateur
#Une fois authentifié l'état est persisté dans ./tailscale-state
```




Un jenkinsfile fonctionnel est aussi dispo, attention le paramètre doit contenir l'extension du fichier

---

## Structure

```
pcloud-backup/
├── compare.sh             ← sync miroir entre un dossier local et pCloud
├── main.sh                ← ancien point d'entrée, boucle sur les arguments
├── functions.sh           ← fonctions login / upload / logout
├── Dockerfile             ← permet d'en faire un conteneur
├── Docker-compose.yml     ← compose pour jenkins
├── Jenkinsfile            ← pour faire l'upload/sync via jenkins
└── README.md
```

---

## Roadmap

- [x] Auth pCloud via API REST avec curl
- [x] Upload avec suivi de progression temps réel
- [x] Gestion des erreurs curl et codes retour pCloud
- [x] Paramétrage par variables d'environnement
- [x] Upload de plusieurs fichiers en arguments
- [x] Containerisation avec `alpine`
- [x] POC cron sur dockerhost 
- [x] Pipeline Jenkins
