#!/bin/sh
# check-test.sh — non-régression de check.sh sur des mini-études jetables.
# Usage : tools/tests/check-test.sh
# Chaque cas écrit un maître (et ses fragments) dans un dossier temporaire,
# lance check.sh et vérifie le code retour et la présence (ou l'absence)
# d'un motif dans la sortie.

CHECK=$(cd "$(dirname "$0")/.." && pwd)/check.sh
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
fails=0; n=0

# cas <nom> <rc attendu> <motif attendu|-> <motif interdit|-> [maître]
# Le dossier du cas doit être préparé dans $d avant l'appel.
cas() {
  n=$((n + 1))
  out=$(cd "$d" && "$CHECK" "${5:-memo.adoc}" 2>&1); st=$?
  err=""
  [ "$st" -eq "$2" ] || err="rc=$st au lieu de $2"
  [ "$3" = - ] || printf '%s\n' "$out" | grep -q -- "$3" || err="$err ; motif absent : $3"
  [ "$4" = - ] || ! printf '%s\n' "$out" | grep -q -- "$4" || err="$err ; motif inattendu : $4"
  if [ -n "$err" ]; then
    fails=$((fails + 1)); echo "ÉCHEC  $1 : $err"; printf '%s\n' "$out" | sed 's/^/       | /'
  else
    echo "ok     $1"
  fi
}
nouveau() { d="$tmp/$n"; mkdir -p "$d"; }

registre='[[H1]]H1:: Hypothèse.'

nouveau; printf '= M\n:type: dat\n\n== Synthèse\n\nVoir <<H1>>.\n\n%s\n' "$registre" > "$d/memo.adoc"
cas "étude propre" 0 - "AVERT"

nouveau
cas "maître introuvable" 1 "maître introuvable" -

nouveau; printf '= M\n:type: dat\n\nTexte.\n' > "$d/memo.adoc"
ASCIIDOCTOR=asciidoctor-absent cas "asciidoctor absent" 1 "prérequis absent" -

nouveau; printf '= M\n:type: dat\n\nVoir <<H9>>.\n' > "$d/memo.adoc"
cas "xref sans ancre" 1 "possible invalid reference" -

nouveau; printf '= M\n:type: dat\n\ninclude::absent.adoc[]\n' > "$d/memo.adoc"
cas "include introuvable" 1 "KO     memo.adoc : build" -

nouveau; printf '= Registre\n\n%s\n' "$registre" > "$d/reg.adoc"
printf '= M\n:type: dat\n\nVoir <<H1>>.\n\ninclude::reg.adoc[]\n' > "$d/memo.adoc"
cas "fragment autonome sans leveloffset" 1 "level 0 sections" -

nouveau; printf '= Registre\n\n%s\n' "$registre" > "$d/reg.adoc"
printf '= M\n:type: dat\n\nVoir <<H1>>.\n\ninclude::reg.adoc[leveloffset=+1]\n' > "$d/memo.adoc"
cas "fragment autonome avec leveloffset" 0 - "KO"

nouveau; printf '= M\n:type: dat\n\nTexte.\n\n* Point, phrase une.\nPhrase deux.\n* Point deux.\n' > "$d/memo.adoc"
cas "liste à une phrase par ligne" 0 - "puce sans ligne vide"

nouveau; printf '= M\n:type: dat\n\n----\n@startmindmap\n* Racine\n** A\n@endmindmap\n----\n' > "$d/memo.adoc"
cas "puces dans un bloc délimité" 0 - "puce sans ligne vide"

nouveau; printf '= M\n:type: dat\n\n[plantuml,phases,svg]\n@startwbs\n* Phases\n** Cadrage\n@endwbs\n' > "$d/memo.adoc"
cas "bloc PlantUML sans lignes ----" 1 "unknown style for paragraph" -

