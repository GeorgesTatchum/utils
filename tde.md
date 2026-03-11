# Transparent data encryption

## spécification
- définir ce que c'est qu'une opération de chiffrement de données à froid de mariadb

- donner le liens vers la documentation officielle par rapport à cela

- donner l'ensemble des fonctionnalités liées à cela

- Donner le processus de mise en place pour des cas de serveur en production

---

## 1. Définition : Chiffrement des données à froid (Data-at-Rest Encryption / TDE) de MariaDB

Le **chiffrement des données au repos** (*Data-at-Rest Encryption*), aussi appelé **TDE** (*Transparent Data Encryption*), est une fonctionnalité de MariaDB qui permet de **chiffrer les fichiers de données stockés sur le disque** de manière transparente pour les applications.

> **Contexte** : Chaque client dispose de **son propre serveur dédié**, tournant soit sous **Windows Server**, soit sous **Linux**. MariaDB est installé dans un chemin identique sur chaque serveur : **`C:\Sites\outils`** (Windows) / **`/Sites/outils`** (Linux). Chaque commande, chemin et recommandation est déclinée pour les deux OS.

### Principe

- Les données sont chiffrées **avant d'être écrites sur le disque** et déchiffrées **lorsqu'elles sont lues en mémoire**.
- L'opération est **transparente** : les applications et les requêtes SQL n'ont aucune modification à subir. Le chiffrement/déchiffrement est géré entièrement par le moteur de stockage.
- Le terme **« à froid »** signifie que la protection porte sur les **données telles qu'elles existent sur le support physique** (disques, sauvegardes, snapshots). Si un attaquant obtient un accès au système de fichiers, aux disques physiques ou à une copie de sauvegarde, il ne pourra **pas lire les données** sans la clé de chiffrement.
- TDE garantit que même si quelqu'un accède aux fichiers `.ibd` sur le disque du serveur d'un client, les données restent illisibles sans la clé de chiffrement.

### Ce qui est protégé

| Élément | Chiffré ? |
|---|---|
| Fichiers tablespace InnoDB / XtraDB (.ibd) | **Oui** |
| Tablespace système InnoDB (ibdata1) | **Oui** (optionnel) |
| Logs redo InnoDB (ib_logfile*) | **Oui** (optionnel) |
| Tables Aria (.MAD, .MAI) | **Oui** |
| Logs binaires / relay logs | **Oui** (depuis MariaDB 10.1.7) |
| General log / Slow query log (fichier) | Non |
| Données en transit (réseau) | Non (nécessite SSL/TLS) |
| Données en mémoire (buffer pool) | Non |

### Ce qui n'est PAS protégé

- Les données **en mémoire** (buffer pool, caches).
- Les données **en transit sur le réseau** (utiliser TLS/SSL pour cela).
- Un utilisateur disposant d'un **accès `root` au SGBD** peut toujours lire les données via des requêtes SQL — TDE ne remplace pas le contrôle d'accès applicatif.

### Algorithme de chiffrement

- MariaDB utilise **AES** (*Advanced Encryption Standard*) avec des clés de **128, 192 ou 256 bits**.
- Mode de chiffrement par défaut : **AES-CBC** (Cipher Block Chaining). Le mode **AES-CTR** est aussi supporté (recommandé pour de meilleures performances sur CPU supportant AES-NI).

---

## 2. Liens vers la documentation officielle

| Sujet | Lien |
|---|---|
| **Vue d'ensemble — Data-at-Rest Encryption** | https://mariadb.com/kb/en/data-at-rest-encryption-overview/ |
| **Encryption Key Management** (gestionnaires de clés) | https://mariadb.com/kb/en/encryption-key-management/ |
| **Plugin File Key Management** | https://mariadb.com/kb/en/file-key-management-encryption-plugin/ |
| **Plugin AWS Key Management** | https://mariadb.com/kb/en/aws-key-management-encryption-plugin/ |
| **Plugin Hashicorp Key Management** | https://mariadb.com/kb/en/hashicorp-key-management-plugin/ |
| **InnoDB / XtraDB Encryption** | https://mariadb.com/kb/en/innodb-encryption/ |
| **Aria Encryption** | https://mariadb.com/kb/en/aria-encryption/ |
| **Encrypting Binary Logs** | https://mariadb.com/kb/en/encrypting-binary-logs/ |
| **Encrypting Temporary Files** | https://mariadb.com/kb/en/encrypting-temporary-files/ |
| **innodb_encrypt_tables** (variable système) | https://mariadb.com/kb/en/innodb-system-variables/#innodb_encrypt_tables |
| **innodb_encrypt_log** (variable système) | https://mariadb.com/kb/en/innodb-system-variables/#innodb_encrypt_log |

---

## 3. Ensemble des fonctionnalités liées au chiffrement au repos

### 3.1 Plugins de gestion de clés

MariaDB utilise une architecture à **plugins** pour la gestion des clés de chiffrement :

| Plugin | Description |
|---|---|
| **file_key_management** | Lit les clés depuis un fichier texte chiffré sur le disque local. Simple à configurer, adapté pour des environnements limités. |
| **aws_key_management** | Intégration avec **AWS KMS** (Key Management Service). Les clés sont générées et stockées par AWS, protégées par leur infrastructure. |
| **hashicorp_key_management** | Intégration avec **HashiCorp Vault**. Gestion centralisée et rotation de clés via Vault. |
| **eperi Gateway** | Solution tierce de chiffrement via passerelle. |
| Plugin personnalisé | MariaDB expose une API permettant de développer son propre plugin de gestion de clés. |

### 3.2 Chiffrement des tablespaces InnoDB/XtraDB

- **`innodb_encrypt_tables`** : `OFF` / `ON` / `FORCE`
  - `ON` : chiffre les nouvelles tables par défaut, les tables existantes sont chiffrées en arrière-plan.
  - `FORCE` : interdit la création de tables non chiffrées.
- **`innodb_encrypt_log = ON`** : chiffre les redo logs InnoDB.
- **`innodb_encryption_threads`** : nombre de threads dédiés au chiffrement/déchiffrement en arrière-plan (rotation de clés, chiffrement des tables existantes).
- **`innodb_encryption_rotate_key_age`** : fonctionne avec les plugins KMS (AWS, HashiCorp) qui gèrent le versioning interne des clés. Avec `file_key_management`, la rotation se fait par **changement de `key_id`** (voir Section 5).

### 3.3 Chiffrement des tables Aria

- **`aria_encrypt_tables = ON`** : active le chiffrement des tables utilisant le moteur Aria (utilisé par les tables temporaires internes).
- Protège les données temporaires manipulées lors de `GROUP BY`, `ORDER BY`, sous-requêtes, etc.

### 3.4 Chiffrement des logs binaires et relay logs

- **`encrypt_binlog = ON`** : chiffre les binary logs et relay logs sur le disque.
- Protège les données de réplication et de point-in-time recovery (PITR).

### 3.5 Chiffrement des fichiers temporaires

- **`encrypt_tmp_files = ON`** : chiffre les fichiers temporaires créés sur le disque par le serveur.

### 3.6 Chiffrement par table (granularité fine)

- Il est possible de chiffrer ou exclure des tables individuelles :
  ```sql
  -- Chiffrer explicitement une table
  CREATE TABLE t1 (id INT) ENCRYPTED=YES ENCRYPTION_KEY_ID=1;

  -- Exclure une table du chiffrement global
  ALTER TABLE t2 ENCRYPTED=NO;
  ```

### 3.7 Rotation des clés

