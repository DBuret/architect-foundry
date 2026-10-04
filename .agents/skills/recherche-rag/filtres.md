# Filtres de recherche (`rag_search`)

À lire seulement avant de poser un filtre sur `rag_search`.

- Forme : `{"field": "status", "op": "eq", "value": "actif"}`. Opérateurs :
  `eq`, `ne`, `in` (valeur tableau), et `gt`, `gte`, `lt`, `lte` sur les
  entiers ; combinaison par `and` ou `or`, sur un niveau d'imbrication au
  plus.
- Seuls les champs déclarés filtrables sont acceptés : `doc_type`, `status`,
  `year`, `domaine`, `source_name`, et `langue` en multi-projets. Un autre
  champ est refusé avec la liste des champs admis : reprends-la, sans
  insister sur le champ refusé.
- La correspondance est exacte, sans recherche partielle. Valeurs
  conventionnelles : `doc_type` vaut `livre`, `reglement`, `referentiel` ou
  `note` ; `status` vaut `actif`, `obsolete` ou `brouillon` ; `langue` vaut
  `fr` ou `en` ; `year` est un entier. Pour `domaine`, ne filtre que sur
  une valeur déjà vue dans un résultat, recopiée à l'identique.
- Un filtre écarte sans message les documents qui n'ont pas le champ
  filtré : un résultat vide ou maigre après un filtre ne vaut pas
  « introuvable » ; relance sans filtre.
- Pour restreindre la recherche à un document précis, utile surtout en
  multi-projets où un ouvrage se perd parmi d'autres, filtre sur
  `source_name`, recopié caractère pour caractère depuis l'en-tête d'un
  résultat (sous pi-rag : dernier élément de la ligne « Source ») (`in` pour plusieurs
  documents). Ce nom sert au filtre, jamais à la citation. Deux versions
  d'un document se distinguent par `status` ou `year`.
