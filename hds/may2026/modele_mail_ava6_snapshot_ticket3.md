# Modèle de mail à AVA6 — Information patch sécurité + demande de snapshot (Ticket 3)

Usage : informer AVA6 (hébergeur) qu'une application **interne** de correctifs de sécurité Windows aura lieu sur des serveurs préprod et prod, et demander un **snapshot hyperviseur préalable** (le snapshot est au niveau hyperviseur, du ressort d'AVA6). OneOrtho applique le patch et valide ; AVA6 ne fait pas l'application.

Adapter les champs entre {{...}}. Remplace le `modele_mail_ava6_ticket3.md` (obsolète : demande d'application).

---

**À** : {{contact exploitation AVA6}}
**Cc** : {{Responsable Numérique OneOrtho}}, {{équipe infrastructure}}
**Objet** : [INFO + Demande snapshot] Application interne de correctifs sécurité Windows — préprod & prod (réf. CICD-169)

---

Bonjour,

Dans le cadre de notre revue mensuelle de sécurité, OneOrtho va appliquer **en interne** (MCO OS assuré par OneOrtho) les correctifs Windows corrigeant 6 vulnérabilités critiques d'exécution de code à distance (Patch Tuesday). L'application et le redémarrage seront pilotés par nos soins, en deux vagues, dans la **fenêtre 02h–03h** pour ne pas impacter les activités clients.

**Ce que nous vous demandons :** prendre un **snapshot hyperviseur** de chaque VM listée **avant le début de la fenêtre**, afin de disposer d'un point de retour arrière. Merci de confirmer que ces VM sont bien sur un hyperviseur que vous gérez et que le snapshot est possible.

**Planning prévu :**

| Vague | Nuit | Snapshot attendu avant | Serveurs |
|-------|------|------------------------|----------|
| 1 — Préprod | {{nuit N — JJ/MM/AAAA}} | {{JJ/MM}} 01:30 | WEBPREPRODDEDIENNE, WEBPREPRODSTRYKER, WEBPREPRODI2B, WEBPREPRODFH, WEBPREPRODEVOLUTIS, WEBPREPRODKERI, WEBPREPRODLEPIN |
| 2 — Prod | {{nuit N+1 — JJ/MM/AAAA}} | {{JJ/MM}} 01:30 | WEBPRODGLOBALD, WEBPRODSTRYKER, WEBPRODI2B, WEBPRODFH, WEBPRODEVOLUTIS, WEBPRODKERI, WEBPRODLEPINE |

**Modalités du snapshot :**
- Nom conseillé : `pre-patch-TI-2026-05` (+ horodatage).
- À prendre **juste avant la fenêtre** (vers 01:30), avec quiescence/VSS si les outils invité le permettent.
- **Conservation** : ne pas supprimer avant notre feu vert. Nous validons l'état de chaque serveur le lendemain matin (build + disponibilité du portail) et vous confirmons la **suppression des snapshots** (ou, en cas de problème, une **demande de restauration**).
- Merci de vérifier au préalable l'**espace libre du datastore** (un snapshot grossit avec les écritures).

**Répartition (RACI) :**
- OneOrtho : application des correctifs, redémarrage, validation post-patch (A/R).
- AVA6 : snapshot préalable + conservation + restauration sur demande + suppression après notre validation (R sur l'infrastructure).
- Aucune action d'application/patch attendue de votre part.

Pouvez-vous confirmer la faisabilité et le créneau de prise des snapshots ? Cette opération est tracée sous la référence CICD-169 (revue Threat Intelligence 2026-05).

Cordialement,
{{Prénom NOM}}
{{Fonction — Service Numérique OneOrtho}}
{{coordonnées}}

---

## Notes d'usage

- N'inclure que les noms d'hôtes nécessaires ; aucune donnée patient ni secret.
- Si **OneOrtho a la main sur l'hyperviseur**, ce mail n'est pas nécessaire pour le snapshot : suivre §5.1bis de `procedure_application_patch_ticket3_windows.md` (snapshot pris en interne). Le mail reste alors utile en simple **information** (intervention nocturne sur des VM hébergées).
- Si des serveurs sont **physiques** (pas de snapshot possible), le préciser dans le mail et basculer sur une sauvegarde système interne (cf. §5.1bis).
- Conserver ce mail (envoi + réponse AVA6 confirmant les snapshots) comme **pièce probante** du Ticket 3 (cf. bordereau `index_pieces_probantes_2026-05.md`).