- Les clés peuvent être **versionnées**. MariaDB effectue une **rotation automatique** en arrière-plan.
- La rotation se fait **sans interruption de service** (en ligne), grâce aux threads de chiffrement en arrière-plan.
- Les plugins AWS KMS et HashiCorp Vault supportent la rotation native coté fournisseur.

### 3.8 Variables de monitoring

| Variable / Commande | Description |
|---|---|
| `SHOW GLOBAL STATUS LIKE 'innodb_encryption%'` | État du chiffrement (nombre de tables chiffrées, en cours, etc.) |
| `innodb_encryption_rotation_pages_per_second` | Vitesse de rotation |
| `innodb_encryption_rotation_iops` | I/O dédiés à la rotation |
| Table `INFORMATION_SCHEMA.INNODB_TABLESPACES_ENCRYPTION` | Détail du statut de chiffrement par tablespace |

---

## 4. Processus de mise en place pour un serveur client en production (Windows / Linux)

> **Prérequis** : MariaDB >= 10.1 (le chiffrement au repos a été introduit en 10.1.3). Recommandé : **MariaDB 10.4+** ou **10.11 LTS** pour bénéficier de toutes les améliorations.

> **Rappel** : MariaDB est installé dans `C:\Sites\outils` (Windows) / `/Sites/outils` (Linux) sur chaque serveur client.

### Chemins de référence par OS

| Élément | Linux | Windows |
|---|---|---|
| Répertoire d'installation | `/Sites/outils/MariaDB<version>/` | `C:\Sites\outils\MariaDB<version>\MariaDB<version>\` |
| Répertoire data | `/Sites/outils/MariaDB<version>/data/` | `C:\Sites\outils\MariaDB<version>\MariaDB<version>\data\` |
| Répertoire config | `/Sites/outils/MariaDB<version>/` | `C:\Sites\outils\MariaDB<version>\MariaDB<version>\` |
| Répertoire clés de chiffrement | `/Sites/outils/MariaDB<version>/encryption/` | `C:\Sites\outils\MariaDB<version>\MariaDB<version>\encryption\` |
| Fichier config principal | `/Sites/outils/MariaDB<version>/my.cnf` | `C:\Sites\outils\MariaDB<version>\MariaDB<version>\my.ini` |
| Répertoire binaires | `/Sites/outils/MariaDB<version>/bin/` | `C:\Sites\outils\MariaDB<version>\MariaDB<version>\bin\` |
| Extension plugin | `.so` | `.dll` |
| Service | `mariadb.service` (systemd) | Service Windows `MySQL` (nom par défaut) |

### Étape 1 — Choisir et configurer le plugin de gestion de clés

#### Option A : `file_key_management` (simple, adapté si pas de KMS externe)

1. **Générer les clés de chiffrement** :

**Linux (bash)** :
```bash
mkdir -p /Sites/outils/MariaDB<version>/encryption

# Format du fichier de clés : <key_id>;<hex_encoded_key>
# key_id=1 est la clé principale utilisée par défaut
echo "1;$(openssl rand -hex 32)" > /Sites/outils/MariaDB<version>/encryption/keyfile
```

**Windows (PowerShell) — 3 méthodes au choix** :

> **Préalable commun** : créer le dossier de clés :
> ```powershell
> New-Item -ItemType Directory -Force -Path "C:\Sites\outils\MariaDB<version>\encryption"
> ```

##### Méthode 1 : avec OpenSSL (identique à Linux)

OpenSSL n'est pas installé par défaut sur Windows. Pour l'installer dans `C:\Sites\outils\openssl` :

**Installation manuelle (recommandé pour maîtriser le versioning)** :

1. Télécharger l'installeur depuis https://slproweb.com/products/Win32OpenSSL.html (choisir **Win64 OpenSSL vX.X.X Light** ou la version complète).
2. Lancer l'installeur et choisir le répertoire `C:\Sites\outils\openssl` :

```powershell
# Télécharger l'installeur (adapter l'URL selon la version souhaitée)
$installerUrl = "https://slproweb.com/download/Win64OpenSSL_Light-3_4_1.exe"
$installerPath = "$env:TEMP\openssl-installer.exe"
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

# Lancer l'installation silencieuse dans C:\Sites\outils\openssl
& $installerPath /VERYSILENT /DIR="C:\Sites\outils\openssl" /NORESTART

# Attendre la fin de l'installation
Start-Sleep -Seconds 30
```

3. Ajouter OpenSSL au PATH de la session (ou du système) :

```powershell
# Ajouter au PATH de la session courante
$env:Path += ";C:\Sites\outils\openssl\bin"

# (Optionnel) Ajouter au PATH système de façon permanente
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Sites\outils\openssl\bin",
    "Machine"
)
```

4. Vérifier l'installation :

```powershell
& "C:\Sites\outils\openssl\bin\openssl.exe" version
# Attendu : OpenSSL 3.x.x  ...
```

> **Suivi du versioning** : pour connaître la version installée sur un serveur à tout moment :
> ```powershell
> & "C:\Sites\outils\openssl\bin\openssl.exe" version
> ```
> Pour mettre à jour, relancer l'installeur avec le même `/DIR` — les fichiers seront remplacés.

**Alternatives rapides (installation dans le répertoire par défaut)** :

```powershell
# Via Chocolatey
choco install openssl -y --params "'/DIR=C:\Sites\outils\openssl'"

# Via winget (répertoire par défaut, pas de contrôle du chemin)
winget install ShiningLight.OpenSSL
```

> **Convention** : dans tout le reste du document, les commandes `openssl` utilisent le chemin complet `C:\Sites\outils\openssl\bin\openssl.exe`. Vous pouvez aussi utiliser simplement `openssl` si le PATH est configuré.

Une fois OpenSSL disponible :

```powershell
$openssl = "C:\Sites\outils\openssl\bin\openssl.exe"
$encDir  = "C:\Sites\outils\MariaDB<version>\encryption"

# Générer la clé AES-256 et écrire le fichier de clés
$key1 = & $openssl rand -hex 32
# IMPORTANT : utiliser WriteAllText pour éviter BOM et caractères parasites
[System.IO.File]::WriteAllText("$encDir\keyfile", "1;$key1`n", [System.Text.Encoding]::ASCII)
```

##### Méthode 2 : PowerShell natif (.NET) — aucune dépendance externe

```powershell
$encDir = "C:\Sites\outils\MariaDB<version>\encryption"

# Générer une clé AES-256 (32 octets = 64 caractères hex) via .NET
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 32
$rng.GetBytes($bytes)
$key1 = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''

# Écriture du fichier de clés (sans BOM ni caractères parasites)
[System.IO.File]::WriteAllText("$encDir\keyfile", "1;$key1`n", [System.Text.Encoding]::ASCII)
```

2. **Chiffrer le fichier de clés lui-même** (fortement recommandé) :

**Linux** :
```bash
openssl rand -hex 128 > /Sites/outils/MariaDB<version>/encryption/keyfile.key

openssl enc -aes-256-cbc -md sha1 \
  -pass file:/Sites/outils/MariaDB<version>/encryption/keyfile.key \
  -in /Sites/outils/MariaDB<version>/encryption/keyfile \
  -out /Sites/outils/MariaDB<version>/encryption/keyfile.enc

rm /Sites/outils/MariaDB<version>/encryption/keyfile   # supprimer le fichier en clair
```

**Windows — 3 méthodes au choix** :

##### Méthode 1 : avec OpenSSL (préalablement installé, voir ci-dessus)

```powershell
$openssl = "C:\Sites\outils\openssl\bin\openssl.exe"
$encDir  = "C:\Sites\outils\MariaDB<version>\encryption"

