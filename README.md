![Schéma architecture](./Sans titre2.png)

# Jour 1 - Introduction et prise en main AWS

> On se met dans la peau d'un utilisateur. On va faire des erreurs/actions volontaires qui auront des répercussions par la suite.

## 1 - Lancement du lab

- Lancer le lab
- Montrer l'access key et la clé SSH à télécharger

## 2 - Rappel IAM

- Rappel IAM et lien avec ce qu'on a vu (on ne peut pas le faire sur Learner Lab)
- Mais expliquer : création user/group + policies (qu'est-ce que je peux faire ?)

## 3 - Création d'une instance EC2

- Création manuelle d'une instance EC2 Ubuntu avec la clé `vockey`
- Cocher SSH / HTTP / HTTPS dans les règles de sécurité

### 3bis - Security Groups

- Montrer les Security Groups dans la console AWS
- Expliquer les règles Inbound / Outbound
- Montrer que SSH, HTTP et HTTPS sont autorisés (cochés à l'étape 3)
- Faire le lien avec le scan Nmap qui viendra plus tard

### 3ter - Premier test de connexion SSH

```bash
chmod 400 vockey.pem
ssh -i vockey.pem ubuntu@<IP_VM2>
# S'assurer que ça marche avant d'aller plus loin
```

---

# Jour 2 - Ansible et Hardening

## Architecture

```
┌─────────────────┐         SSH          ┌─────────────────┐
│   VM1 (Control) │ ──────────────────>  │ VM2 (Managed)   │
│  - Ansible      │    avec vockey.pem   │  - Target       │
│  - Terraform    │                      │  - Nginx        │
└─────────────────┘                      └─────────────────┘
```

## 4 - Installation d'Ansible (sur VM1)

```bash
sudo apt update
sudo apt install python3 python3-pip git
sudo pip3 install ansible --break-system-packages
```

## Fichier d'inventaire (`hosts`)

```ini
[servers]
ma-vm2 ansible_host=44.201.65.186 ansible_user=ubuntu
```

## 5 - Test de connexion Ansible

Avant de lancer le playbook, tester la connexion :

```bash
ansible ma-vm2 -i hosts -m ping --private-key=./vockey.pem --ssh-common-args='-o StrictHostKeyChecking=no'
```

## Playbook de mise à jour (`playbook.yml`)

```yaml
---
- name: Mise à jour des paquets avec apt
  hosts: ma-vm2
  become: yes

  tasks:
    - name: Mettre à jour le cache apt
      apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Mettre à jour tous les paquets
      apt:
        upgrade: dist
        autoremove: yes
        autoclean: yes
```

## Lancement du playbook

```bash
ansible-playbook playbook.yml -i hosts --private-key=./vockey.pem --ssh-common-args='-o StrictHostKeyChecking=no'
```

## Hardening avec Lynis

### Sur VM2 - Audit manuel

```bash
git clone https://github.com/CISOfy/lynis
cd lynis && ./lynis audit system
```

- Choisir 2 points à durcir et les corriger manuellement
- Relancer le scan pour vérifier
- Ce processus est correct pour 1 VM, mais fastidieux si on en a plusieurs

### Sur VM1 - Hardening automatisé avec Ansible

- Écrire un playbook pour durcir 2 autres points
- Lancer le playbook, puis se connecter à la VM2 et relancer le scan pour vérifier

> **Discussion** : moins d'intervention humaine = moins d'erreurs possibles

---

# Jour 3 - Nmap, Terraform et outils de scan

## Nmap

### Règles du Security Group de la VM cible (que les élèves vont scanner)

#### Ports standards

| Protocole | Port | Service | Source |
|-----------|------|---------|--------|
| TCP | 22 | SSH | 0.0.0.0/0 |
| TCP | 80 | HTTP | 0.0.0.0/0 |
| TCP | 443 | HTTPS | 0.0.0.0/0 |
| TCP | 25 | SMTP | 0.0.0.0/0 |
| TCP | 993 | IMAPS | 0.0.0.0/0 |
| TCP | 445 | SMB | 0.0.0.0/0 |
| ICMP | All | ICMP IPv4 | 0.0.0.0/0 |

#### DNS

| Protocole | Port | Service | Source |
|-----------|------|---------|--------|
| UDP | 53 | DNS | 0.0.0.0/0 |
| TCP | 53 | DNS | 0.0.0.0/0 |

#### Base de données

| Protocole | Port | Service | Source |
|-----------|------|---------|--------|
| TCP | 9142 | Cassandra/CQLSH | 0.0.0.0/0 |

#### Ports personnalisés

| Protocole | Port | Usage | Source |
|-----------|------|-------|--------|
| TCP | 60011 | Custom | 0.0.0.0/0 |
| TCP | 7645 | Custom | 0.0.0.0/0 |
| TCP | 4576 | Custom | 0.0.0.0/0 |
| UDP | 7712 | Custom | 0.0.0.0/0 |
| UDP | 5555 | Custom | 0.0.0.0/0 |
| UDP | 59879 | Custom | 0.0.0.0/0 |

> **Note de securite** : toutes les regles autorisent le trafic depuis n'importe quelle IP (0.0.0.0/0). Pensez a restreindre l'acces aux IPs necessaires pour ameliorer la securite.

### Scan Nmap (depuis VM1)

```bash
sudo nmap -sS -sU -p- <IP_CIBLE>
```

### TP Nmap:

1. Détecter le type d'OS
2. Réponse au ping ou pas ? Justifié ou pas ? Sécurisé ou pas ?
3. Scan des ports
4. Produire un petit compte-rendu


### Installation de Nginx (sur VM2)

```bash
sudo apt install nginx
sudo systemctl start nginx
```

- Retourner sur VM1, relancer le scan et observer le port 80 ouvert
- Tester l'accès à l'IP de la VM2 depuis un navigateur web
- Constat : problème de sécurité, le serveur web est exposé

---

## Terraform

> **Message cle** : "Automatiser = Securiser"

### Installation (sur VM1)

```bash
snap install terraform --classic
```

### Fichiers de configuration

Voir le dossier dédié.

---

## ZAP (OWASP ZAP)

Outil pour le test de sécurité web.

### Serveur web volontairement vulnérable (DVWA)

```bash
docker run -d --name dvwa -p 80:80 vulnerables/web-dvwa
```

---

## Trivy

### Installation

```bash
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

### Exemples de scans

```bash
# Scanner le répertoire de l'application web
trivy fs /var/www/html

# Scanner les dépendances (Python, Node.js, etc.)
trivy fs --scanners vuln,misconfig /chemin/vers/projet

# Scanner le système entier
trivy rootfs /

# Scanner le système entier avec rapport HTML
wget https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl
trivy rootfs --format template --template "@html.tpl" -o report.html /
```

---

# Jour 4 - Nginx HTTPS, ssh-audit et TP

## Configuration Nginx avec HTTPS

### Installation et génération du certificat

```bash
sudo apt update && sudo apt install nginx -y && sudo systemctl enable nginx && sudo systemctl start nginx

sudo mkdir -p /etc/nginx/ssl

sudo openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
  -keyout /etc/nginx/ssl/server.key \
  -out /etc/nginx/ssl/server.crt \
  -subj "/C=FR/ST=State/L=City/O=Organization/CN=127.0.0.1"

sudo chmod 600 /etc/nginx/ssl/server.key
sudo chmod 644 /etc/nginx/ssl/server.crt
```

### Configuration du vhost (`/etc/nginx/sites-available/default`)

```nginx
# Bloc HTTP - Redirection vers HTTPS
server {
    listen 80;                          # Écoute sur le port 80 (HTTP) en IPv4
    listen [::]:80;                     # Écoute sur le port 80 (HTTP) en IPv6
    server_name votredomaine.com;       # Nom de domaine ou IP du serveur

    return 301 https://$host$request_uri;  # Redirige tout le trafic HTTP vers HTTPS
}

# Bloc HTTPS - Configuration principale
server {
    listen 443 ssl;                     # Écoute sur le port 443 (HTTPS) en IPv4 avec SSL
    listen [::]:443 ssl;                # Écoute sur le port 443 (HTTPS) en IPv6 avec SSL
    server_name votredomaine.com;       # Nom de domaine ou IP du serveur

    # Certificats SSL
    ssl_certificate /etc/nginx/ssl/server.crt;      # Certificat SSL public
    ssl_certificate_key /etc/nginx/ssl/server.key;  # Clé privée SSL

    # Paramètres SSL recommandés
    ssl_protocols TLSv1.2 TLSv1.3;      # Protocoles autorisés (TLS 1.2 et 1.3 uniquement)
    ssl_ciphers HIGH:!aNULL:!MD5;       # Chiffrements forts, exclut les faibles (aNULL, MD5)
    ssl_prefer_server_ciphers on;       # Le serveur choisit le cipher, pas le client

    # En-têtes de sécurité
    add_header Strict-Transport-Security "max-age=31536000" always;  # Force HTTPS pendant 1 an (HSTS)
    add_header X-Frame-Options "SAMEORIGIN" always;                  # Anti-clickjacking
    add_header X-Content-Type-Options "nosniff" always;              # Empêche le MIME sniffing

    # Racine du site
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # Si vous avez ModSecurity (WAF)
    # modsecurity on;
    # modsecurity_rules_file /etc/nginx/modsec/main.conf;
}
```

### Validation et redémarrage

```bash
sudo nginx -t
sudo systemctl restart nginx
```

### Résumé des sections

| Section | Rôle |
|---------|------|
| **Bloc port 80** | Redirige HTTP vers HTTPS |
| **Bloc port 443** | Sert le site en HTTPS sécurisé |
| **ssl_*** | Configuration du chiffrement TLS |
| **add_header** | Protection contre les attaques web courantes |
| **location /** | Gestion des requêtes et fichiers statiques |



---

## ssh-audit

```bash
sudo apt install ssh-audit
ssh-audit <IP_CIBLE>
```
### ssh-audit, Lynis et référentiel ANSSI TP FINAL

**Objectifs** :

- Scanner avec ssh-audit + Lynis + référentiel ANSSI
- Proposer un fichier de configuration `sshd_config` conforme aux recommandations
- Le faire manuellement, et si possible avec Ansible

**Référence** : [Guide ANSSI - Configuration Linux](https://messervices.cyber.gouv.fr/documents-guides/fr_np_linux_configuration-v2.0.pdf)


