# Justification du retrait de H-ISAC du plan de veille (§3.2)

Document à joindre au ticket Jira R8 (rattaché à SEC-THREATINTEL-2026-06 / CICD-170).

## Contexte

H-ISAC (Health Information Sharing and Analysis Center) figure au plan `plan_revue_mensuel_v2.md` §3.2 comme source de veille, à accès membre. L'accès n'a jamais été activé et la source est marquée « non activé » dans les revues mensuelles de mai et juin 2026 (`sources_consultees_2026-05.md`, `rapport_threat_intel_june2026.md`).

Coût d'adhésion : 2000 $/an.

## Analyse de couverture

Le plan §3.2 couvre déjà, avec des sources actives et gratuites, le même secteur (santé / dispositifs médicaux) :

| Source | Périmètre |
|--------|-----------|
| CISA ICS Medical Advisories | Vulnérabilités dispositifs médicaux, push continu |
| FDA Medical Device Safety | Alertes sécurité dispositifs |
| FDA Cybersecurity Alerts | Alertes cybersécurité dispositifs |
| HHS HC3 | Coordination cybersécurité secteur santé (US) |
| ENISA Health sector | Secteur santé (UE) |
| ANSM Cybersécurité DM | Dispositifs médicaux (FR) |

Ces 6 sources recoupent largement l'objet de H-ISAC (partage d'information cybersécurité secteur santé).

## Analyse du périmètre technique OneOrtho

Le processus de veille couvre une chaîne de traitement DICOM purement numérique (planification d'implant), sans exploitation de réseau clinique (PACS, EHR, réseau hospitalier). H-ISAC apporte le plus de valeur sur le partage d'indicateurs de compromission (IOC) entre opérateurs de soins (ransomware, APT ciblant les établissements de santé) — un périmètre hors du champ d'exposition d'OneOrtho en tant qu'éditeur de logiciel de planification.

## Point réglementaire (FDA 510(k))

La guidance FDA « Cybersecurity in Medical Devices : Quality System Considerations and Content of Premarket Submissions » (2023) impose un programme de gestion des vulnérabilités, un SBOM et une politique de divulgation coordonnée. Elle ne mandate pas d'adhésion à un ISAO/ISAC nommé.

**Non vérifié dans ce repo** : cette lecture s'appuie sur la connaissance générale de la guidance, pas sur un document source présent dans le repo. À faire confirmer par les Affaires Réglementaires avant de citer ce point dans un dossier de soumission 510(k).

## Décision recommandée

Retirer H-ISAC du plan §3.2. Ne pas engager les 2000 $/an — aucune valeur ajoutée démontrée sur le périmètre réel, au regard des sources déjà actives.

## Actions associées

* Ticket Jira R8 (à créer) : validation formelle du retrait par le Responsable Numérique
* Mise à jour de `plan_revue_mensuel_v2.md` §3.2 (suppression de la ligne H-ISAC) — non faite à ce stade, en attente de validation
* Si le point doit apparaître dans un dossier 510(k) : confirmation RA à tracer séparément

## Traçabilité

Origine : Revue Threat Intelligence 2026-06 (SEC-THREATINTEL-2026-06 / CICD-170), ticket de recommandation R8 (`tickets_recommandations_june2026.md`).