# Générer le keyfile.key SANS caractères parasites (pas de BOM, pas de newline)
$keyHex = (& $openssl rand -hex 128).Trim()
[System.IO.File]::WriteAllBytes("$encDir\keyfile.key", [System.Text.Encoding]::ASCII.GetBytes($keyHex))

# Chiffrer le fichier de clés
& $openssl enc -aes-256-cbc -md sha1 `
  -pass "file:$encDir\keyfile.key" `
  -in "$encDir\keyfile" `
  -out "$encDir\keyfile.enc"

# Vérifier que le déchiffrement fonctionne AVANT de redémarrer MariaDB
& $openssl enc -aes-256-cbc -md sha1 -d `
  -pass "file:$encDir\keyfile.key" `
  -in "$encDir\keyfile.enc"
# Doit afficher le contenu du keyfile : 1;<clé hex>

Remove-Item "$encDir\keyfile"   # supprimer le fichier en clair
```

> **Attention encodage Windows** : ne jamais utiliser `Out-File` ou l'opérateur `|` pour écrire le `keyfile.key`. PowerShell ajoute des caractères invisibles (BOM, `\r\n`) qui font que MariaDB lit une clé différente de celle utilisée par OpenSSL lors du chiffrement. Toujours utiliser `[System.IO.File]::WriteAllBytes()` pour une écriture binaire exacte.

> **Attention OpenSSL 3.x** : depuis OpenSSL 3.0, le digest par défaut pour `-pass` est **SHA-256**, alors que MariaDB attend **SHA-1**. Le paramètre **`-md sha1`** est donc **obligatoire** lors du chiffrement. Sans lui, MariaDB ne pourra pas déchiffrer le fichier (`Cannot decrypt keyfile.enc. Wrong key?`). La commande de vérification (déchiffrement avec `-md sha1`) doit toujours être exécutée avant de redémarrer le service.

##### Méthode 2 : PowerShell natif (.NET) — aucune dépendance externe

```powershell
$encDir = "C:\Sites\outils\MariaDB<version>\encryption"

# Générer la clé de chiffrement du fichier (128 octets hex = 256 caractères)
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 128
$rng.GetBytes($bytes)
$filekey = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''
# IMPORTANT : écriture binaire exacte, sans BOM ni newline
[System.IO.File]::WriteAllBytes("$encDir\keyfile.key", [System.Text.Encoding]::ASCII.GetBytes($filekey))

# Chiffrer le fichier de clés avec AES-256-CBC via .NET
$keyfileContent = [System.IO.File]::ReadAllBytes("$encDir\keyfile")
$filekeyBytes = [System.Text.Encoding]::ASCII.GetBytes($filekey)

# Dériver clé AES + IV (compatible OpenSSL EVP_BytesToKey)
$md5 = [System.Security.Cryptography.MD5]::Create()
$d1 = $md5.ComputeHash($filekeyBytes)
$d2 = $md5.ComputeHash($d1 + $filekeyBytes)
$d3 = $md5.ComputeHash($d2 + $filekeyBytes)
$aesKey = $d1 + $d2          # 32 octets = AES-256
$aesIV  = $d3[0..15]          # 16 octets = IV

$aes = [System.Security.Cryptography.Aes]::Create()
$aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$aes.Key = $aesKey
$aes.IV  = $aesIV
$encryptor = $aes.CreateEncryptor()
$encrypted = $encryptor.TransformFinalBlock($keyfileContent, 0, $keyfileContent.Length)

[System.IO.File]::WriteAllBytes("$encDir\keyfile.enc", $encrypted)

Remove-Item "$encDir\keyfile"   # supprimer le fichier en clair
```

##### Méthode 3 : fichier de clés non chiffré (simplifié, protection par ACL + BitLocker)

Si le chiffrement du fichier de clés paraît trop complexe, il est possible de **ne pas chiffrer le fichier de clés**. La sécurité repose alors sur :
- Les **ACL restrictives** (voir étape 3)
- Le **chiffrement du volume avec BitLocker**

Dans ce cas, à l'étape 4 (configuration MariaDB), utiliser :
```ini
[mariadb]
file_key_management_filename = C:/Sites/outils/MariaDB<version>/encryption/keyfile
# PAS de file_key_management_filekey (le fichier n'est pas chiffré)
```

