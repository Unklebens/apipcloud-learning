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

---

## Structure

```
pcloud-backup/
├── main.sh         ← point d'entrée, boucle sur les arguments
├── functions.sh    ← fonctions login / upload / logout
└── README.md
```

---

## Roadmap

- [x] Auth pCloud via API REST avec curl
- [x] Upload avec suivi de progression temps réel
- [x] Gestion des erreurs curl et codes retour pCloud
- [x] Paramétrage par variables d'environnement
- [x] Upload de plusieurs fichiers en arguments
- [ ] Containerisation avec `curlimages/curl`
- [ ] POC cron sur dockerhost
- [ ] Pipeline Jenkins