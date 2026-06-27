# creation de l'user jenkins sur dockerhost

`sudo useradd -m -s /bin/bash jenkins --group docker`

---

# Certificats

Sur VM101 (dockerhost), dans un dossier temporaire :
```bash
mkdir ./docker-tls && cd ./docker-tls
```

## 1. CA

```bash
openssl genrsa -aes256 -out ca-key.pem 4096
openssl req -new -x509 -days 3650 -key ca-key.pem -sha256 -out ca.pem \
  -subj "/CN=docker-ca"
```

## 2. Clé + CSR serveur

```bash
openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=dockerhost.tail358360.ts.net" \
  -sha256 -new -key server-key.pem -out server.csr
```
## 3. SAN — important : inclure l'IP LAN et l'IP Tailscale

```bash
echo "subjectAltName = DNS:dockerhost.tail358360.ts.net,DNS:dockerhost,IP:192.168.104.35,IP:127.0.0.1" > extfile.cnf
echo "extendedKeyUsage = serverAuth" >> extfile.cnf

openssl x509 -req -days 3650 -sha256 \
  -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
  -out server-cert.pem -extfile extfile.cnf
```
## 4. Clé + CSR client

```bash
openssl genrsa -out key.pem 4096
openssl req -subj '/CN=client' -new -key key.pem -out client.csr
echo "extendedKeyUsage = clientAuth" > extfile-client.cnf
openssl x509 -req -days 3650 -sha256 \
  -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
  -out cert.pem -extfile extfile-client.cnf
```
Ensuite placer les certs serveur :

```bash
sudo mkdir -p /etc/docker/certs
sudo cp ca.pem server-cert.pem server-key.pem /etc/docker/certs/
sudo chmod 600 /etc/docker/certs/server-key.pem
```

Configurer le daemon Docker (/etc/docker/daemon.json) :

```json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"],
  "tls": true,
  "tlscacert": "/etc/docker/certs/ca.pem",
  "tlscert": "/etc/docker/certs/server-cert.pem",
  "tlskey": "/etc/docker/certs/server-key.pem",
  "tlsverify": true
}
```


```bash
root@dockerhost:~# cat /etc/docker/daemon.json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2376"],
  "tls": true,
  "tlscacert": "/etc/docker/certs/ca.pem",
  "tlscert": "/etc/docker/certs/server-cert.pem",
  "tlskey": "/etc/docker/certs/server-key.pem",
  "tlsverify": true,
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    }
}
```
Redémarrer Docker :
```bash
sudo systemctl restart docker
```

juin 27 16:16:06 dockerhost dockerd[1504828]: unable to configure the Docker daemon with file /etc/docker/daemon.json: the following directives are specified both as a flag and in the configuration file: hosts: (from flag: [fd://], from file: [unix:///var/run/docker.sock tcp://0.0.0.0:2376])


Le problème vient du systemd unit de Docker qui passe déjà -H fd:// en flag. Les deux entrent en conflit avec le hosts dans daemon.json.

Il faut override le service systemd pour retirer ce flag :

```bash
sudo nano /etc/systemd/system/docker.service.d/override.conf
Contenu du fichier :

ini
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
```

La première ligne ExecStart= vide la valeur existante (sinon systemd concatene), la deuxième redéfinit sans le flag -H fd://.

Ensuite :

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

Les trois fichiers à récupérer pour Jenkins (côté client) :

```bash
ca.pem
cert.pem
key.pem
```

Jenkins → Manage Jenkins → Credentials → System → Global credentials → Add Credentials
Tu choisis le type "X.509 Client Certificate" (ou "Docker Host Certificate Authentication" selon la version du plugin), et tu colles :

cert.pem → Client Certificate
key.pem → Client Key
ca.pem → Server CA Certificate