nouveau; printf '= M\n:type: dat\n\nTexte collé.\n* Point.\n' > "$d/memo.adoc"
cas "puce collée au texte" 0 "puce sans ligne vide" -

nouveau; printf '= M\n:type: dat\n\n[[PO-01,PO-01]]\n== Point\n\nTexte.\n' > "$d/memo.adoc"
cas "ancre avec texte jamais citée" 0 "jamais cité" -

nouveau; printf '= M\n:type: dat\n\nVoir xref:H1[].\n\n%s\n' "$registre" > "$d/memo.adoc"
cas "citation xref:ID[]" 0 - "jamais cité"

nouveau; printf '= M\n:type: dat\n\nVoir <<H1>>, et H1 encore.\n\n%s\n' "$registre" > "$d/memo.adoc"
cas "mention nue" 0 "cité sans xref" -


nouveau; printf '= M\n:type: dat\n\nLancement 🚀 prévu.\nAttention ⚠️ ici.\n' > "$d/memo.adoc"
cas "emoji" 0 "memo.adoc:5:.*⚠️" -

nouveau; printf '= M\n:type: dat\n\n== Synthèse\n\nA → B, ✓ fait, ⇒ donc, © 2026.\n' > "$d/memo.adoc"
cas "symboles texte, pas des emojis" 0 - "AVERT"

nouveau; printf '= M\n:type: dat\n\nVoir <<H1>> et <<H2>>.\n\n[[H1]]\n== H1 : Un\n\n.Statut\nValidée.\n\n[[H2]]\n== H2 : Deux\n\n.Énoncé\nTexte.\n\n== Suite\n\n.Statut\nHors entrée.\n' > "$d/memo.adoc"
cas "entrée de registre sans .Statut" 0 "memo.adoc:12: H2" "memo.adoc:6: H1"

nouveau; printf '= M\n:type: dat\n\nVoir <<ADR-01>>.\n\n[[ADR-01]]\n== ADR-01 : Choix\n\n=== Statut\n\nProposé.\n' > "$d/memo.adoc"
cas "statut en sous-section" 0 "sans .Statut" -

nouveau; printf '= M\n:type: dat\n\nVoir <<PO-01>>.\n\n[[PO-01]]\n== PO-01 : Question\n\n.Question\nTexte.\n\n=== Détail\n\n.Statut\nOuvert.\n' > "$d/memo.adoc"
cas "statut dans une sous-section de l'entrée" 0 - "sans .Statut"

nouveau; printf '= M\n:type: dat\n\n== Synthèse\n\n.Incertain\nregistre::hypotheses[incertains]\n\nregistre::adr[]\n\nVoir <<H1>>.\n\n[[H1]]\n== H1 : Un\n\n.Statut\nNon validée par le métier.\n' > "$d/memo.adoc"
cas "macro registre et statut admis" 0 - "KO\|AVERT"

nouveau; printf '= M\n:type: dat\n\nregistre::hypothese[]\n' > "$d/memo.adoc"
cas "macro registre inconnu" 1 "registre inconnu" -

nouveau; printf '= M\n:type: dat\n\nVoir <<PO-01>>.\n\n[[PO-01]]\n== PO-01 : Q\n\n.Statut\nFermé.\n' > "$d/memo.adoc"
cas "statut hors liste" 1 "hors liste" -

nouveau; printf '= M\n:type: dat\n\nNOTE: Précision.\n\n[CAUTION]\n====\nRisque.\n====\n\n----\nNOTE: exemple dans un bloc\n----\n' > "$d/memo.adoc"
cas "admonitions NOTE et CAUTION" 0 "memo.adoc:4: NOTE" "memo.adoc:12"

nouveau; printf '= M\n:type: dat\n\n== Synthèse\n\nTIP: Piste.\n\n[IMPORTANT]\n====\nPoint.\n====\n\nWARNING: Risque.\n' > "$d/memo.adoc"
cas "admonitions admises" 0 - "AVERT"

