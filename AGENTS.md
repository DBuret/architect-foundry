# Études d'architecture — guide agent

## Objet
Documents d'un architecte sur un sujet : mémo de décision pour la direction,
dossier d'architecture technique pour les équipes, note de réflexion sur un
sujet long. Rédaction en français, AsciiDoc, rendu PDF. Ton factuel.
Aussi peu que possible, autant que nécessaire : n'ajoute ni texte, ni
schéma, ni entrée de registre, ni fichier qui ne serve une décision, une
preuve ou la compréhension du lecteur.

## Carte
- Documents maîtres, à la racine, chacun typé par `:type:` dans son header :
  `memo.adoc` (`memo`, mémo de décision pour la direction), `dat.adoc`
  (`dat`, dossier d'architecture technique pour les équipes) et `note.adoc`
  (`note`, note de réflexion sur un sujet long). Une étude en garde un ou
  plusieurs. Leurs `include::` fixent l'ordre de lecture : commence
  toujours par eux.
- Fragments : à la racine, un fichier par chapitre, annexe ou registre.
- Registres, source unique : `hypotheses.adoc`, `points-ouverts.adoc`,
  `adr.adoc`.
- `normes/` : les règles de rédaction, chacune écrite une seule fois.
  `normes/asciidoc.adoc` se lit avant toute rédaction ; les autres, selon
  la tâche (voir « Économie de contexte »).
- `.agents/skills/` : skills `integrer-entrant`, `recherche-rag`,
  `illustrer-etude`, `revue-etude` et `justifier-idee`, lus par pi comme
  par VS Code.
- `work/` (ignoré par git) : PDF, schémas générés, rapports de revue,
  propositions à l'architecte.
- `images/` : images ajoutées par l'architecte, versionnées.
- `README.adoc` et `doc/` : documentation pour les humains ; ne les lis pas.
- `tools/`, `normes/`, `doc/`, `.agents/`, `.github/` et ce fichier viennent du modèle ; `images/`
  appartient à l'architecte : ne les modifie pas sans demande explicite.

## Ce que tu ne fais pas
Tu proposes, l'architecte décide. Ne change pas le statut d'une ADR, ne clos
pas un point ouvert, ne modifie ni une hypothèse ni un seuil de décision sans
demande explicite. Ne contourne jamais le hook (`--no-verify`).

## Workflow de rédaction
Lis le `:type:` du maître visé et applique sa structure (`normes/types.adoc`).
Rédige le texte d'un chapitre en entier avant de songer aux schémas — ne
t'interromps pas en écrivant pour juger si un passage mérite un diagramme,
ce jugement est plus fiable une fois le chapitre entier sous les yeux.
Ordre : rédaction → skill `illustrer-etude` sur le chapitre touché →
`tools/check.sh` → skill `revue-etude` si une relecture est demandée.
La synthèse se rédige en dernier. Toute source se cherche et se vérifie
avec le skill `recherche-rag`, jamais de mémoire. Un entrant (compte rendu,
courriel, indication orale) passe par le skill `integrer-entrant` avant
d'être cité dans un chapitre.

## Contrôles
- Après toute modification : `tools/check.sh` (sans argument : tous les
  maîtres). Ne rends pas la main avec un KO ; signale chaque AVERT.
- Un prérequis absent donne un KO : ne le contourne pas, signale-le.
- Après une modification de `tools/check.sh` : `tools/tests/check-test.sh`.
- Après une modification du thème, de `build.sh` ou de `normes/plantuml/` :
  `tools/tests/rendu.sh`, puis relis `work/rendu.pdf`.
- PDF : `tools/build.sh`, qui relance `check.sh` et écrit dans `work/`.
  `check.sh` ne voit pas les défauts propres au PDF : lis chaque WARNING et
  ERROR d'asciidoctor-pdf, corrige-le ou signale-le, comme un AVERT ;
  signale aussi l'AVERT des textes provisoires (« À rédiger. »).
- État d'ensemble : `tools/status.sh`, ou `--rapide` sans `check.sh` ;
  `--comite` liste les entrées de registre en attente de réponse.

## Économie de contexte
Le dépôt est conçu pour une fenêtre de 128K tokens. Le travail tient dans
les fichiers, pas dans la conversation :
- Normes : `normes/asciidoc.adoc` toujours ; `registres.adoc` pour un
  registre ou une macro `registre::` ; `types.adoc` pour un maître ou une
  synthèse ; `schemas.adoc` pour un schéma ou une image ; `fichiers.adoc`
  pour un include ou un header.
- Une tâche par session : un chapitre, ou un axe de revue sur un périmètre.
  Entre deux tâches, repars d'une session neuve ; l'état est dans git et
  dans `work/`.
- Lis par morceaux : `rg -n` sur l'ID ou l'ancre, puis la plage de lignes
  utile. Un fichier entier seulement si la tâche l'exige (le chapitre que
  tu illustres ou relis). Les `.adoc` du dépôt se cherchent avec `rg`,
  jamais avec le RAG.
- Écris au fil de l'eau ce qui doit survivre : rapport de revue, verdicts
  de recherche, propositions à l'architecte.
- PDF : lis le texte (LiteParse, `pdftotext`) ; une page en image seulement
  pour un défaut visuel, à basse résolution, page par page.
