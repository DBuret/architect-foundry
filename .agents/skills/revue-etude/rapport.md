# Rapport de revue

À lire au moment de créer le rapport.

Écris le rapport dans un fichier AsciiDoc, jamais seulement dans le chat :
`work/revue-etude-<AAAAMMJJ>-<HHMMSS>.adoc`, à la racine du dépôt (crée
`work/` s'il n'existe pas). Obtiens la date et l'heure réelles au moment de
la revue (`date +%Y%m%d-%H%M%S` ou équivalent) — ne les invente jamais.

Structure du fichier :

```asciidoc
= Revue — <axe> — <périmètre>

== Informations

* Date : <AAAA-MM-JJ HH:MM:SS>
* Axe : <axe>
* Périmètre : <périmètre>
* Bases consultées : <noms des bases, « aucune » ou « RAG indisponible : <message> »>

== Constats

.Constats
[cols="1,2,3,3,3"]
|===
| Gravité | Localisation | Constat | Preuve | Correction proposée

| erreur
| synthese.adoc:212
| ...
| ...
| ...
|===

== Journal des vérifications

.Vérifications
[cols="2,1,3,1,3"]
|===
| Affirmation | Base | Requêtes | Verdict | Référence

| memo.adoc:42
| projet
| ...
| confirmé
| ...
|===

== Synthèse

N erreurs, M risques — axe <axe>, périmètre <périmètre> — V vérifications : c confirmées, x contredites, p partielles, i introuvables, n non vérifiées.
```

La gravité est `erreur` ou `risque`, ou `allègement` pour l'axe
`concision` ; la synthèse compte alors les allègements et les lignes qu'ils
libèrent au lieu des erreurs et des risques.

Un seul tableau de constats, une ligne par constat, dans l'ordre où ils
apparaissent dans le périmètre relu. Aucun constat : le tableau garde sa
seule ligne d'en-tête.

Le journal a une ligne par affirmation vérifiée, pas par requête : la
colonne Requêtes les énumère, séparées par « ; ». La colonne Référence
porte la citation au format de `recherche-rag`, ou « — » pour un
« introuvable » ou un « non vérifié ». Sans aucune recherche dans les bases
(axe `rendu`, par exemple), la section contient la seule phrase « Aucune
vérification dans les bases. » et la synthèse indique `0 vérification`.

Échapper tout `|` littéral à l'intérieur d'une cellule avec `\|` — sans quoi
la table se rompt à cet endroit.

Ce rapport suit les mêmes règles de syntaxe que `normes/asciidoc.adoc`
(tables, délimiteurs, pas de Markdown), mais pas sa structure imposée ni
son en-tête d'attributs `:indexable:`/`:type:` : ce n'est pas un document
d'architecture, il n'a pas d'ancres à poser et n'est pas destiné à être
indexé.

Une fois le fichier écrit, confirme dans ta réponse le chemin exact et la
ligne de synthèse, sans obliger à ouvrir le fichier pour connaître le
résultat.

## Exemple (axe cohérence)

`work/revue-etude-20260924-150311.adoc` :

```asciidoc
= Revue — cohérence — synthese.adoc

== Informations

* Date : 2026-09-24 15:03:11
* Axe : cohérence
* Périmètre : synthese.adoc
* Bases consultées : projet

== Constats

.Constats
[cols="1,2,3,3,3"]
|===
| Gravité | Localisation | Constat | Preuve | Correction proposée

| erreur
| synthese.adoc:212
| La justification de l'absence de filtrage de ports ne vaut pas pour un peer externe
| « chaque instance ne fait tourner qu'un seul service » ; scénario 2 : serveur Oracle legacy déclaré peer externe
| Signaler que tous les ports du peer sont exposés au groupe ; ouvrir un point ouvert sur le filtrage côté hôte

| erreur
| synthese.adoc:48
| Le calendrier de l'étude place la bascule après l'échéance fixée par la direction, sans le signaler
| « bascule complète au T2 2027 » ; présentation de lancement : « fin de la migration au 31/12/2026 »
| Aligner le calendrier sur l'échéance, ou exposer l'écart et sa justification dans la synthèse
|===

== Journal des vérifications

.Vérifications
[cols="2,1,3,1,3"]
|===
| Affirmation | Base | Requêtes | Verdict | Référence

| synthese.adoc:31
| projet
| « périmètre applicatif retenu par le cadrage » ; « applications exclues du périmètre »
| confirmé
| « seules les applications stateless sont éligibles » — Note de cadrage v2, Périmètre, p. 3 (projet, note-cadrage.pdf, 9c41e07ab2f3-p3-c4)

| synthese.adoc:48
| projet
| « échéance de la migration » ; « calendrier de bascule validé par la direction »
| contredit
| « fin de la migration au 31/12/2026 » — Présentation de lancement, Calendrier, p. 7 (projet, presentation-lancement.pptx)
|===

== Synthèse

2 erreurs, 0 risque — axe cohérence, périmètre synthese.adoc — 2 vérifications : 1 confirmée, 1 contredite, 0 partielle, 0 introuvable, 0 non vérifiée.
```