nouveau; printf '= M\n\nTexte.\n' > "$d/memo.adoc"
cas "maître sans :type:" 1 "pas de :type:" -

nouveau; printf '= M\n:type: rapport\n\nTexte.\n' > "$d/memo.adoc"
cas "type de maître inconnu" 1 ":type: rapport inconnu" -

nouveau; printf '= N\n:type: note\n\n== Synthèse\n\nTexte.\n\n== Point de départ\n\n----\ncode\n----\n\n=== A\n\n==== B\n\nTexte.\n' > "$d/note.adoc"
cas "note de réflexion : type reconnu, règles du mémo non appliquées" 0 - "corps d'un mémo" note.adoc

nouveau; printf '= R\n:type: dat\n\nTexte.\n' > "$d/reg.adoc"
printf '= M\n:type: memo\n\n== Synthèse\n\nTexte.\n\ninclude::reg.adoc[leveloffset=+1]\n' > "$d/memo.adoc"
cas "fragment avec :type:" 0 "reg.adoc : :type: dans un fragment" -

nouveau; printf '= M\n:type: memo\n\n== Contexte\n\n----\ncode\n----\n\n=== A\n\n==== B\n\n===== C\n\nTexte.\n' > "$d/memo.adoc"
cas "mémo : synthèse, code, profondeur" 0 "pas la synthèse" -
cas "mémo : bloc de code" 0 "bloc de code ou littéral dans le corps d.un mémo" -
cas "mémo : section trop profonde" 0 "section au-delà de ====" -

nouveau; printf '= M\n:type: memo\n\n== Synthèse\n\nTexte.\n\n== Contexte\n\n=== A\n\n==== B\n\nTexte.\n' > "$d/memo.adoc"
cas "mémo : trois niveaux admis dans le corps" 0 - "AVERT"

nouveau; printf '= M\n:type: memo\n\n== Synthèse\n\nTexte.\n\n[appendix]\n== Détail technique\n\n----\ncode\n----\n\n=== A\n\n==== B\n\nTexte.\n' > "$d/memo.adoc"
cas "mémo : annexes techniques admises" 0 - "AVERT"

nouveau; printf '= D\n:type: dat\n\n== Synthèse\n\nTexte.\n\n== Détail\n\n----\ncode\n----\n\n=== A\n\n==== B\n\nTexte.\n' > "$d/memo.adoc"
cas "DAT : code et profondeur admis" 0 - "AVERT"

nouveau; printf '= M\n:type: memo\n\n== Synthèse\n\nTexte.\n' > "$d/memo.adoc"; printf '= D\n:type: dat\n\n== Synthèse\n\nTexte.\n' > "$d/dat.adoc"
n=$((n + 1)); d0=$d; mkdir -p "$d0/tools"; cp "$CHECK" "$(dirname "$CHECK")/conteneur.sh" "$d0/tools/"; cp -r "$(dirname "$CHECK")/extensions" "$d0/tools/"
out=$(sh "$d0/tools/check.sh" 2>&1); st=$?
if [ $st -eq 0 ] && ! printf '%s\n' "$out" | grep -q 'KO\|AVERT'; then echo "ok     sans argument : maîtres détectés"; else fails=$((fails + 1)); echo "ÉCHEC  sans argument : rc=$st"; printf '%s\n' "$out" | sed 's/^/       | /'; fi

nouveau; printf '= M\n:type: dat\n\n== Synthèse\n\nTexte.\n\ninclude::long.adoc[]\n' > "$d/memo.adoc"
awk 'BEGIN { print "== Long\n"; for (i = 0; i < 700; i++) print "Une phrase de remplissage assez longue pour grossir le fragment." }' > "$d/long.adoc"
cas "fragment trop long" 0 "long.adoc : 4[0-9] Ko" -
MAX_FRAGMENT_KO=60 cas "seuil de fragment surchargé" 0 - "fragment de plus"

