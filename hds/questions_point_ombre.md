OneOrtho
Logo 

Comité Technique — Partenariat AVA6 

 

AVA6 — Questions & Points d'ombre 

Analyse des zones grises contractuelles, des services facturés et des responsabilités 

 

Informations du document 

Objet 

Clarification des contrats AVA6 — services, périmètres, responsabilités 

Destinataires 

IT Manager OneOrtho · Comité technique · Référent AVA6 

Documents source 

Contrat AVA6 signé · Infogérance 2019 · Renouvellement 2025-2026 · EPDR REDSOC · SIEM · Avenant scalabilité 

Date d'analyse 

Avril 2026 

Statut 

Document de travail — à compléter avec réponses AVA6 

Classification 

CONFIDENTIEL — Usage interne OneOrtho 

 

Légende des priorités 

CRITIQUE 

Impact direct sur la conformité HDS, la sécurité ou la facturation — à clarifier avant le prochain renouvellement 

IMPORTANT 

Responsabilité ambiguë ou service mal défini — à clarifier dans les 3 prochains mois 

À CLARIFIER 

Point de vigilance ou amélioration — à aborder lors de la prochaine revue contractuelle annuelle 

 

Synthèse — Vue d'ensemble des points d'ombre 

L'analyse des contrats AVA6 et de la cartographie infrastructure révèle 40 questions réparties en 4 domaines. Le tableau ci-dessous donne une vision consolidée avant le détail question par question. 

 

Domaine 

CRITIQUE 

IMPORTANT 

À CLARIFIER 

Questions clés 

Services facturés (Q1–Q11) 

4 

5 

2 

WAF, MCO N1, sauvegarde volumétrie, licences 

Responsabilités (Q12–Q24) 

4 

7 

2 

Notification CNIL, RDP exposés, tests restauration, SIEM périmètre 

Conformité HDS (Q25–Q32) 

2 

4 

2 

Contrat HDS formel, PRA/PCA, certification périmètre 

Commercial & renouvellement (Q33–Q40) 

1 

4 

3 

Signature renouvellement, scalabilité, réversibilité 

TOTAL 

11 

20 

9 

40 questions — à adresser avec AVA6 

 

→ 11 points CRITIQUE à adresser en priorité lors d'une réunion AVA6 dans les 30 jours. 

 

1. Services facturés — Périmètre et cohérence 

Ces questions portent sur ce qu'AVA6 facture réellement vs ce qui est livré. Certaines lignes de facturation sont absentes des contrats ou mal définies. 

 

N° 

Priorité 

Question / Point d'ombre 

Contexte contractuel 

Impact 

Commentaire 

Q1 

CRITIQUE 

Le WAF (Web Application Firewall) est-il inclus dans le contrat d'hébergement actuel, ou est-ce un service séparé à contractualiser ? 

Absent des contrats fournis. Mentionné dans l'offre 2019 mais non confirmé dans le renouvellement 2025-2026. 

Conformité HDS art. 9 — protection des apps web exposant des données de santé 

 

Q2 

CRITIQUE 

Qu'est-ce que le "Cluster Firewall mutualisé" (22 €/machine/mois) couvre exactement ? Qui peut demander des ouvertures de flux? Quel est le délai d'application ? 

Ligne présente dans tous les devis client. Mutualisé = partagé avec d'autres clients AVA6? 

Sécurité réseau, ségrégation inter-clients, conformité HDS 

 

Q3 

CRITIQUE 

Le "MCO N1" (30 €/VM/mois) : quelles actions sont incluses vs facturées en régie ? Y a-t-il un catalogue de services N1/N2 ? 

Présent dans tous les devis. Aucune définition du périmètre N1 dans les contrats fournis. 

Risque de double facturation ou de "hors périmètre" surprises 

 

Q4 

CRITIQUE 

La sauvegarde "Volumétrie 100 Go" : est-elle calculée avant ou après déduplication/compression ? Quel outil ? Quels serveurs sont inclus ? 

Facturée par tranches de 100 Go avec rétention 15j. Cartographie montre des taux d'utilisation très élevés (DSPROD 1220 Go, GDPROD 2662 Go). 

Coût caché si volumétrie réelle > volumétrie facturée 

 

Q5 

IMPORTANT 

Les licences Windows Server "par vCPU" (7,71 €) : comment sont-elles décomptées pour les serveurs 4 vCPU (STRYKERPROD, DSPRODNEW, etc.) ? Sont-elles facturées en SPLA? 

