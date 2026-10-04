---
name: revue-etude
description: Relecture ciblée d'une étude d'architecture rédigée en AsciiDoc (doc-as-code), selon un axe précis — traçabilité, cohérence, sources, rendu, décision, robustesse ou concision —, avec vérification dans les bases de connaissances RAG (cadrage du projet, normes, réglementation). Utilise ce skill dès qu'on te demande de relire, vérifier, auditer, contrôler ou challenger une étude, un chapitre, une annexe, un registre (hypothèses, points ouverts, ADR) ou un diff, ou de la confronter à son cadrage ; aussi pour examiner une décision ou un ADR, chercher les faiblesses d'une architecture, ou dire ce qui peut être retiré ou allégé, même si le mot « revue » n'est pas employé.
---

# Revue d'étude d'architecture

Une revue utile produit peu de constats, chacun prouvé. Une relecture générale
produit des remarques vagues et consomme beaucoup de tokens. Travaille donc sur
un seul axe et un seul périmètre à la fois.

## Avant de commencer

1. Identifie l'axe (voir plus bas) et le périmètre : un fichier, un chapitre,
   un registre ou `git diff`. S'ils ne sont pas donnés, demande-les en une
   seule question ; propose par défaut l'axe `traçabilité` sur le diff.
2. Lance `tools/check.sh <maître>`. Ne reporte pas ce qu'il détecte déjà : xrefs
   sans ancre, includes, « § » en dur, restes de LaTeX et de Markdown, IDs de
   registre jamais cités (orphelins) ou cités sans xref (mentions nues).
3. Lis `AGENTS.md` et `normes/asciidoc.adoc` si ce n'est pas déjà fait ;
   les autres fichiers de `normes/` seulement si l'axe les touche
   (`registres.adoc` pour la traçabilité, `types.adoc` pour la synthèse).
   Lis le `:type:` du maître : il fixe le lecteur et donc ce que tu juges.
   Dans un mémo (`memo`), le lecteur du corps est un décideur : signale
   comme risque tout détail technique du corps qui ne change pas la
   décision, tout terme non défini, toute option sans coût ni risque. Ses
   annexes sont lues par des experts : juge-les comme un DAT. Dans un DAT
   (`dat`), le lecteur construit : signale comme risque un choix structurant sans ADR,
   un flux ou une donnée cités sans être décrits. Dans une note de
   réflexion (`note`), le lecteur suit une recherche en cours : ne signale
   ni l'absence de décision ni celle d'ADR ; signale comme risque une idée
   non démontrée présentée comme acquise au lieu d'être une hypothèse du
   registre, et un concept recopié d'un fragment au lieu d'être inclus.
4. Lis le fichier de l'axe, et lui seul : `axes/tracabilite.md`,
   `axes/coherence.md`, `axes/sources.md`, `axes/rendu.md`,
   `axes/decision.md`, `axes/robustesse.md` ou `axes/concision.md` (chemins
   relatifs au dossier de ce skill).
5. Crée le rapport tout de suite, selon `rapport.md`, et remplis-le au fil
   de la revue : chaque constat et chaque ligne de journal y sont écrits dès
   qu'ils sont acquis. Le fichier, pas la conversation, garde la mémoire de
   la revue : elle survit à un contexte saturé ou résumé.
6. Pour les axes `traçabilité`, `cohérence`, `sources`, `décision` et
   `robustesse`, lis
   `.agents/skills/recherche-rag/SKILL.md` et applique-le à chaque recherche dans
   les bases. Lance `rag_list` : si le RAG est indisponible, dis-le d'emblée
   et poursuis la revue, en marquant « non vérifié » chaque vérification qui
   en dépendait.

## Règles

- Tu constates ; tu ne corriges pas sans accord. Ne change jamais le statut
  d'un ADR, ne clos jamais un point ouvert, ne modifie jamais une hypothèse :
  ce sont des décisions de l'architecte.
- Chaque constat a une localisation (fichier:ligne ou ID) et une preuve, sous
  forme de citation courte du texte. Sans preuve, pas de constat. Quand la
  preuve vient d'une base, cite aussi l'extrait et sa référence, selon
  `recherche-rag`.
- Une vérification non faite n'est jamais comptée comme conforme : elle
  figure au journal comme « non vérifié ».
- Cherche avec `rg` sur les IDs et les ancres avant de lire un fichier entier.
- Classe chaque constat. Une **erreur** est un énoncé faux, une contradiction
  (y compris avec une source : verdict « contredit ») ou une référence
  cassée. Un **risque** est un argument fragile ou une affirmation non étayée
  (verdicts « partiel » et « introuvable »). L'axe `concision` a sa propre
  gravité, `allègement`. Ne commente le style que si on te le demande.

## Axes

Un axe par passe. Le détail de chaque axe est dans son fichier, lu seulement
pour la revue qui le concerne.

| Axe | Objet |
|---|---|
| `traçabilité` | Chaque critère renvoie à la bonne hypothèse, au bon point ouvert, à une source ; pas de « à confirmer » hors registre. |
| `cohérence` | Pas de règle contredite par un cas particulier ; mêmes noms et chiffres partout ; synthèse fidèle au corps ; accord avec les entrants écrits. |
| `sources` | Chaque affirmation sur un produit, un entrant ou une norme est sourcée et vérifiée dans la bonne base. |
| `rendu` | Défauts visibles seulement dans le PDF produit. |
| `décision` | Chaque ADR a sa chaîne complète : options écartées, preuves, risque accepté, réversibilité, condition de révision. |
| `robustesse` | Faiblesses de l'architecture, attaquée par point de vue (exploitation, résilience, sécurité, coûts…), en questions et non en architecture de remplacement. |
| `concision` | Ce qui peut disparaître sans perte de décision, de preuve ou de compréhension. |

## Sortie

Le rapport va dans `work/revue-etude-<AAAAMMJJ>-<HHMMSS>.adoc`, au format de
`rapport.md`. Une fois la revue finie, confirme dans ta réponse le chemin
exact et la ligne de synthèse.