> **Note** : cette méthode est acceptable en production si BitLocker est activé sur le volume contenant le dossier `encryption\`.

3. **Sécuriser les permissions** :

**Linux** :
```bash
chown mysql:mysql /Sites/outils/MariaDB<version>/encryption/*
chmod 600 /Sites/outils/MariaDB<version>/encryption/*
```

**Windows (PowerShell — restreindre les ACL au compte de service)** :

> **Compte de service** : sur vos serveurs, le service est enregistré sous le nom **`MySQL`** et tourne sous le compte **`NT SERVICE\MySQL`**. Pour vérifier :
> ```powershell
> Get-WmiObject Win32_Service -Filter "Name='MySQL'" | Select-Object Name, StartName
> ```

```powershell
$encDir = "C:\Sites\outils\MariaDB<version>\encryption"
$acl = Get-Acl $encDir

# Supprimer l'héritage et les accès existants
$acl.SetAccessRuleProtection($true, $false)
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) } | Out-Null

# Récupérer le compte de service (ici NT SERVICE\MySQL)
$serviceAccount = (Get-WmiObject Win32_Service -Filter "Name='MySQL'").StartName
# Si le compte est ".\utilisateur", normaliser en "MACHINE\utilisateur"
if ($serviceAccount -match '^\.\\') {
    $serviceAccount = $serviceAccount -replace '^\.\\', "$env:COMPUTERNAME\"
}

# Accorder l'accès en lecture au compte de service et FullControl aux administrateurs
$ruleService = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $serviceAccount, "Read", "ContainerInherit,ObjectInherit", "None", "Allow")
$ruleAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.AddAccessRule($ruleService)
$acl.AddAccessRule($ruleAdmin)
Set-Acl -Path $encDir -AclObject $acl

# Appliquer aux fichiers enfants
Get-ChildItem $encDir | ForEach-Object { Set-Acl -Path $_.FullName -AclObject $acl }

# Vérifier que les 2 règles sont bien appliquées (dossier + fichiers)
Write-Host "`n--- Dossier encryption ---"
(Get-Acl $encDir).Access | Format-Table IdentityReference, FileSystemRights, AccessControlType -AutoSize

Get-ChildItem $encDir | ForEach-Object {
    Write-Host "`n--- $($_.Name) ---"
    (Get-Acl $_.FullName).Access | Format-Table IdentityReference, FileSystemRights, AccessControlType -AutoSize
}
# Attendu : 2 lignes par élément :
#   BUILTIN\Administrateurs  FullControl        Allow
#   NT SERVICE\MySQL         Read, Synchronize  Allow
```

> **Note** : `Format-List -Property Access` affiche le nombre de règles mais pas leur détail. Utilisez toujours `$acl.Access | Format-Table IdentityReference, FileSystemRights, AccessControlType` pour voir le contenu réel des ACL.

4. **Configurer MariaDB** :

**Linux** (`/Sites/outils/MariaDB<version>/my.cnf`) :
```ini
[mariadb]
plugin_load_add = file_key_management
file_key_management_filename = /Sites/outils/MariaDB<version>/encryption/keyfile.enc
file_key_management_filekey = FILE:/Sites/outils/MariaDB<version>/encryption/keyfile.key
file_key_management_encryption_algorithm = AES_CTR
```

**Windows** (ajouter dans `C:\Sites\outils\MariaDB<version>\my.ini`, section `[mariadb]`) :
```ini
[mariadb]
plugin_load_add = file_key_management
file_key_management_filename = C:/Sites/outils/MariaDB<version>/encryption/keyfile.enc
file_key_management_filekey = FILE:C:/Sites/outils/MariaDB<version>/encryption/keyfile.key
file_key_management_encryption_algorithm = AES_CTR
```

> **Note Windows** : utiliser des **slashs** `/` (et non `\`) dans les chemins du fichier `my.ini`.

#### Option B : `aws_key_management` (recommandé en environnement AWS)

```ini
[mariadb]
plugin_load_add = aws_key_management
aws_key_management_master_key_id = alias/mariadb-encryption
aws_key_management_region = eu-west-1
aws_key_management_rotate_key = ON
aws_key_management_key_spec = AES_256
aws_key_management_log_level = Warn
```

> Identique sur Windows et Linux. Sur Windows, s'assurer que les credentials AWS sont configurés via `%USERPROFILE%\.aws\credentials` ou via les variables d'environnement du service. Sur Linux : `/home/mysql/.aws/credentials` ou IAM Role si EC2. Ajouter cette config dans `/Sites/outils/MariaDB<version>/my.cnf` (Linux) ou `C:\Sites\outils\MariaDB<version>\my.ini` (Windows).

#### Option C : `hashicorp_key_management` (recommandé pour infrastructure on-premise sécurisée)

**Linux** (`/Sites/outils/MariaDB<version>/my.cnf`) :
```ini
[mariadb]
plugin_load_add = hashicorp_key_management
hashicorp_key_management_vault_url = https://vault.example.com:8200/v1/mariadb/
hashicorp_key_management_token = s.xxxxxxxxx
hashicorp_key_management_vault_ca = /Sites/outils/MariaDB<version>/encryption/vault-ca.pem
hashicorp_key_management_caching_enabled = ON
hashicorp_key_management_use_cache_on_timeout = ON
```

**Windows** (`C:\Sites\outils\MariaDB<version>\my.ini`) :
```ini
[mariadb]
plugin_load_add = hashicorp_key_management
hashicorp_key_management_vault_url = https://vault.example.com:8200/v1/mariadb/
hashicorp_key_management_token = s.xxxxxxxxx
hashicorp_key_management_vault_ca = C:/Sites/outils/MariaDB<version>/encryption/vault-ca.pem
hashicorp_key_management_caching_enabled = ON
hashicorp_key_management_use_cache_on_timeout = ON
```

### Étape 2 — Activer le chiffrement des données

Ajouter dans le fichier de configuration du serveur client :
- **Linux** : `/Sites/outils/MariaDB<version>/my.cnf`
- **Windows** : `C:\Sites\outils\MariaDB<version>\my.ini`

```ini
[mariadb]
# --- Chiffrement InnoDB ---
innodb_encrypt_tables = ON            # ON = chiffre par défaut, FORCE = interdit les tables non chiffrées
innodb_encrypt_log = ON               # Chiffrer les redo logs
innodb_encryption_threads = 4         # Threads de chiffrement en arrière-plan (adapter selon CPU)
innodb_encryption_rotate_key_age = 1  # Utile avec plugins KMS. Avec file_key_management, la rotation se fait par changement de key_id (voir Section 5)

# --- Chiffrement Aria (tables temporaires) ---
aria_encrypt_tables = ON

# --- Chiffrement des binary logs ---
encrypt_binlog = ON

# --- Chiffrement des fichiers temporaires ---
encrypt_tmp_files = ON
```

> **Identique sur les deux OS.** Les variables système MariaDB sont les mêmes indépendamment de la plateforme.

### Étape 3 — Redémarrer MariaDB

**Linux** :
```bash
sudo systemctl restart mariadb
```

**Windows (PowerShell en administrateur)** :
```powershell
Restart-Service MySQL
```

> **Attention en production** : planifier le redémarrage dans une fenêtre de maintenance convenue avec le client. Si l'architecture du client est en réplication (master/slave ou Galera), redémarrer les nœuds un par un.

### Étape 4 — Vérifier l'activation du chiffrement

```sql
-- Vérifier que le plugin est chargé
SHOW PLUGINS;

-- Vérifier les variables de chiffrement
SHOW GLOBAL VARIABLES LIKE '%encrypt%';
SHOW GLOBAL VARIABLES LIKE 'file_key_management%';

-- Vérifier l'état du chiffrement des tables
SELECT * FROM INFORMATION_SCHEMA.INNODB_TABLESPACES_ENCRYPTION;

-- Résumé : nombre de tables chiffrées vs non chiffrées
SELECT
    ENCRYPTION_SCHEME,
    COUNT(*) AS nb_tables
FROM INFORMATION_SCHEMA.INNODB_TABLESPACES_ENCRYPTION
GROUP BY ENCRYPTION_SCHEME;

-- Vérifier les status globaux
SHOW GLOBAL STATUS LIKE 'innodb_encryption%';
```

### Étape 5 — Chiffrer les tables existantes

Si `innodb_encrypt_tables = ON`, les threads d'arrière-plan chiffreront automatiquement les tables existantes. Pour suivre la progression :

```sql
-- Tables en attente de chiffrement
SELECT NAME, ENCRYPTION_SCHEME, ROTATING_OR_FLUSHING
FROM INFORMATION_SCHEMA.INNODB_TABLESPACES_ENCRYPTION
WHERE ENCRYPTION_SCHEME = 0;
```

Pour forcer manuellement le chiffrement d'une table spécifique :

```sql
ALTER TABLE ma_base.ma_table ENCRYPTED=YES ENCRYPTION_KEY_ID=1;
```

### Étape 6 — Valider physiquement le chiffrement

**Linux** :
```bash
# Avant chiffrement, on pouvait voir les données en clair :
strings /Sites/outils/MariaDB<version>/data/ma_base/ma_table.ibd | head

# Après chiffrement, le fichier ne contient que des données illisibles.
# Aucune chaîne de caractères lisible ne doit apparaître.
```

**Windows (PowerShell)** :
```powershell
# Vérifier qu'aucune donnée lisible n'apparaît dans le fichier chiffré
$dataDir = "C:\Sites\outils\MariaDB<version>\data"
$bytes = [System.IO.File]::ReadAllBytes("$dataDir\ma_base\ma_table.ibd")
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
# Rechercher des chaînes lisibles (ne devrait rien retourner après chiffrement)
[regex]::Matches($text, '[\x20-\x7E]{8,}') | Select-Object -First 10 -ExpandProperty Value
```

### Étape 7 — Sécurisation complémentaire (recommandations production)

| Mesure | Linux | Windows |
|---|---|---|
| **Protéger le fichier de clés** | `chmod 600` + `chown mysql:mysql` sur `.../encryption/` | ACL restrictives : accès limité au compte de service (membre IUSRS) + Administrators (voir étape 1) |
| **Chiffrement volume OS** | LUKS (dm-crypt) sur la partition contenant `/Sites/outils/MariaDB<version>/data/` | BitLocker sur le volume contenant `C:\Sites\outils\MariaDB<version>\data\` |
| **Sauvegardes** | mariabackup conserve le chiffrement. Clé sauvegardée **séparément** des données. | Idem. Stocker les clés dans un coffre-fort distinct (pas sur le même volume). |
| **Rotation des clés** | Rotation trimestrielle. AWS KMS / Vault : rotation automatique. | Idem. |
| **Monitoring** | Zabbix/Prometheus/Grafana sur `innodb_encryption%` | Idem + Windows Performance Monitor / Event Log. |
| **Audit** | Plugin `server_audit` pour tracer les accès. | Idem + Windows Event Forwarding (WEF) pour centraliser. |
| **TLS/SSL** | `ssl_cert`, `ssl_key`, `ssl_ca` dans `/Sites/outils/MariaDB<version>/my.cnf`. | Idem dans `C:\Sites\outils\MariaDB<version>\my.ini`. Les chemins utilisent `/`. |
| **mariabackup** | `/Sites/outils/MariaDB<version>/bin/mariabackup --backup` (fichiers chiffrés copiés tels quels). | `C:\Sites\outils\MariaDB<version>\bin\mariabackup.exe`. |
| **Tester la restauration** | Valider régulièrement avec les clés de chiffrement. | Idem — tester selon l'OS du serveur client. |
| **Firewall** | `iptables`/`nftables` : restreindre les IP sources autorisées. | Windows Firewall (Advfirewall) : règles entrantes restrictives. |

### Étape 8 — Commandes mariabackup avec chiffrement

**Linux** :
```bash
# Sauvegarde complète (les fichiers chiffrés sont copiés avec leur chiffrement)
/Sites/outils/MariaDB<version>/bin/mariabackup --backup \
  --target-dir=/backup/full \
  --user=backup_user --password=xxx

# Préparation
/Sites/outils/MariaDB<version>/bin/mariabackup --prepare --target-dir=/backup/full

# Restauration (nécessite les mêmes clés dans /Sites/outils/MariaDB<version>/my.cnf)
/Sites/outils/MariaDB<version>/bin/mariabackup --copy-back --target-dir=/backup/full
chown -R mysql:mysql /Sites/outils/MariaDB<version>/data
```

**Windows (PowerShell en administrateur)** :
```powershell
$mariabackup = "C:\Sites\outils\MariaDB<version>\bin\mariabackup.exe"

# Sauvegarde complète
& $mariabackup --backup `
  --target-dir="C:\Backup\MariaDB\full" `
  --user=backup_user --password=xxx

# Préparation
& $mariabackup --prepare --target-dir="C:\Backup\MariaDB\full"

# Restauration (nécessite les mêmes clés dans C:\Sites\outils\MariaDB<version>\my.ini)
& $mariabackup --copy-back --target-dir="C:\Backup\MariaDB\full"

# Réattribuer les permissions au compte de service
$dataDir = "C:\Sites\outils\MariaDB<version>\data"
$serviceAccount = (Get-WmiObject Win32_Service -Filter "Name='MySQL'").StartName
if ($serviceAccount -match '^\.\\') {
    $serviceAccount = $serviceAccount -replace '^\.\\', "$env:COMPUTERNAME\"
}
icacls $dataDir /grant "${serviceAccount}:(OI)(CI)F" /T
```

> Il est possible de sauvegarder uniquement certaines bases avec `--databases="db1 db2"` pour des sauvegardes ciblées.

---

## 5. Rotation périodique des clés — Conformité FDA (données médicales)

### 5.1 Exigences réglementaires FDA applicables

Dans un environnement de manipulation de **données médicales** (SaMD, dispositifs médicaux, essais cliniques, ePHI), plusieurs réglementations imposent une gestion rigoureuse des clés cryptographiques :

| Référentiel | Article / Section | Exigence | Lien direct |
|---|---|---|---|
| **FDA 21 CFR Part 11** | §11.10(c), §11.10(d) | Contrôles d'accès, audit trail, protection des enregistrements électroniques | [ecfr.gov — 21 CFR 11.10](https://www.ecfr.gov/current/title-21/chapter-I/subchapter-A/part-11/subpart-B/section-11.10) |
| **FDA 21 CFR Part 11** | §11.300 | Contrôles techniques pour signatures et chiffrement | [ecfr.gov — 21 CFR 11.300](https://www.ecfr.gov/current/title-21/chapter-I/subchapter-A/part-11/subpart-C/section-11.300) |
| **NIST SP 800-57 Part 1** (recommandé par FDA) | §5.3 | Cryptoperiod maximale : **1 à 2 ans** pour les clés de chiffrement de données | [nist.gov — SP 800-57 Part 1 Rev. 5](https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final) |
| **NIST SP 800-57 Part 1** | §5.3, Table 1 | Clé de chiffrement symétrique (Data Encryption Key) : renouvellement **≤ 2 ans** | [nist.gov — SP 800-57 Part 1 (PDF)](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57pt1r5.pdf) |
| **HIPAA Security Rule** | §164.312(a)(2)(iv) | Chiffrement des données de santé au repos et mécanismes de gestion des clés | [ecfr.gov — 45 CFR 164.312](https://www.ecfr.gov/current/title-45/subtitle-A/subchapter-C/part-164/subpart-C/section-164.312) |
| **ISO 27001:2022** | A.10.1.2 | Politique de gestion des clés, dont la rotation | [iso.org — ISO/IEC 27001:2022](https://www.iso.org/standard/27001) |
| **IEC 62443** (dispositifs connectés) | SR 4.3 | Renouvellement cryptographique périodique | [iec.ch — IEC 62443-3-3](https://webstore.iec.ch/en/publication/7033) |

### 5.2 Périodicité recommandée (environnement données médicales / FDA)

| Élément | Périodicité | Justification |
|---|---|---|
| **Clé de chiffrement des données** (`keyfile` — key_id versions) | **Tous les 90 jours (trimestriel)** | Conforme NIST SP 800-57 (cryptoperiod ≤ 2 ans), avec marge de sécurité pour ePHI. Trimestriel = pratique standard dans le médical. |
| **Clé de chiffrement du fichier de clés** (`keyfile.key`) | **Tous les 12 mois (annuel)** | Protège le conteneur de clés. Rotation annuelle conforme NIST. |
| **Rotation d'urgence** | **Immédiate** | En cas de compromission suspectée, départ d'un DBA, incident de sécurité, ou demande audit FDA. |

> **Résumé** : rotation **trimestrielle** de la clé de données + rotation **annuelle** de la clé d'enveloppe + rotation **immédiate** en cas d'incident. Documenter chaque rotation dans un **journal d'audit** (exigence 21 CFR Part 11).

### 5.3 Mécanisme de rotation avec `file_key_management`

> **Attention** : le plugin `file_key_management` **ne gère PAS les versions de clés**. Le format à 3 champs (`key_id;version;hex`) n'est **pas supporté**. Le paramètre `innodb_encryption_rotate_key_age` ne fonctionne qu'avec les plugins KMS d'entreprise (AWS KMS, HashiCorp Vault, etc.) qui gèrent le versioning en interne.

**Format supporté** — une seule possibilité :

```
<key_id>;<hex_encoded_key>
```

**Mécanisme de rotation** : au lieu de versionner une même clé, on **ajoute une nouvelle clé avec un nouvel ID** (1, 2, 3...) et on bascule MariaDB dessus.

**Étapes de rotation :**

1. Ajouter une nouvelle ligne `<nouveau_key_id>;<nouvelle_clé_hex>` dans le fichier de clés
2. Re-chiffrer le fichier avec la clé d'enveloppe (`keyfile.key`)
3. Changer la clé par défaut : `SET GLOBAL innodb_default_encryption_key_id = <nouveau_key_id>;`
4. Re-chiffrer les tables existantes : `ALTER TABLE <table> ENCRYPTION_KEY_ID=<nouveau_key_id>;`

> **Important** : les anciennes clés doivent **rester dans le fichier** pour que MariaDB puisse lire les tables encore chiffrées avec elles pendant la transition et pour les restaurations de sauvegardes.

**Évolution du fichier de clés au fil des rotations :**

```
# État initial (1 seule clé, key_id=1)
1;ca00376654ebdba401a0a1d2298c8eb0a2fa06bd105c5a66a00a5585caf2ece0

# Après 1ère rotation → ajout key_id=2, MariaDB bascule dessus
1;ca00376654ebdba401a0a1d2298c8eb0a2fa06bd105c5a66a00a5585caf2ece0
2;nouvelle_cle_hex_64_caracteres

# Après 2ème rotation → ajout key_id=3
1;ca00376654ebdba401a0a1d2298c8eb0a2fa06bd105c5a66a00a5585caf2ece0
2;nouvelle_cle_hex_64_caracteres
3;encore_une_nouvelle_cle_hex_64_caracteres
```

Après re-chiffrement de toutes les tables avec le dernier `key_id`, les anciens IDs ne sont plus activement utilisés mais restent nécessaires pour les restaurations de backups historiques.

### 5.4 Script de rotation des clés — Windows (PowerShell)

Ce script effectue la rotation complète : ajout d'un nouveau key_id, re-chiffrement du fichier, bascule MariaDB sur la nouvelle clé, et journalisation pour conformité FDA/21 CFR Part 11.

```powershell
<#
.SYNOPSIS
    Rotation périodique de la clé de chiffrement MariaDB TDE (file_key_management).
    Le plugin file_key_management ne gère PAS les versions de clés.
    La rotation se fait par ajout d'un NOUVEL ID de clé (1, 2, 3...).
    Conforme FDA 21 CFR Part 11 / NIST SP 800-57.

.NOTES
    À planifier via le Planificateur de tâches Windows (trimestriel).
    Exécuter en tant qu'Administrateur.
#>

param(
    [string]$MariaDBVersion = "MariaDB115",
    [string]$BasePath       = "C:\Sites\outils",
    [string]$OpenSSLPath    = "C:\Sites\outils\openssl\bin\openssl.exe",
    [string]$LogPath        = "C:\Sites\outils\logs\tde-rotation.log"
)

$ErrorActionPreference = "Stop"
$encDir     = "$BasePath\$MariaDBVersion\encryption"
$keyfileTmp = "$encDir\keyfile.tmp"
$keyfileEnc = "$encDir\keyfile.enc"
$keyfileKey = "$encDir\keyfile.key"
$backupDir  = "$encDir\backups"
$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"

# --- Fonction de journalisation (audit trail FDA) ---
function Write-AuditLog {
    param([string]$Message)
    $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$(whoami)] $Message"
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
    Add-Content -Path $LogPath -Value $entry
    Write-Host $entry
}

try {
    Write-AuditLog "=== DEBUT ROTATION DE CLE TDE ==="

    # --- 1. Sauvegarder les fichiers actuels ---
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Force -Path $backupDir | Out-Null }
    Copy-Item $keyfileEnc "$backupDir\keyfile.enc.$timestamp" -Force
    Copy-Item $keyfileKey "$backupDir\keyfile.key.$timestamp" -Force
    Write-AuditLog "Backup des cles existantes dans $backupDir"

    # --- 2. Déchiffrer le keyfile actuel ---
    & $OpenSSLPath enc -aes-256-cbc -md sha1 -d `
      -pass "file:$keyfileKey" `
      -in $keyfileEnc `
      -out $keyfileTmp

    if (-not (Test-Path $keyfileTmp)) { throw "Echec du dechiffrement du keyfile.enc" }
    Write-AuditLog "Dechiffrement du keyfile.enc reussi"

    # --- 3. Déterminer le key_id le plus élevé ---
    # Format file_key_management : <key_id>;<hex_key> (PAS de version)
    # @() force un tableau même si une seule ligne
    $lines = @(Get-Content $keyfileTmp | Where-Object { $_.Trim() -ne "" })
    $maxKeyId = 0

    foreach ($line in $lines) {
        $parts = $line -split ";"
        if ($parts.Count -ge 2) {
            $id = [int]$parts[0]
            if ($id -gt $maxKeyId) { $maxKeyId = $id }
        }
    }
    if ($maxKeyId -eq 0) { throw "Format de cle invalide : attendu '<key_id>;<hex_key>'." }
    $newKeyId = $maxKeyId + 1
    Write-AuditLog "Key ID actuel le plus eleve: $maxKeyId -> Nouveau key_id: $newKeyId"

    # --- 4. Générer une nouvelle clé AES-256 ---
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $keyBytes = New-Object byte[] 32
    $rng.GetBytes($keyBytes)
    $newKeyHex = ($keyBytes | ForEach-Object { $_.ToString('x2') }) -join ''

    # --- 5. Ajouter la nouvelle clé avec le nouvel ID ---
    $newLine = "$newKeyId;$newKeyHex"
    $allLines = $lines + $newLine
    $finalContent = ($allLines -join "`n") + "`n"
    [System.IO.File]::WriteAllBytes($keyfileTmp, [System.Text.Encoding]::ASCII.GetBytes($finalContent))
    Write-AuditLog "Nouvelle cle generee (key_id=$newKeyId)"

    # --- 6. Re-chiffrer le fichier de clés ---
    & $OpenSSLPath enc -aes-256-cbc -md sha1 `
      -pass "file:$keyfileKey" `
      -in $keyfileTmp `
      -out $keyfileEnc

    # --- 7. Vérifier le re-chiffrement ---
    # $verifyOutput est un string[] (une ligne par clé) → joindre avant -notmatch
    $verifyOutput = & $OpenSSLPath enc -aes-256-cbc -md sha1 -d `
      -pass "file:$keyfileKey" `
      -in $keyfileEnc
    $verifyString = ($verifyOutput -join "`n")

    if ($verifyString -notmatch [regex]::Escape($newKeyHex)) { throw "Verification du chiffrement echouee" }
    Write-AuditLog "Verification du re-chiffrement: OK"

    # --- 8. Nettoyer le fichier temporaire ---
    Remove-Item $keyfileTmp -Force
    Write-AuditLog "Fichier temporaire supprime"

    # --- 9. Basculer MariaDB sur la nouvelle clé ---
    $mysql = "$BasePath\$MariaDBVersion\bin\mysql.exe"

    # Changer la clé par défaut pour les nouvelles écritures
    & $mysql -u root -e "SET GLOBAL innodb_default_encryption_key_id = $newKeyId;"
    Write-AuditLog "innodb_default_encryption_key_id = $newKeyId"

    # Re-chiffrer toutes les tables InnoDB avec le nouveau key_id
    $tables = @(& $mysql -u root -N -e "SELECT CONCAT(TABLE_SCHEMA,'.',TABLE_NAME) FROM INFORMATION_SCHEMA.TABLES WHERE ENGINE='InnoDB' AND TABLE_SCHEMA NOT IN ('mysql','information_schema','performance_schema');" 2>$null)
    $tableCount = 0
    foreach ($table in $tables) {
        $t = $table.Trim()
        if ($t -ne "") {
            & $mysql -u root -e "ALTER TABLE $t ENCRYPTION_KEY_ID=$newKeyId;" 2>$null
            $tableCount++
        }
    }
    Write-AuditLog "Re-chiffrement lance sur $tableCount table(s) avec key_id=$newKeyId"

    Write-AuditLog "=== ROTATION TERMINEE AVEC SUCCES (key_id=$newKeyId) ==="
    Write-AuditLog "IMPORTANT: Ajouter 'innodb_default_encryption_key_id = $newKeyId' dans my.ini pour persister apres redemarrage"

} catch {
    Write-AuditLog "ERREUR: $($_.Exception.Message)"
    Write-AuditLog "=== ROTATION ECHOUEE — Restauration manuelle necessaire depuis $backupDir ==="
    throw
}
```

### 5.5 Script de rotation de la clé d'enveloppe (`keyfile.key`) — annuel

```powershell
<#
.SYNOPSIS
    Rotation annuelle de la clé d'enveloppe (keyfile.key) qui chiffre le fichier de clés TDE.
    Conforme FDA 21 CFR Part 11 / NIST SP 800-57.
#>

param(
    [string]$MariaDBVersion = "MariaDB115",
    [string]$BasePath       = "C:\Sites\outils",
    [string]$OpenSSLPath    = "C:\Sites\outils\openssl\bin\openssl.exe",
    [string]$LogPath        = "C:\Sites\outils\logs\tde-rotation.log"
)

$ErrorActionPreference = "Stop"
$encDir     = "$BasePath\$MariaDBVersion\encryption"
$keyfileEnc = "$encDir\keyfile.enc"
$keyfileKey = "$encDir\keyfile.key"
$backupDir  = "$encDir\backups"
$timestamp  = Get-Date -Format "yyyyMMdd-HHmmss"

function Write-AuditLog {
    param([string]$Message)
    $entry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$(whoami)] $Message"
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
    Add-Content -Path $LogPath -Value $entry
    Write-Host $entry
}

try {
    Write-AuditLog "=== DÉBUT ROTATION CLÉ D'ENVELOPPE ==="

    # 1. Backup
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Force -Path $backupDir | Out-Null }
    Copy-Item $keyfileKey "$backupDir\keyfile.key.$timestamp" -Force
    Copy-Item $keyfileEnc "$backupDir\keyfile.enc.$timestamp" -Force
    Write-AuditLog "Backup clé d'enveloppe et keyfile.enc"

    # 2. Déchiffrer avec l'ancienne clé d'enveloppe
    & $OpenSSLPath enc -aes-256-cbc -md sha1 -d `
      -pass "file:$keyfileKey" `
      -in $keyfileEnc `
      -out "$encDir\keyfile.plain.tmp"

    Write-AuditLog "Déchiffrement avec ancienne clé d'enveloppe: OK"

    # 3. Générer une nouvelle clé d'enveloppe
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $envKeyBytes = New-Object byte[] 32
    $rng.GetBytes($envKeyBytes)
    $newEnvKey = ($envKeyBytes | ForEach-Object { $_.ToString('x2') }) -join ''
    [System.IO.File]::WriteAllBytes($keyfileKey, [System.Text.Encoding]::ASCII.GetBytes($newEnvKey))
    Write-AuditLog "Nouvelle clé d'enveloppe générée ($($newEnvKey.Length) caractères)"

    # 4. Re-chiffrer avec la nouvelle clé d'enveloppe
    & $OpenSSLPath enc -aes-256-cbc -md sha1 `
      -pass "file:$keyfileKey" `
      -in "$encDir\keyfile.plain.tmp" `
      -out $keyfileEnc

    # 5. Vérifier
    $verify = & $OpenSSLPath enc -aes-256-cbc -md sha1 -d `
      -pass "file:$keyfileKey" `
      -in $keyfileEnc
    Write-AuditLog "Vérification re-chiffrement nouvelle enveloppe: OK"
    Write-AuditLog "Contenu vérifié: $($verify.Count) lignes de clés"

    # 6. Nettoyer
    Remove-Item "$encDir\keyfile.plain.tmp" -Force

    # 7. Redémarrer le service pour charger la nouvelle clé d'enveloppe
    Restart-Service MySQL
    Write-AuditLog "Service MySQL redémarré avec la nouvelle clé d'enveloppe"

    Write-AuditLog "=== ROTATION CLÉ D'ENVELOPPE TERMINÉE ==="

} catch {
    Write-AuditLog "ERREUR: $($_.Exception.Message)"
    Write-AuditLog "=== RESTAURATION : copier les fichiers depuis $backupDir ==="
    throw
}
```

### 5.6 Planification via le Planificateur de tâches Windows

```powershell
# --- Rotation trimestrielle de la clé de données (key_id version) ---
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Sites\outils\scripts\Rotate-TDEDataKey.ps1`""

# Tous les 90 jours, à 02:00 (hors heures de production)
$trigger = New-ScheduledTaskTrigger -Daily -DaysInterval 90 -At "02:00"

$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask `
    -TaskName "MariaDB TDE - Rotation clé données (90j)" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Rotation trimestrielle clé TDE MariaDB - Conformité FDA 21 CFR Part 11 / NIST SP 800-57"


# --- Rotation annuelle de la clé d'enveloppe ---
$actionEnv = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\Sites\outils\scripts\Rotate-TDEEnvelopeKey.ps1`""

$triggerEnv = New-ScheduledTaskTrigger -Daily -DaysInterval 365 -At "03:00"

Register-ScheduledTask `
    -TaskName "MariaDB TDE - Rotation clé enveloppe (annuel)" `
    -Action $actionEnv `
    -Trigger $triggerEnv `
    -Settings $settings `
    -Principal $principal `
    -Description "Rotation annuelle clé d'enveloppe TDE - Conformité FDA / NIST"
```

### 5.7 Script de rotation — Linux (bash)

```bash
#!/bin/bash
# Rotation trimestrielle de la clé TDE MariaDB (file_key_management)
# Le plugin file_key_management ne gère PAS les versions de clés.
# La rotation se fait par ajout d'un NOUVEL ID de clé (1, 2, 3...).
# Conformité FDA 21 CFR Part 11 / NIST SP 800-57

set -euo pipefail

VERSION="MariaDB115"  # adapter selon l'installation
BASE="/Sites/outils"
ENC_DIR="$BASE/$VERSION/encryption"
LOG_FILE="$BASE/logs/tde-rotation.log"
BACKUP_DIR="$ENC_DIR/backups"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$(whoami)] $1" | tee -a "$LOG_FILE"; }

mkdir -p "$BACKUP_DIR" "$(dirname "$LOG_FILE")"

log "=== DEBUT ROTATION DE CLE TDE ==="

# 1. Backup
cp "$ENC_DIR/keyfile.enc" "$BACKUP_DIR/keyfile.enc.$TIMESTAMP"
cp "$ENC_DIR/keyfile.key" "$BACKUP_DIR/keyfile.key.$TIMESTAMP"
log "Backup effectue"

# 2. Déchiffrer
openssl enc -aes-256-cbc -md sha1 -d \
  -pass "file:$ENC_DIR/keyfile.key" \
  -in "$ENC_DIR/keyfile.enc" \
  -out "$ENC_DIR/keyfile.tmp"
log "Dechiffrement OK"

# 3. Déterminer le key_id le plus élevé
# Format : <key_id>;<hex_key> (PAS de version)
MAX_ID=$(awk -F';' '{if($1+0 > max) max=$1+0} END{print max+0}' "$ENC_DIR/keyfile.tmp")
[ "$MAX_ID" -eq 0 ] && { log "ERREUR: format de cle invalide (attendu '<key_id>;<hex_key>')."; exit 1; }
NEW_ID=$((MAX_ID + 1))
log "Key ID actuel le plus eleve: $MAX_ID -> Nouveau key_id: $NEW_ID"

# 4. Générer et ajouter la nouvelle clé
NEW_KEY=$(openssl rand -hex 32)
echo "${NEW_ID};${NEW_KEY}" >> "$ENC_DIR/keyfile.tmp"
log "Nouvelle cle generee (key_id=$NEW_ID)"

# 5. Re-chiffrer
openssl enc -aes-256-cbc -md sha1 \
  -pass "file:$ENC_DIR/keyfile.key" \
  -in "$ENC_DIR/keyfile.tmp" \
  -out "$ENC_DIR/keyfile.enc"

# 6. Vérifier
openssl enc -aes-256-cbc -md sha1 -d \
  -pass "file:$ENC_DIR/keyfile.key" \
  -in "$ENC_DIR/keyfile.enc" | grep -q "$NEW_KEY" && log "Verification OK" || { log "ERREUR verification"; exit 1; }

# 7. Nettoyer
rm -f "$ENC_DIR/keyfile.tmp"

# 8. Basculer MariaDB sur la nouvelle clé
mysql -u root -e "SET GLOBAL innodb_default_encryption_key_id = $NEW_ID;"
log "innodb_default_encryption_key_id = $NEW_ID"

# 9. Re-chiffrer les tables existantes avec le nouveau key_id
TABLES=$(mysql -u root -N -e "SELECT CONCAT(TABLE_SCHEMA,'.',TABLE_NAME) FROM INFORMATION_SCHEMA.TABLES WHERE ENGINE='InnoDB' AND TABLE_SCHEMA NOT IN ('mysql','information_schema','performance_schema');")
COUNT=0
while IFS= read -r TABLE; do
  [ -z "$TABLE" ] && continue
  mysql -u root -e "ALTER TABLE $TABLE ENCRYPTION_KEY_ID=$NEW_ID;" 2>/dev/null && COUNT=$((COUNT+1))
done <<< "$TABLES"
log "Re-chiffrement lance sur $COUNT table(s) avec key_id=$NEW_ID"

log "=== ROTATION TERMINEE (key_id=$NEW_ID) ==="
log "IMPORTANT: Ajouter 'innodb_default_encryption_key_id = $NEW_ID' dans my.cnf pour persister apres redemarrage"
```

Planification via cron (trimestriel, le 1er du mois à 02:00) :

```bash
# Éditer le crontab
sudo crontab -e

# Ajouter — exécution le 1er janvier, avril, juillet, octobre à 02:00
0 2 1 1,4,7,10 * /Sites/outils/scripts/rotate-tde-datakey.sh >> /Sites/outils/logs/tde-cron.log 2>&1
```

### 5.8 Vérification post-rotation (SQL — identique Windows/Linux)

```sql
-- Vérifier le key_id utilisé par chaque tablespace
SELECT
    NAME,
    ENCRYPTION_SCHEME,
    KEY_ID,
    ROTATING_OR_FLUSHING
FROM INFORMATION_SCHEMA.INNODB_TABLESPACES_ENCRYPTION
ORDER BY NAME;

-- Vérifier que toutes les tables utilisent le nouveau key_id
-- (remplacer <nouveau_key_id> par l'ID attendu, ex: 2)
SELECT NAME, KEY_ID
FROM INFORMATION_SCHEMA.INNODB_TABLESPACES_ENCRYPTION
WHERE KEY_ID != <nouveau_key_id>;
-- Attendu : 0 ligne (toutes les tables sont sur le nouveau key_id)

-- Vérifier qu'il n'y a plus de tables en cours de rotation
SELECT COUNT(*) AS tables_en_attente
FROM INFORMATION_SCHEMA.INNODB_TABLESPACES_ENCRYPTION
WHERE ROTATING_OR_FLUSHING = 1;
-- Attendu : 0 (rotation terminée)

-- Status global du chiffrement
SHOW GLOBAL STATUS LIKE 'innodb_encryption%';
```

### 5.9 Journal d'audit — exigences FDA 21 CFR Part 11

Le fichier de log `C:\Sites\outils\logs\tde-rotation.log` (ou `/Sites/outils/logs/tde-rotation.log`) contient l'audit trail complet, avec pour chaque rotation :

| Champ | Exemple |
|---|---|
| **Date et heure** | `2026-03-10 02:00:05` |
| **Identité de l'opérateur** | `SYSTEM` ou `administrateur` |
| **Action** | `Nouvelle cle generee (key_id=3)` |
| **Résultat** | `Vérification du re-chiffrement: OK` |
| **Statut** | `ROTATION TERMINÉE AVEC SUCCÈS` |

> **Rétention** : conserver les logs de rotation **minimum 3 ans** (pratique standard FDA). Les backups de clés doivent être conservés **aussi longtemps que des données chiffrées avec ces key_id existent** (nécessaire pour les restaurations de sauvegardes historiques).

### 5.10 Calendrier récapitulatif de rotation (données médicales / FDA)

```
Année N
├── T1 (Janvier)   → Rotation clé données (nouveau key_id)
│                    + Rotation clé enveloppe (annuelle)
├── T2 (Avril)     → Rotation clé données (nouveau key_id)
├── T3 (Juillet)   → Rotation clé données (nouveau key_id)
├── T4 (Octobre)   → Rotation clé données (nouveau key_id)
│
Année N+1
├── T1 (Janvier)   → Rotation clé données (nouveau key_id)
│                    + Rotation clé enveloppe (annuelle)
└── ...
```

> **Incident / Compromission** → rotation **immédiate** hors cycle, documentée dans le journal d'audit avec la raison.

---

## Résumé architecture TDE MariaDB — Serveur dédié par client (Windows / Linux)

```
┌───────────────────────────────────────────────────────────┐
│              Application du client                            │
│          (aucune modification nécessaire)                      │
└──────────────┬────────────────────────────────────────────┘
               │  Requêtes SQL classiques
               ▼
┌───────────────────────────────────────────────────────────┐
│   MariaDB Server  (Linux: /Sites/outils                       │
│                    Windows: C:\Sites\outils)                  │
│                                                               │
│  ┌────────────────┐   ┌─────────────────────────────┐     │
│  │  Buffer Pool    │   │   Key Management Plugin       │     │
│  │  (données en    │   │   file_key_mgmt / aws / vault  │     │
│  │   clair en      │◄──│                               │     │
│  │   mémoire)      │   │   .../encryption/keyfile.enc  │     │
│  └────────┬───────┘   └──────────────┬──────────────┘     │
│           │ AES encrypt/decrypt   │ clés                     │
│           ▼                       ▼                          │
│  ┌────────────────────────────────────────────────┐    │
│  │          Moteur de stockage                          │    │
│  │     InnoDB/XtraDB  |  Aria                           │    │
│  └────────────────┬───────────────────────────────┘    │
└─────────────────┼────────────────────────────────────────┘
                  │  Données chiffrées (AES)
                  ▼
┌───────────────────────────────────────────────────────────┐
│   Système de fichiers / Disque du serveur client              │
│                                                               │
│   Linux  : /Sites/outils/MariaDB<version>/data/                                │
│   Windows: C:\Sites\outils\MariaDB<version>\data\                              │
│                                                               │
│   .ibd  ibdata1  ib_logfile*  binlog  aria files              │
│          *** TOUT EST CHIFFRÉ ***                             │
│                                                               │
│   + LUKS (Linux) ou BitLocker (Windows) = double couche       │
└───────────────────────────────────────────────────────────┘
```