Devis type client : "3 licences" pour 6 vCPU. Les serveurs récents (Win 2025) ont 4 vCPU. 

Sur/sous-facturation possible, risque de non-conformité licence Microsoft 

 

Q6 

IMPORTANT 

L'EPDR "Service managé par périphérique" (2 à 4,59 €/périph/mois) : quels serveurs sont couverts exactement ? Le serveur CALCUL (Ubuntu) est-il inclus ? 

Contrat REDSOC renouvellement 2025. Cartographie montre 21+ VMs. Ubuntu 24.04 supporte WatchGuard EPDR ? 

VMs non protégées = non-conformité HDS art. 8 

 

Q7 

IMPORTANT 

Le serveur ONEORTHO-PREPROD (ONE-IISPREPROD) est-il bien dans le périmètre de facturation ? Il n'apparaît pas dans tous les devis clients. 

Présent dans la cartographie, IP 172.16.48.21, 600 Go HDD à 80%. Introuvable dans les lignes de coûts. 

Service fourni mais potentiellement non facturé ou non suivi 

 

Q8 

IMPORTANT 

Les serveurs CICD (QUALITY, JENKINS) : sous quel contrat sont-ils ? Sont-ils hébergés chez AVA6 ou ailleurs ? Quelle est leur configuration ? 

Présents dans la cartographie mais sans IP, OS, ni configuration. Hors périmètre AVA6 ? 

Périmètre de sécurité incomplet si non couverts par SIEM/EPDR 

 

Q9 

IMPORTANT 

Le service EFS "Nextcloud" (100 €/mois pour 50 utilisateurs) : est-il toujours actif ? Qui gère les accès utilisateurs ? KILIAN  

Présent dans la feuille de coûts décembre 2025. Aucune mention dans les contrats infogérance. 

Service actif non documenté dans les RACI 

 

Q10 

À CLARIFIER 

La "Sauvegarde VM – Rétention 15 jours" : les environnements préprod sont-ils tous sauvegardés ? La rétention est-elle la même pour prod et préprod ? 

L'offre 2019 pose la question pour la préprod. Coûts décembre 2025 notent : "A changer pour conserver que la production ?" 

Coût inutile si préprod sauvegardée sans utilité réelle 

La réponse est OUI à priori mais on peu confirmé 

 

Q11 

À CLARIFIER 

Qu'est-ce que le "Stockage Full Flash – 100 Go" vs le stockage standard HDD ? Tous les serveurs bénéficient-ils du Full Flash ? 

Certaines VMs sont en SSD, d'autres en HDD (cf. cartographie). Le devis mentionne "Full Flash" mais la réalité semble mixte. 

Performances et coût — les clients prod critiques sont-ils bien en SSD ? 

Techniquement Stokcage full flash est la techno utilisée dans SSD, donc, à voir comment il facture du HDD 

2. Responsabilités — Zones d'ombre opérationnelles 

Ces questions portent sur les ambiguïtés de responsabilité entre OneOrtho et AVA6 dans la gestion quotidienne de l'infrastructure, notamment en cas d'incident de sécurité. 

 

N° 

Priorité 

Question / Point d'ombre 

Contexte contractuel 

Impact 

 

Q12 

CRITIQUE 

En cas d'incident de sécurité sur une VM AVA6 (ransomware, intrusion), qui déclare l'incident à la CNIL ? Dans quel délai ? Qui est le responsable de traitement HDS ? 

HDS art. 10 : notification CNIL obligatoire sous 72h en cas de violation de données de santé. Non explicité dans les contrats fournis. 

Risque juridique majeur — amende CNIL, responsabilité HDS 

 

Q13 

CRITIQUE 

Les RDP exposés directement en IP publique (195.42.148.160/161 ports 33900-33906) : qui est responsable de leur sécurisation ? AVA6 a-t-il un engagement de détection de brute-force sur ces ports ? 

Cartographie : 15+ serveurs exposent RDP publiquement sans bastion ni VPN obligatoire. Risque élevé de compromission. 

Incident de sécurité potentiel — données de santé exposées 

 

Q14 

CRITIQUE 

Quel est le délai contractuel de notification par AVA6 en cas d'incident de sécurité détecté par le SIEM/REDSOC affectant les VMs OneOrtho ? 

