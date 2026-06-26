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

# Uploader un fichier
./main.sh /chemin/vers/fichier.tar.gz

# Uploader plusieurs fichiers
./main.sh /chemin/vers/fichier1.tar.gz /chemin/vers/fichier2.tar.gz

# Les noms de fichiers avec espaces doivent être entre guillemets
./main.sh "/chemin/vers/mon fichier.tar.gz"
```

---

## Ce que fait le script

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

la variable `FILESTOKEEP` dans main.sh permet de mettre en place une rotation des fichiers avec un nombre customisable

> :warning: **si vous transférez plus d'un fichier**: l'implémentation actuelle ne fera pas un bon travail

### Conteneurisation

Un dockerfile est disponible pour faire un upload dans un conteneur , les variables peuvent être sourcées ou transmises de façon offusquée si c'est lancé par Jenkins par exemple


```bash
#build the image from inside the repo
docker build . -t pclouduploader:v0 #<10s

docker run --rm \
  -e PCLOUDUSER=$PCLOUDUSER \
  -e PCLOUDPASS=$PCLOUDPASS \
  -v /sourceFileDirectory:/backups:ro \
  pclouduploader:v0 \
  /backups/fileToUpload.tar.gz
```


### Utilisation avec jenkins

je prevois de me service de cette dynamique via Jenkins , un fichier compose est present

Pour l'auth Tailscale au premier démarrage :

```bash
docker compose up -d
docker exec tailscale tailscale up
# → colle le lien affiché dans ton navigateur
```

Une fois authentifié l'état est persisté dans ./tailscale-state


---

## Structure

```
pcloud-backup/
├── main.sh                ← point d'entrée, boucle sur les arguments
├── functions.sh           ← fonctions login / upload / logout
├── Dockerfile             ← permet d'en faire un conteneur
├── Docker-compose.yml     ← compose pour jenkins
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
- [ ] POC cron sur dockerhost `in progress`
- [ ] Pipeline Jenkins