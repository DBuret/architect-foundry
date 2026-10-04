---
name: justifier-idee
description: "Analyste de preuves : à partir d'une idée tirée d'un document de l'étude, ou d'affirmations déjà rédigées, retrouve dans les bases de connaissances (documents en français et en anglais) les passages qui la soutiennent ou la contredisent, avec des citations vérifiables, et rend un rapport par affirmation. Utilise ce skill quand on te demande de justifier, étayer, prouver ou contester une idée, une thèse ou une affirmation, ou de trouver des sources pour elle comme contre elle."
---

# Justifier une idée

Ce skill dit quoi chercher pour une idée et comment en rendre compte. La
manière de chercher, de lire un passage, de conclure et de citer est celle
de `recherche-rag` : lis `.agents/skills/recherche-rag/SKILL.md` avant de
commencer et applique-le, sans y déroger. Seuls les passages renvoyés par
le RAG font foi, jamais tes connaissances propres.

## Entrée

Soit un extrait de l'étude, avec son fichier et sa section ; soit une ou
plusieurs affirmations déjà rédigées (appel par un autre agent), à traiter
telles quelles, sans les redécouper.

## Procédure

1. **Décomposer** l'idée en 1 à 5 affirmations atomiques et vérifiables.
2. **Chercher**, pour chaque affirmation, ce qui la soutient et ce qui la
   contredirait (exception, limite, cas d'échec, avis contraire), dans les
   deux langues selon `recherche-rag`, « Formuler les requêtes ».
3. **Retenir** au plus 5 passages par affirmation, sans doublon, classés
   selon leur pertinence et non selon leur langue ni leur score. Pour
   chacun, noter s'il soutient directement, indirectement, ou contredit ;
   écarter les autres.
4. **Conclure** par un verdict de `recherche-rag` (confirmé, partiel,
   contredit, introuvable, non vérifié), et l'écrire au rapport dès qu'il
   est acquis : ses passages n'ont plus besoin de rester en mémoire.

Rapporte les contre-preuves, même si elles affaiblissent l'idée. Ne modifie
aucun fichier de l'étude : une affirmation introuvable, partielle ou
contredite se propose à l'architecte comme hypothèse ou point ouvert
(`recherche-rag`, « Citer »).

## Sortie

Le rapport va dans `work/justification-<AAAAMMJJ>-<HHMMSS>.md`, rempli au
fil de l'eau ; ta réponse en reprend le verdict global et les citations à
insérer, et donne le chemin du fichier. En français, concis, factuel.

```
## Idée analysée
Une phrase.

## Verdict global
Affirmations confirmées (ex. 3/4) ; confiance faible, moyenne ou élevée.

## 1. <affirmation>
**Verdict** : confirmé | partiel | contredit | introuvable | non vérifié
**Citation à insérer** : la preuve directe la plus forte, au format de
`recherche-rag`, « Citer » ; « aucune » si le verdict n'est pas « confirmé ».

**Preuves**
- « <citation> » [trad. : …] — *<titre>*, <section>, p. <page>
  (<base>, <source_name>, <id>) — directe | indirecte. <raison en une phrase>

**Contre-preuves**
- même forme.

**Requêtes** : <requêtes lancées, avec base et langue>

## Lacunes
Affirmations non confirmées, termes déjà essayés, documents à ajouter au RAG.
```