Documentation SIEM v1.0 fournie, mais aucun SLA de notification trouvé dans les contrats. 

Conformité HDS, gestion de crise, communication clients 

 

Q15 

CRITIQUE 

La destruction sécurisée des données en fin de contrat : existe-t-il une procédure documentée et signée avec AVA6 ? Quel est le délai ? Y a-t-il un certificat de destruction? 

Exigence HDS art. 5. Non mentionné dans les contrats fournis. 

Non-conformité HDS — données de santé résiduelles chez l'hébergeur 

Le doc d’hébergement stipule un délai de 1 mois pour sauvegarde par OneOrtho avant desctruction de AVA6 

Q16 

IMPORTANT 

Le WAF : qui définit les règles de filtrage ? Qui gère les faux positifs bloquant des accès légitimes ? Quel est le processus de demande de modification de règle ? 

Si WAF mutualisé AVA6 : règles probablement génériques, pas adaptées aux spécificités de One-platform. 

Blocage production, délai de traitement des faux positifs 

 

Q17 

IMPORTANT 

Les alertes disque critique (GDPROD 96%, DSPRODNEW 94%, SAASPREPROD 97%) : qui est responsable d'alerter ? Y a-t-il un seuil contractuel déclenchant une notification automatique ? 

Cartographie au 10/04/2026 montre 8 serveurs >80%. Aucun SLA de surveillance disque trouvé. 

Perte de données, indisponibilité service client 

 

Q18 

IMPORTANT 

Les tests de restauration trimestriels : qui les déclenche, qui y assiste, qui valide le résultat ? Les rapports sont-ils transmis automatiquement par AVA6 ? 

Exigence HDS art. 9. Non formalisé dans les contrats fournis. 

Conformité HDS — absence de preuve = non-conformité audit 

 

Q19 

IMPORTANT 

Les fenêtres de maintenance AVA6 (patching OS) : quel est le préavis ? Les déploiements OneOrtho en cours sont-ils interrompus ? Qui valide la fenêtre ? 

MCO inclus dans le contrat mais procédure de maintenance non détaillée. 

Indisponibilité imprévue des serveurs clients 

 

Q20 

IMPORTANT 

Les serveurs AD01&2 tournent sur Windows Server 2016: AVA6 est-il au courant? Assure-t-il le MCO sur un OS en fin de mainstream support? 

Microsoft mainstream support Windows 2016 terminé en janvier 2022. Extended support jusqu'en janvier 2027. 

Sécurité, patches critiques, conformité HDS 

 

Q21 

IMPORTANT 

Le SIEM couvre-t-il 100% des VMs OneOrtho (y compris CALCUL Ubuntu, CLIPPER, PREPROD) ou uniquement un sous-ensemble? Quelle est la liste exhaustive des sources collectées ? 

Documentation SIEM v1.0 disponible mais périmètre exact non vérifié par rapport à la cartographie. 

Angles morts de détection — incident non détecté 

 

Q22 

IMPORTANT 

L'isolation d'une VM compromise par le SOC REDSOC : nécessite-t-elle une validation préalable de OneOrtho ou AVA6 peut-il agir de manière autonome ? Dans quel délai ? 

Procédure de réponse aux incidents non formalisée dans les contrats fournis. 

Indisponibilité imprévue en cas d'action SOC non concertée 

 

Q23 

À CLARIFIER 

Les accès AVA6 (techniciens, admins) aux VMs OneOrtho sont-ils tracés et audités ? OneOrtho peut-il accéder à ces logs d'accès AVA6 ? 

Exigence HDS art. 6 — traçabilité des accès hébergeur. Non mentionné dans les contrats. 

Conformité HDS, détection accès non autorisés chez l'hébergeur 

 

Q24 

À CLARIFIER 

AVA6 peut-il sous-traiter tout ou partie des services (SIEM, MCO) à un tiers ? OneOrtho en est-il informé et a-t-il son agrément ? 

Non mentionné dans les contrats fournis. HDS exige la notification de tout sous-traitant. 

Conformité HDS, chaîne de responsabilité 

 

 

3. Conformité HDS — Exigences réglementaires 

Ces questions portent sur les obligations légales liées à l'hébergement de données de santé. Certaines non-conformités peuvent engager la responsabilité pénale de OneOrtho. 

 

N° 

Priorité 

Question / Point d'ombre 

