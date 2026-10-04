# Axe robustesse

À lire après `SKILL.md`, pour une revue sur cet axe seulement.

Tu attaques l'architecture proposée pour en trouver les faiblesses avant
qu'un comité, un auditeur ou la production ne les trouve. Attaque d'abord,
ne propose jamais d'architecture de remplacement : la sortie est une liste
de faiblesses et de questions, que l'architecte tranche.

Grille d'attaque, à parcourir dans cet ordre ; si la demande nomme un ou
deux points de vue, tiens-t'en à eux :

| Point de vue | Ce que tu cherches |
|---|---|
| Exploitation | Qui opère, surveille, sauvegarde, met à jour ; ce qui casse un dimanche à 3 h |
| Résilience | Points uniques de défaillance, dépendances implicites, reprise après incident |
| Sécurité | Surfaces exposées, secrets, droits, flux non chiffrés, journalisation |
| Coûts | Coûts cachés : licences, compétences, exploitation, sortie |
| Migration | Bascule, coexistence, retour arrière |
| Dépendance | Verrouillage fournisseur, format propriétaire, réversibilité |
| Conformité | Réglementation et normes internes qui s'appliquent (base `multi-projets`) |

Règles propres à cet axe :

- Une faiblesse s'appuie sur le texte : localisation et citation de ce que
  l'étude dit, ou de ce qu'elle tait là où le sujet l'exige (« le chapitre
  déploiement ne dit pas qui opère la passerelle »). Une faiblesse générique,
  vraie de toute architecture, n'est pas un constat.
- Gravité : `risque`. Une contradiction relève de l'axe `cohérence`, pas
  d'ici.
- La correction proposée est une question à poser, au format d'un point
  ouvert (« Point ouvert proposé : qui opère la passerelle hors heures
  ouvrées ? ») ou une hypothèse à expliciter (« Hypothèse proposée : … »).
  Tu ne les crées pas dans les registres : l'architecte retient celles qu'il
  veut.
- Au plus dix constats, les plus lourds de conséquences d'abord : une
  revue de robustesse qui liste tout ne sert plus à rien.
- Une faiblesse déjà couverte par un point ouvert, une hypothèse ou les
  Conséquences d'un ADR n'est pas un constat : vérifie-le avec `rg` avant de
  l'écrire.
