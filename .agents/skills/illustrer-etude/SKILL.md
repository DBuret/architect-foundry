---
name: illustrer-etude
description: Relit un chapitre déjà rédigé d'une étude d'architecture AsciiDoc et ajoute les mindmaps ou WBS PlantUML qui en faciliteraient la compréhension, sans toucher au texte normatif. Utilise ce skill après avoir fini de rédiger ou de réviser un chapitre — jamais pendant la rédaction — ou dès qu'on te demande d'illustrer, d'ajouter des schémas, des diagrammes, des mindmaps ou des WBS à un chapitre, une section ou un document existant.
---

# Illustration d'une étude déjà rédigée

Ce skill est une passe séparée de la rédaction, pas une règle à appliquer
phrase par phrase en écrivant. Juger si un passage mérite un schéma
demande de voir le chapitre entier — sa longueur, ses répétitions, sa
hiérarchie réelle — ce qu'on ne voit pas correctement en écrivant une
liste au fil de l'eau. D'où l'ordre : rédiger, puis illustrer.

## Avant de commencer

1. Identifie le périmètre : un chapitre, un fichier, ou par défaut les
   chapitres touchés par `git diff` depuis le dernier commit.
2. Lis `normes/schemas.adoc` : syntaxe PlantUML, partage des rôles entre
   mindmap et WBS (« Mindmaps et WBS »), fichier `!include` à poser dans
   chaque nouveau bloc (« Style commun aux schémas »), couleurs nommées et
   mise en évidence (« Couleurs des schémas »).
3. Lis le `:type:` du maître. Dans le corps d'un mémo (`memo`), un schéma
   par chapitre au plus, mindmap ou WBS seulement : le décideur doit saisir
   les options et la trajectoire, pas l'architecture détaillée. Ses annexes
   techniques suivent les règles d'un DAT. Dans un DAT
   (`dat`) ou une note de réflexion (`note`), les règles ci-dessous
   s'appliquent telles quelles.
4. Lis le chapitre en entier avant de juger quoi que ce soit. Un passage
   qui semble long isolément peut être bref une fois le chapitre vu en
   entier, et inversement.

## Règles

- Additif seulement : tu ajoutes des schémas, tu ne réécris ni ne
  supprimes le texte normatif (prose, listes, tables) qu'ils illustrent.
  Si un schéma rend une liste franchement redondante, signale-le comme
  option à la fin de ton compte-rendu — ne la supprime pas toi-même.
- N'illustre que ce qui franchit le seuil des conventions : plus de cinq
  éléments énumérés, une hiérarchie sur deux niveaux ou plus, ou une
  décomposition en phases/lots/tâches. En dessous, ne rien ajouter — un
  document où chaque paragraphe a son diagramme est plus dur à lire, pas
  plus facile.
- Un schéma par passage qualifié, pas plus. Si un chapitre entier
  qualifie plusieurs passages, chacun reçoit son propre bloc, à l'endroit
  où il se trouve dans le texte — pas un schéma unique fourre-tout en fin
  de chapitre qui oblige à retrouver soi-même quel nœud correspond à
  quel paragraphe.
- Mindmap pour un inventaire ou une catégorisation sans ordre
  d'exécution (risques, critères, périmètre inclus/exclu). WBS pour une
  décomposition avec un sens d'exécution (phasage, livrable, lots).
- Couleurs : celles du style suffisent le plus souvent. Pour en poser
  une, une couleur nommée de la palette en stéréotype
  (`** Lot 2 <<peche>>`), jamais un code (`[#FF0000]`, `#lightblue`) :
  `check.sh` signale tout code hors palette. Une couleur, un sens : la même couleur
  pour la même notion dans tout le document. Pour mettre un nœud en
  évidence, `<<focus>>` ou `<<urgent>>`, un de chaque au plus par schéma,
  et seulement si le texte dit pourquoi.
- Toute donnée portée par un schéma (un chiffre, un statut, un nom) doit
  déjà être dans le texte qu'il illustre. N'invente rien pour remplir un
  nœud ; un schéma qui ajoute une information absente du texte introduit
  une source de vérité parallèle, exactement ce que la discipline
  ancre/xref des conventions cherche à éviter pour le texte.

## Méthode

1. Pour chaque passage qualifié, rédige le bloc complet, sur ce modèle
   exact, avec un `nom` distinctif (pas `diagram1`, `diagram2`) :

   ```
   [plantuml,nom,svg]
   ----
   @startwbs
   !include normes/plantuml/_wbs.iuml
   * Racine
   ** Élément
   @endwbs
   ----
   ```

   Les deux lignes `----` (quatre tirets) encadrent le code : sans elles,
   le schéma n'est pas dessiné et son texte brut s'affiche dans le PDF.
   Pour un mindmap : `@startmindmap`, `_mindmap.iuml`, `@endmindmap`.
   N'écris jamais de `skinparam` toi-même.
2. Insère-le juste après le passage qu'il illustre, avec une ligne vide
   avant et après.
3. Une fois le chapitre traité, lance `tools/check.sh <maître>`. Il détecte
   un bloc mal fermé ou non converti, pas un mauvais choix de contenu :
   relis toi-même les nœuds du schéma contre le texte source avant de
   conclure.

## Sortie

Termine par un tableau récapitulatif :

| Chapitre | Passage illustré | Type | Justification |
|---|---|---|---|

Puis une ligne : `N schémas ajoutés (n mindmap, m wbs) — périmètre <périmètre>`.
Si aucun passage ne franchit le seuil, dis-le explicitement plutôt que de
forcer un schéma : `0 schéma ajouté — aucun passage au-delà du seuil`.
