# Axe concision

À lire après `SKILL.md`, pour une revue sur cet axe seulement.

Une seule question, pour chaque passage du périmètre : peut-il disparaître,
ou se réduire, sans perte de décision, de preuve ou de compréhension pour
le lecteur du type (`memo`, `dat`, `note`) ? Tu proposes, tu ne supprimes
rien.

Ce que tu cherches :

- **Répétitions** : un même contenu en deux endroits. Proposer d'en garder
  un et de renvoyer à l'autre par xref, ou par `include::` pour un concept.
- **Reformulations** : un paragraphe qui redit la synthèse, l'introduction
  d'un chapitre ou un ADR sans rien ajouter.
- **Analyses sans effet** : une comparaison, un historique ou un état de
  l'art qui ne change ni un critère, ni une option, ni une décision.
- **Détail mal placé** : dans le corps d'un mémo, un détail technique qui
  ne change pas la décision (proposer l'annexe) ; dans un DAT, un paragraphe
  de contexte que le cadrage porte déjà (proposer une référence).
- **Tableaux recopiés** : un tableau qui reprend un registre, à remplacer
  par la macro `registre::` (`normes/registres.adoc`).
- **Décoratif** : formules d'annonce (« Dans ce chapitre, nous allons… »),
  transitions, généralités vraies de toute étude.

Ce que tu ne proposes jamais :

- Supprimer ou fusionner une entrée de registre : un ID a pu être cité dans
  un PDF déjà diffusé.
- Supprimer une affirmation sourcée qui soutient un critère ou la
  recommandation, ni sa source.
- Couper sous la structure imposée par `normes/types.adoc` : une section
  obligatoire reste, même courte.

Règles propres à cet axe :

- Gravité : `allègement`, à la place d'erreur ou de risque.
- La correction proposée dit l'action (supprimer, réduire à une phrase,
  déplacer en annexe, remplacer par une xref) et le volume libéré en lignes.
- La synthèse du rapport compte les allègements et le total de lignes
  qu'ils libèrent : « 7 allègements, environ 120 lignes ».
- Commence par les plus gros gains : une revue de concision qui pinaille
  sur des mots coûte plus qu'elle ne rapporte.
