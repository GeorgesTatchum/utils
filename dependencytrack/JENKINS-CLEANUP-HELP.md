# Jenkins Cleanup Troubleshooting

## Problème: Group 'jenkins' is not empty!

**Cause:** Jenkins a laissé des fichiers/répertoires qui empêchent la suppression complète du user/group.

**Solution:** Utiliser le script de correction fourni.

---

## Solution 1: Script automatisé (RECOMMANDÉ)

```bash
cd /home/gtatchum/Sites/wwwroot/utils/dependencytrack

# Exécuter le script de correction
./jenkins-cleanup-fix.sh
```

**Durée:** 2 minutes
**Résultat:** Jenkins complètement supprimé

---

## Solution 2: Commandes manuelles (si script échoue)

### Étape 1: Arrêter Jenkins

```bash
# Arrêter le service
sudo systemctl stop jenkins

# Arrêter les processus
sudo pkill -9 -f jenkins

# Vérifier (aucun résultat = bon)
ps aux | grep jenkins
```

### Étape 2: Supprimer les fichiers

```bash
# Supprimer les répertoires Jenkins
sudo rm -rf /var/cache/jenkins
sudo rm -rf /var/lib/jenkins
sudo rm -rf /var/log/jenkins
sudo rm -rf /etc/jenkins

# Supprimer les exécutables
sudo rm -f /usr/sbin/jenkins
sudo rm -f /usr/share/java/jenkins*

# Supprimer les configs systemd
sudo rm -f /etc/systemd/system/jenkins.service
sudo rm -f /usr/lib/systemd/system/jenkins.service
sudo rm -f /etc/default/jenkins
```

### Étape 3: Supprimer l'user Jenkins

```bash
# Lister les fichiers appartenant à jenkins (optionnel)
find / -user jenkins 2>/dev/null | head -20

# Supprimer l'user
sudo userdel -r jenkins 2>/dev/null || sudo userdel jenkins
```

### Étape 4: Supprimer le group

```bash
# Supprimer le group
sudo groupdel jenkins 2>/dev/null || echo "Group jenkins may not exist or user still exists"
```

### Étape 5: Recharger systemd

```bash
sudo systemctl daemon-reload
sudo systemctl reset-failed
```

### Étape 6: Vérifier

```bash
# Vérifier Jenkins disparu
ps aux | grep jenkins              # (aucun résultat)
id jenkins                          # (user not found)
getent group jenkins                # (group not found)
which jenkins                       # (not found)
```

---

## Résultat attendu après la procédure

```bash
# User supprimé
$ id jenkins
id: jenkins: no such user

# Group supprimé
$ getent group jenkins
(aucun résultat)

# Aucun processus Jenkins
$ ps aux | grep jenkins
(aucun résultat)

# Aucun fichier Jenkins
$ ls /etc/jenkins
ls: cannot access '/etc/jenkins': No such file or directory
```

---

## Si ça ne marche toujours pas

### Option 1: Forcer la suppression du group

```bash
# Si le group est verrouillé, essayer:
sudo groupdel -f jenkins 2>/dev/null || true

# Ou si c'est sur un système Debian/Ubuntu spécifique:
sudo delgroup --force jenkins 2>/dev/null || true
```

### Option 2: Vérifier les fichiers restants

```bash
# Chercher les fichiers appartenant au user/group jenkins
find / -user jenkins 2>/dev/null | xargs sudo rm -rf
find / -group jenkins 2>/dev/null | xargs sudo rm -rf

# Puis réessayer suppression du group
sudo groupdel jenkins
```

### Option 3: Nettoyer manuellement l'entry du group

```bash
# Éditer le fichier group
sudo nano /etc/group

# Chercher la ligne:
# jenkins:x:XXX:

# La supprimer et sauvegarder
```

---

## Après le nettoyage Jenkins

Vérifier que la Phase 1 peut continuer:

```bash
# Vérifier RAM libérée
free -h

# Vérifier SonarQube toujours en place
sudo systemctl is-active sonarqube

# Vérifier PostgreSQL
sudo systemctl is-active postgresql

# Vérifier Docker
docker ps
```

---

## Notes

- **Jenkins est bien supprimé** une fois que `id jenkins` retourne "user not found"
- Les fichiers restants dans les snaps peuvent être ignorés
- La RAM doit être libérée (vérifier avec `free -h`)
- Les services critiques (SonarQube, PostgreSQL, Docker) doivent rester actifs

---

## Prochaine étape

Une fois Jenkins complètement supprimé:

1. Relancer `phase1-cleanup.sh` (le reste du script)
2. Ou continuer manuellement avec Datadog, LXD, etc.

