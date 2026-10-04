---
name: integrer-entrant
description: "Intègre un entrant de projet (compte rendu de réunion, notes d'atelier, courriel, indication orale, note reçue) dans une étude d'architecture AsciiDoc : trie ce qu'il apporte en sources, hypothèses, points ouverts et décisions à proposer, crée les entrées de registre au format, et propose à l'architecte ce qui touche des entrées existantes, sans changer leur statut. Utilise ce skill dès qu'on te donne des notes, un compte rendu, un courriel ou une information orale à intégrer, consigner, reporter ou prendre en compte dans l'étude, même si le mot « entrant » n'est pas employé."
---

# Intégrer un entrant

Un entrant apporte en vrac des faits, des suppositions, des questions et
des choix. Ce skill les range dans les registres, pour que chacun soit cité
par son ID au lieu d'être réécrit de mémoire dans un chapitre. Il ne
rédige pas les chapitres : il prépare ce qu'ils citeront.

## Avant de commencer

1. Lis `normes/registres.adoc` (format, statuts) et, dans
   `normes/asciidoc.adoc`, la section « Sources et hypothèses ».
2. Identifie l'entrant : nature (réunion, courriel, note, oral), auteur ou
   participants, date, cadre. S'il en manque un, demande-le en une seule
   question : sans eux, l'origine d'une hypothèse ne dit rien au lecteur.
3. Relève les IDs existants et leurs intitulés :
   `rg -n '^== (H[0-9]+|PO-[0-9]+|ADR-[0-9]+) :' hypotheses.adoc points-ouverts.adoc adr.adoc`.
   Le prochain ID est le plus grand du registre plus un, sur le même
   format (`H7`, `PO-08`, `ADR-04`) ; ne comble jamais un trou de
   numérotation : un ID disparu a pu être cité dans un PDF déjà diffusé.
4. Crée tout de suite le rapport
   `work/entrant-<AAAAMMJJ>-<HHMMSS>.adoc` (date réelle, `date +%Y%m%d-%H%M%S`)
   et remplis-le au fil du tri.

## Trier

Découpe l'entrant en éléments, une affirmation ou une question chacun, et
range chacun dans une seule catégorie :

| L'élément est… | Il devient |
|---|---|
| Un fait tiré d'un document écrit que le lecteur peut retrouver | Une source, citée par titre, version ou date, et section, là où le texte s'en sert. Pas d'entrée de registre. Si le document est dans la base projet, vérifie la citation avec le skill `recherche-rag`. |
| Une indication orale, une valeur supposée, une déduction non confirmée | Une hypothèse, statut « Non validée. », dont l'origine dit qui, quand, dans quel cadre. |
| Une question qu'un tiers doit trancher ou confirmer | Un point ouvert, statut « Ouvert. », avec son porteur et son échéance s'ils sont dits, sinon « À désigner. » et « À fixer. ». |
| Un choix d'architecture annoncé ou souhaité | Une ADR, statut « Proposé. », même si l'entrant dit la décision prise : l'architecte change le statut, pas toi. |
| Un élément qui confirme, contredit, précise ou répond à une entrée existante | Une proposition au rapport, jamais une modification de l'entrée. |
| Un élément hors du sujet de l'étude | Rien ; une ligne au rapport. |

Avant de créer une entrée, cherche si une entrée existante la couvre déjà
(`rg -n -i` sur deux ou trois mots clés dans les registres) : si oui,
c'est une proposition sur l'entrée existante, pas un doublon.

## Écrire

- Ajoute chaque nouvelle entrée à la fin de son registre, au format de
  `normes/registres.adoc` : ancre seule sur sa ligne, `== ID : intitulé`
  de cinq mots environ, rubriques en titres de bloc dans l'ordre du
  registre, une phrase par ligne.
- L'énoncé reprend ce que dit l'entrant, sans l'interpréter ni le
  renforcer : « le responsable métier estime… », pas « le volume est… ».
- Ne modifie aucune entrée existante, aucun statut, aucun seuil : tout
  cela va au rapport, en proposition.
- Ne rédige pas les chapitres. Une entrée nouvelle reste donc souvent
  orpheline : `check.sh` le signale en AVERT, attendu ici. Indique au
  rapport le chapitre ou la section où elle devrait être citée.
- Si l'architecte demande aussi d'insérer les renvois, ajoute seulement le
  `<<ID>>` dans la phrase existante qui s'appuie sur l'entrée, sans
  réécrire la phrase.
- Lance `tools/check.sh`. Pas de KO ; chaque AVERT autre qu'un orphelin
  attendu se corrige ou se signale.

## Rapport

```asciidoc
= Entrant — <nature> — <auteur ou instance>, <date de l'entrant>

== Informations

* Date de l'intégration : <AAAA-MM-JJ HH:MM:SS>
* Entrant : <nature, auteur ou participants, date, cadre>

== Entrées créées

[cols="1,3,3"]
|===
| ID | Intitulé | Où la citer

| H7
| ...
| Chapitre « Contexte et enjeux », volume à traiter
|===

== Propositions sur des entrées existantes

[cols="1,3,3"]
|===
| ID | Ce que dit l'entrant | Proposition

| H2
| « ... »
| Passer à « Validée par ... le ... ».
|===

== Sources écrites citées

Une ligne par document, avec ce qu'il établit.

== Éléments écartés

Une ligne par élément, avec la raison.
```

## Sortie

Réponds par le décompte (`n hypothèses, m points ouverts, k ADR créés,
p propositions`), les propositions sur les entrées existantes, à trancher
par l'architecte, le résultat de `check.sh`, et le chemin du rapport.
