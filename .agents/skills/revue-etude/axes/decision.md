# Axe décision

À lire après `SKILL.md`, pour une revue sur cet axe seulement.

Une décision se juge à sa chaîne : contexte, options, preuves, décision,
conséquences. Le format ADR (`normes/registres.adoc`) n'a pas de rubrique
propre aux options écartées ni à la réversibilité : cherche-les dans le
Contexte et les Conséquences, où la norme les place.

Pour chaque ADR du périmètre, ou cité par lui :

- **Options.** Le Contexte nomme au moins une alternative sérieuse et dit
  pourquoi elle est écartée. Une décision sans alternative est un risque.
  Une option que les entrants écrits mentionnent (base projet) et que l'ADR
  ignore est un constat, preuve à l'appui. Ne propose jamais toi-même une
  nouvelle option, ni une autre décision : tu juges la chaîne, pas le choix.
- **Preuves.** Chaque raison de la décision renvoie à une source, ou par
  xref à l'hypothèse qui la couvre. Une décision `Accepté` qui repose sur une
  hypothèse `Invalidée` est une erreur ; sur une hypothèse `Non validée` ou
  un point ouvert `Ouvert`, un risque, sauf si l'ADR le dit et l'assume.
- **Risque accepté.** Les Conséquences disent ce que la décision coûte ou
  expose, pas seulement ce qu'elle apporte. Des Conséquences toutes
  positives sont un risque.
- **Réversibilité.** Les Conséquences disent ce que coûterait un retour
  arrière, ou qu'il est impossible. Une décision structurante (fournisseur,
  format de données, topologie) sans cette mention est un risque.
- **Condition de révision.** L'ADR dit ce qui ferait revenir sur la
  décision : un seuil, un événement, une hypothèse invalidée. Son absence
  est un risque pour une décision structurante, pas pour une décision
  mineure.
- **Statut.** Un ADR `Proposé` présenté comme acquis dans la synthèse ou
  le corps est une erreur. Ne change jamais un statut : signale-le.

Dans un mémo (`memo`), juge aussi la décision demandée au décideur : chaque
option présentée porte un coût et un risque, et la recommandation renvoie à
l'ADR qui la fonde. Dans une note (`note`), ne signale pas l'absence d'ADR.

La correction proposée dit ce qui manque à la chaîne (« dire au Contexte
pourquoi l'option X, citée par la note de cadrage, est écartée »), jamais
quoi décider.
