# Analyse et optimisation du disque

## 📊 État actuel du disque

**Total:** 80 GB (43 GB utilisé, 37 GB libre)

### `/var/lib/` - Les gros consommateurs

| Répertoire | Taille | Actions possibles |
|-----------|--------|------------------|
| **docker** | 2.9 GB | ✅ À GARDER (nécessaire) |
| **snapd** | 1.4 GB | ❌ À SUPPRIMER (optionnel) |
| **postgresql** | 338 MB | ✅ À GARDER (SonarQube + DependencyTrack) |
| **apt** | 298 MB | ⚠️ À NETTOYER (~50% récupérable) |
| **dpkg** | 40 MB | ⚠️ À NETTOYER |
| **command-not-found** | 3.4 MB | ❌ À SUPPRIMER |

### `/var/cache/` - Les petits consommateurs

| Répertoire | Taille | Actions |
|-----------|--------|---------|
| **apt** | 131 MB | ⚠️ À NETTOYER |
| **snapd** | 4.4 MB | Si snapd supprimé |
| **fwupd** | 1.4 MB | ⚠️ À NETTOYER |
| **apparmor** | 2.7 MB | À laisser |

---

## 🎯 Opportunités de nettoyage

### SÛRS à nettoyer (pas de risque)

1. **APT cache** — 131 MB + 298 MB = **~430 MB**
   ```bash
   sudo apt-get clean
   sudo apt-get autoclean
   ```

2. **Ancien journaux systemd** — ~50-100 MB
   ```bash
   sudo journalctl --vacuum=30d
   ```

3. **Fichiers temp** — ~50 MB
   ```bash
   sudo rm -rf /tmp/* /var/tmp/*
   ```

4. **Vieux fichiers log** — ~100-200 MB
   ```bash
   find /var/log -type f -name "*.gz" -mtime +30 -delete
   ```

5. **command-not-found** — 3.4 MB
   ```bash
   sudo apt-get purge -y command-not-found
   ```

**TOTAL sûr:** ~700 MB - 1 GB

---

### OPTIONNEL mais efficace

**Snapd** — 1.4 GB (+ 4.4 MB cache)
```bash
sudo snap remove snapd --purge
sudo apt-get purge -y snapd
```

**Raison:** Snapd utilise beaucoup de ressources et de disque pour peu de bénéfice. Rarement nécessaire sur un serveur.

**TOTAL optionnel:** ~1.4 GB

---

### À CONSERVER (ne pas toucher)

- ✅ `/var/lib/docker` (2.9 GB) — Nécessaire pour Docker Compose
- ✅ `/var/lib/postgresql` (338 MB) — Bases de données SonarQube/DependencyTrack
- ✅ `/var/lib/nginx` (4 MB) — Configuration Nginx
- ✅ `/var/lib/containerd` (188 KB) — Runtime de container

---

## 📈 Estimation gains

### Scénario 1: Nettoyage sûr seul

```
Avant:  43 GB utilisé, 37 GB libre
Après:  42 GB utilisé, 38 GB libre
Gain:   ~1 GB (pour DependencyTrack)
```

✅ **Recommandé — aucun risque**

---

### Scénario 2: Nettoyage sûr + Snapd

```
Avant:  43 GB utilisé, 37 GB libre
Après:  41.5 GB utilisé, 38.5 GB libre
Gain:   ~1.5 GB
```

✅ **Recommandé — Snapd peu utile sur serveur**

---

## 🚀 Script d'optimisation

Exécuter:
```bash
chmod +x disk-optimization.sh
./disk-optimization.sh
```

**Ce que ça fait:**
1. Nettoie cache APT
2. Supprime vieux kernels
3. Nettoie journaux systemd
4. Nettoie fichiers temp
5. Nettoie anciens logs
6. (Optionnel) Supprime snapd

**Durée:** 2-3 minutes
**Résultat:** 700 MB - 1.4 GB libérés

---

## 📋 Ordre d'exécution recommandé

```
Phase 1: Cleanup Jenkins      (phase1-cleanup.sh)
Phase 2: Cleanup Datadog/LXD  (phase1-cleanup.sh)
Phase 3: Optimisation disque  (disk-optimization.sh)  ← Vous êtes ici
Phase 4: Vérifier OVH upgrade (phase2-verify.sh)
Phase 5: Déployer DT          (01-deployment-dependencytrack.md)
```

---

## ✅ Après optimisation

```bash
# Vérifier l'espace
df -h /

# Doit afficher ~38-40 GB libre (au lieu de 37 GB)

# Vérifier pas de problèmes
sudo systemctl status docker      # (active)
sudo systemctl status postgresql  # (active)
```

---

## 🛑 Ne pas nettoyer

❌ `/var/lib/docker` — C'est toute votre virtualisation

❌ `/var/lib/postgresql` — C'est vos bases SonarQube + DependencyTrack

❌ `/etc/` — Config système

❌ `/home/` — Données utilisateurs

---

## Résumé

| Action | Gain | Risque | Recommandé |
|--------|------|--------|-----------|
| Nettoyer APT | 430 MB | ✅ Nul | OUI |
| Nettoyer logs | 150 MB | ✅ Nul | OUI |
| Nettoyer temp | 50 MB | ✅ Nul | OUI |
| Supprimer snapd | 1.4 GB | ⚠️ Mineur | OUI |
| **TOTAL** | **~2 GB** | **Bas** | **OUI** |

