# pcloud-backup

Scripts shell pour uploader un fichier vers pCloud via leur API REST, avec suivi de progression en temps réel.

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

```bash
ENV_FILE="../homelab/.secret/pcloud.env"
```

> ⚠️ Ne jamais committer ce fichier. Vérifier que `.gitignore` contient `*.env`.

---

## Utilisation

```bash
# Rendre les scripts exécutables
chmod +x main.sh

# Lancer un upload
LOCAL_FILE=/chemin/vers/fichier.tar.gz ./main.sh
```

Ou en exportant la variable :

```bash
export LOCAL_FILE=/chemin/vers/fichier.tar.gz
./main.sh
```

---

## Ce que fait le script

```
login()   → authentification pCloud → token de session
upload()  → upload du fichier avec suivi de progression en temps réel
logout()  → invalidation du token
```

La progression s'affiche toutes les 2 secondes via l'endpoint `uploadprogress` de l'API pCloud :

```
transfering backup_20260614.tar.gz : a1b2c3d4-...
Upload progress: 12% (734/6144 MB)
Upload progress: 28% (1720/6144 MB)
...
Upload OK → fileid: 92281279695
```

---

## Structure

```
pcloud-backup/
├── main.sh         ← point d'entrée
├── functions.sh    ← fonctions login / upload / logout
└── README.md
```

---

## Roadmap

- [x] Auth pCloud via API REST avec curl
- [x] Upload avec suivi de progression temps réel
- [x] Gestion des erreurs curl et codes retour pCloud
- [x] Paramétrage par variables d'environnement
- [ ] Containerisation avec `curlimages/curl`
- [ ] POC cron sur dockerhost
- [ ] Pipeline Jenkins