nouveau; printf '= Annexe\n\n[[X1]]X1:: Rien.\n' > "$d/annexe.adoc"; printf '= Hyp\n\n%s\n' "$registre" > "$d/hyp.adoc"
printf '= M\n:type: dat\n\nVoir xref:hyp.adoc#H1[] et xref:annexe.adoc#X1[].\n\ninclude::hyp.adoc[leveloffset=+1]\n' > "$d/memo.adoc"
cas "renvoi vers un fichier non inclus" 1 "memo.adoc:4:.*xref:annexe.adoc#X1" "xref:hyp.adoc#H1.*non inclus"

nouveau; printf '= Hyp\n\n%s\n' "$registre" > "$d/hyp.adoc"
printf '= M\n:type: dat\n\nVoir xref:hyp.adoc#H1[] et https://example.org[site].\n\ninclude::hyp.adoc[leveloffset=+1]\n' > "$d/memo.adoc"
cas "renvois internes et URL" 0 - "non inclus"

nouveau; printf '= M\n:type: dat\n\nVoir §4.2.\n' > "$d/memo.adoc"
cas "renvoi numérique en dur" 1 "renvoi numérique" -

nouveau; mkdir "$d/images"; printf '<svg xmlns="http://www.w3.org/2000/svg"/>' > "$d/images/ok.svg"
printf '= M\n:type: dat\n:imagesdir: images\n\nimage::ok.svg[]\n\nimage::absent.svg[]\n' > "$d/memo.adoc"
cas "image introuvable" 1 "absent.svg" "ok.svg"

# URL et cible contenant un attribut (au début ou au milieu) : invérifiables,
# jamais signalées.
nouveau; mkdir "$d/images"
printf '= M\n:type: dat\n:imagesdir: images\n:nom: schema\n\nimage::https://exemple.org/logo.png[]\n\nimage::schemas/{nom}.svg[]\n\nimage::{imagesdir}/x.svg[]\n' > "$d/memo.adoc"
cas "image : URL et attributs ignorés" 0 - "image introuvable"

nouveau; printf '= M\n:type: dat\n\nTexte.\n' > "$d/memo.adoc"; printf '= Lisez-moi\n\nVoir H1 et §4.2.\n' > "$d/README.adoc"
cas "README.adoc hors périmètre" 0 - "README"