Contexte contractuel 

Impact 

Q25 

CRITIQUE 

OneOrtho a-t-il signé un contrat spécifique en tant qu'hébergeur de données de santé avec AVA6 (contrat de sous-traitance HDS) ? Est-ce distinct du contrat d'infogérance ? 

La certification HDS d'AVA6 est attestée (CGCLOUD nov. 2025). Mais le contrat signé doit comporter les clauses HDS obligatoires (art. L.1111-8 CSP). 

Sans contrat HDS explicite : invalidité de l'hébergement, risque pénal 

Q26 

CRITIQUE 

Le PRA/PCA (Plan de Reprise/Continuité d'Activité) avec AVA6 : existe-t-il un document formel signé ? A-t-il été testé ? Quels sont les RTO/RPO contractuels pour chaque niveau de sinistre ? 

RTO 4h / RPO 24h mentionnés oralement. Non trouvés dans les contrats fournis. 

Conformité HDS art. 12, engagements contractuels 

Q27 

IMPORTANT 

Les certifications AVA6 (HDS nov. 2025, ISO 27001 nov. 2023) : couvrent-elles bien le datacenter qui héberge les VMs OneOrtho ? Les certificats fournis concernent-ils la bonne entité juridique ? 

Certificat HDS : CGCLOUD (entité). SynAApS pour ISO 27001. Vérifier que l'entité contractante est bien dans le périmètre de certification. 

Hébergement HDS invalide si entité hors périmètre certifié 

Q28 

IMPORTANT 

Le Registre des Traitements OneOrtho mentionne-t-il AVA6 comme sous-traitant ? La liste des données de santé hébergées est-elle à jour ? 

RGPD art. 28 + HDS : obligation de tenir un registre des sous-traitants de données de santé. 

Non-conformité RGPD/HDS, risque CNIL 

Q29 

IMPORTANT 

OneOrtho peut-il demander un audit de conformité chez AVA6 (audit de site, rapport SOC 2, etc.) ? Cette clause est-elle dans le contrat ? 

Standard HDS : le responsable de traitement doit pouvoir auditer son hébergeur. Non trouvé dans les contrats. 

Impossibilité de prouver la conformité en cas d'audit CNIL ou certification client 

Q30 

IMPORTANT 

Les logs du SIEM sont-ils conservés en dehors de l'infrastructure AVA6 (backup offsite) ? En cas de sinistre AVA6, les logs sont-ils préservés ? 

Exigence HDS art. 7 : conservation des logs d'accès. Non mentionné dans les contrats. 

Perte de preuves en cas d'incident chez AVA6 

Q31 

À CLARIFIER 

AVA6 réalise-t-il des tests d'intrusion sur son infrastructure (dont les VMs OneOrtho) ? Les rapports sont-ils communiqués à OneOrtho ? 

HDS recommande des tests de pénétration réguliers. OneOrtho réalise les siens mais quid de l'infrastructure AVA6 ? 

Angles morts sécurité côté hébergeur 

Q32 

À CLARIFIER 

En cas de réquisition judiciaire ou accès par une autorité publique aux données hébergées : AVA6 est-il tenu d'informer OneOrtho préalablement ? Cette clause est-elle dans le contrat ? 

RGPD art. 28.3(a) : le sous-traitant doit informer le responsable de traitement sauf interdiction légale. 

Données de santé sensibles — procédure à définir 

 

4. Questions commerciales & renouvellement contractuel 

Ces questions portent sur les aspects financiers, la négociation et les modalités du contrat AVA6 en vigueur et à venir. 

 

N° 

Priorité 

Question / Point d'ombre 

Contexte contractuel 

Impact 

Q33 

CRITIQUE 

Le renouvellement Infogérance 2025-2026 : a-t-il bien été signé par les deux parties ? Les conditions tarifaires ont-elles changé par rapport à 2019 ? 

Document "Renouvellement Infogérance 2025 2026 v1.0" présent mais statut de signature non vérifié. 

Engagement contractuel non formalisé = service sans base légale 

Q34 

IMPORTANT 

L'avenant scalabilité (AVAOOM20) : quelles sont les limites de scalabilité (max vCPU, RAM, stockage) ? Quel est le délai de provisioning d'une nouvelle VM ? 

Avenant signé présent. Limites et délais non visibles dans le résumé. 

Planification capacité clients, onboarding nouveaux clients 

Q35 

IMPORTANT 

La facturation de GDPROD (96,3% disque, 2 662 Go HDD) : avons-nous une alerte contractuelle ou sommes-nous hors quota sans le savoir ? Quel est le mécanisme d'alerte de dépassement ? 

Feuille de coûts montre 28 tranches de 100 Go pour GDPROD. Taux actuel 96% = quasi-saturation. 

Risque panne imminente, coût d'extension non budgété 

Q36 

IMPORTANT 

Le "frais de mise en place" AVA6 (990 € par nouveau serveur) : est-il toujours d'actualité dans le renouvellement 2025-2026 ? Peut-il être négocié pour les clients qui migreront vers One-platform v5 ? 

Présent dans le gabarit "Serveur type client Premium". Non confirmé dans le renouvellement. 

Budget onboarding nouveaux clients 

Q37 

IMPORTANT 

Les serveurs avec OS Windows Server 2016/2017 encore en production : AVA6 applique-t-il encore les patches de sécurité (extended support) ? Ces patches sont-ils inclus dans le MCO ? 

8 serveurs sur 21 tournent sur Win 2016/2017 (mainstream support terminé). Extended support Microsoft jusqu'en 2027. 

Failles de sécurité non patchées, conformité HDS 

Q38 

À CLARIFIER 

La migration vers Windows Server 2025 est en cours (DSPRODNEW, STRYKERPROD, STRYKERPREPROD...) : AVA6 facture-t-il les deux serveurs (ancien + nouveau) pendant la période de transition ? 

Cartographie montre DSPROD (2016) + DSPRODNEW (2025) pour le même client Dedienne. 

Double facturation potentielle pendant la migration 

Q39 

À CLARIFIER 

Le contrat AVA6 prévoit-il une clause de réversibilité (export des données et VMs en fin de contrat) ? Dans quel format et dans quel délai ? 

Non mentionné dans les contrats fournis. Exigence HDS art. 5 pour la portabilité des données. 

Risque de dépendance (vendor lock-in) et coût de sortie 

Q40 

À CLARIFIER 

Existe-t-il un portail ou reporting AVA6 accessible en autonomie par OneOrtho (consommation, alertes, tickets) ? Sinon, comment sont remontés les incidents N1 ? 

Non mentionné dans les contrats. Le suivi semble se faire uniquement par échanges bilatéraux. 

Visibilité opérationnelle, réactivité, traçabilité des incidents 

 

5. Plan d'action recommandé 

Sur la base des 40 questions identifiées, voici les actions prioritaires à engager avec AVA6 et en interne chez OneOrtho. 

 

Action 

Description 

Échéance 

Responsable 

1. Réunion de clarification AVA6 

Organiser une réunion technique avec AVA6 pour adresser les 11 questions CRITIQUE (Q1, Q2, Q3, Q12, Q13, Q14, Q15, Q25, Q26, Q33, Q34) 

< 30 jours 

CTO + Comité technique 

2. Audit du contrat HDS 

Vérifier la présence des clauses HDS obligatoires dans le contrat signé (sous-traitance, notification, réversibilité) 

< 30 jours 

CTO 

3. Inventaire services réels vs facturés 

Confronter la cartographie infra avec les factures AVA6 des 12 derniers mois pour détecter écarts 

< 45 jours 

Comité technique 

4. Sécurisation accès RDP 

Migrer les accès RDP exposés (195.42.148.160/161) vers VPN ou bastion SSH — plan de migration à chiffrer avec AVA6 

< 60 jours 

Comité technique + AVA6 

5. Formalisation PRA/PCA 

Obtenir et signer un document PRA/PCA formel avec AVA6 incluant RTO/RPO par niveau de sinistre 

< 60 jours 

CTO + AVA6 

6. Extension stockage urgente 

Déclencher les demandes d'extension pour GDPROD (96%), SAASPREPROD (97%), DSPRODNEW (94%) 

IMMÉDIAT 

Comité technique 

7. Revue annuelle contractuelle 

Inclure toutes les questions "À CLARIFIER" dans l'ordre du jour de la prochaine revue contractuelle annuelle AVA6 

< 6 mois 

CTO 

 

Ce document est destiné à préparer la prochaine réunion technique avec AVA6 et la revue contractuelle. Il est recommandé de l'envoyer à AVA6 en amont pour obtenir des réponses écrites formelles. 