if ruby -e 'require "asciidoctor-diagram"' >/dev/null 2>&1; then
  nouveau; printf '= M\n:type: dat\n:imagesoutdir: {docdir}/work/images\n:diagram-cachedir: {docdir}/work/cache\n\n[plantuml,schema,svg]\n----\n@startmindmap\n* Racine\n** A\n@endmindmap\n----\n' > "$d/memo.adoc"
  cas "schéma PlantUML converti" 0 - "KO"
  cas "schéma sans style commun" 0 "sans style commun" -
  n=$((n + 1))
  if [ -e "$d/work" ] || [ -e "$d/schema.svg" ]; then
    fails=$((fails + 1)); echo "ÉCHEC  build de contrôle sans image dans le dépôt"
  else
    echo "ok     build de contrôle sans image dans le dépôt"
  fi
  nouveau; mkdir -p "$d/normes/plantuml"
  printf 'skinparam mindmap {\n  BackgroundColor #F1F1F1\n}\n' > "$d/normes/plantuml/_mindmap.iuml"
  printf '= M\n:type: dat\n:imagesoutdir: {docdir}/work/images\n:diagram-cachedir: {docdir}/work/cache\n\n[plantuml,schema,svg]\n----\n@startmindmap\n!include normes/plantuml/_mindmap.iuml\n* Racine\n** A\n@endmindmap\n----\n' > "$d/memo.adoc"
  cas "schéma avec style commun (fichier présent)" 0 - "sans style commun"

  nouveau; printf '= M\n:type: dat\n:imagesoutdir: {docdir}/work/images\n:diagram-cachedir: {docdir}/work/cache\n\n[plantuml,schema,svg]\n----\n@startmindmap\n!include normes/plantuml/_mindmap.iuml\n* Racine\n** A\n@endmindmap\n----\n' > "$d/memo.adoc"
  cas "schéma avec style commun (fichier absent)" 1 "cannot include" -

  # Régression : un arrow{} ou un sélecteur de classe (.urgent) posé hors
  # du bloc englobant (mindmapDiagram/wbsDiagram) n'a silencieusement
  # aucun effet sur cette version de PlantUML (voir normes/schemas.adoc).
  # check.sh ne peut pas le voir : on inspecte donc le SVG produit, avec les
  # vrais fichiers du dépôt. <<urgent>> (#C62828) et <<focus>> (#087859)
  # marquent leur nœud seul : l'enfant d'un nœud marqué ne l'est pas.
  nouveau; mkdir -p "$d/normes/plantuml"
  cp "$ROOT/normes/plantuml/_commun.iuml" "$ROOT/normes/plantuml/_mindmap.iuml" "$ROOT/normes/plantuml/_wbs.iuml" "$d/normes/plantuml/"

  # marques <type> <début> <fin> <image>
  marques() {
    printf '= M\n:type: dat\n:imagesoutdir: {docdir}/work/images\n:diagram-cachedir: {docdir}/work/cache\n\n[plantuml,%s,svg]\n----\n%s\n!include normes/plantuml/_%s.iuml\n* Racine\n** Point <<urgent>>\n*** Enfant\n** Sujet <<focus>>\n%s\n----\n' "$4" "$2" "$1" "$3" > "$d/memo.adoc"
    n=$((n + 1))
    svg=$d/work/images/$4.svg
    if (cd "$d" && asciidoctor -r asciidoctor-diagram -o /dev/null memo.adoc >/dev/null 2>&1) \
       && grep -q "stroke:#C62828;stroke-width:2.5" "$svg" \
       && grep -q "stroke:#087859;stroke-width:2.5" "$svg" \
       && ! grep -o "<rect[^>]*/><text[^>]*>Enfant<" "$svg" | grep -q "#C62828"; then
      echo "ok     <<urgent>> et <<focus>> sur un $1, nœud seul"
    else
      fails=$((fails + 1)); echo "ÉCHEC  <<urgent>> et <<focus>> sur un $1 : contour absent, ou étendu à l'enfant"
    fi
  }
  marques mindmap @startmindmap @endmindmap mm
  marques wbs @startwbs @endwbs wb
else
  echo "ignoré schéma PlantUML : asciidoctor-diagram absent"
fi

# Repli sur le conteneur (BUILD=docker) : le cas doit être sous la racine
# du dépôt, seule montée. Ignoré sans moteur de conteneurs ni image locale.
. "$ROOT/tools/conteneur.sh"
if "$DOCKER" image inspect "$IMAGE" >/dev/null 2>&1; then
  d="$ROOT/work/check-test-$$"; mkdir -p "$d"
  printf '= M\n:type: dat\n\n== Synthèse\n\nTexte.\n' > "$d/memo.adoc"
  BUILD=docker cas "conteneur : étude propre" 0 "dans le conteneur" "KO"
  printf '= M\n:type: dat\n\n== Synthèse\n\nVoir <<H9>>.\n' > "$d/memo.adoc"
  BUILD=docker cas "conteneur : xref sans ancre" 1 "possible invalid reference" -
  rm -rf "$d"
  d="$tmp/hors-depot"; mkdir -p "$d"; printf '= M\n:type: dat\n\nTexte.\n' > "$d/memo.adoc"
  BUILD=docker cas "conteneur : maître hors du dépôt" 1 "hors du dépôt" -
else
  echo "ignoré conteneur : $DOCKER ou image $IMAGE absents"
fi

echo "$((n - fails))/$n cas OK"
[ "$fails" -eq 0 ]
