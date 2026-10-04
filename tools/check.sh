#!/bin/sh
# check.sh — contrôles mécaniques d'une étude AsciiDoc
# Usage     : tools/check.sh [maitre.adoc ...]
#             Sans argument : tous les maîtres de la racine du dépôt, soit les
#             .adoc dont le header déclare :type: memo, dat ou note.
# Prérequis : asciidoctor, ruby, grep, awk ; asciidoctor-diagram et
#             asciidoctor-diagram-plantuml (Java) si l'étude a des schémas.
#             À défaut, docker (ou podman) : check.sh se relance alors dans
#             l'image de build.sh (tools/conteneur.sh) ; BUILD=docker l'y
#             force.
# Périmètre : les .adoc du dossier des maîtres (la racine de l'étude), sauf
#             README.adoc ;
#             normes/, images/, tools/, work/ sont exclus d'office puisqu'ils
#             sont dans des sous-répertoires.
# Sortie    : code retour 1 si au moins un KO ; les AVERT ne bloquent pas.
#             Un prérequis ou un maître absent est un KO, jamais un succès.

# Type d'un maître : valeur de :type: dans son header (du titre à la
# première ligne vide).
type_de() { awk 'NR > 1 && /^[ \t]*$/ { exit } /^:type:/ { sub(/^:type:[ \t]*/, ""); sub(/[ \t]*$/, ""); print; exit }' "$1"; }

if [ $# -eq 0 ]; then
  depot=$(cd "$(dirname "$0")/.." && pwd)
  set -- $(grep -l -E '^:type:[[:space:]]*(memo|dat|note)[[:space:]]*$' "$depot"/*.adoc 2>/dev/null)
  [ $# -gt 0 ] || { echo "KO     aucun maître (:type: memo, dat ou note) à la racine de $depot"; exit 1; }
fi

# Surchargeable pour les tests ou une installation hors du PATH.
asciidoctor_impose=${ASCIIDOCTOR:+1}
ASCIIDOCTOR=${ASCIIDOCTOR:-asciidoctor}

# Repli sur le conteneur : sans les outils sur le poste, ou avec
# BUILD=docker, check.sh se relance dans l'image de build.sh, si docker est
# là. Seule la racine du dépôt y est montée : les maîtres doivent s'y
# trouver. Jamais quand ASCIIDOCTOR est imposé (tests, installation hors du
# PATH), ni déjà dans le conteneur.
depot=$(cd "$(dirname "$0")/.." && pwd)
. "$depot/tools/conteneur.sh"
outils_poste() {
  for c in "$ASCIIDOCTOR" ruby grep awk; do command -v "$c" >/dev/null 2>&1 || return 1; done
}
if [ -z "${DANS_CONTENEUR:-}" ] && [ -z "$asciidoctor_impose" ] &&
   { [ "${BUILD:-}" = docker ] || ! outils_poste; } &&
   command -v "$DOCKER" >/dev/null 2>&1; then
  rel=
  for m in "$@"; do
    [ -f "$m" ] || { echo "KO     $m : maître introuvable"; exit 1; }
    a=$(cd "$(dirname "$m")" && pwd)/$(basename "$m")
    case $a in
      "$depot"/*) rel="$rel ${a#"$depot"/}" ;;
      *) echo "KO     $m : hors du dépôt $depot, seul monté dans le conteneur"; exit 1 ;;
    esac
  done
  echo "check : contrôles dans le conteneur $IMAGE" >&2
  conteneur "$depot" sh tools/check.sh $rel
  st=$?
  [ $st -le 1 ] && exit $st
  echo "KO     conteneur $IMAGE non lancé ($DOCKER, code $st) : moteur arrêté ou image introuvable"
  exit 1
fi

# Reprendre ici les options passées par ton tooling PDF si les maîtres en
# dépendent. asciidoctor-diagram est chargé automatiquement s'il est installé.
# registres.rb (macro registre::, vocabulaire des statuts) est chargé comme
# au build : un registre inconnu ou un statut hors liste y lève un WARNING.
# Chemin absolu, calculé avant le cd vers le dossier des maîtres.
EXT=$(cd "$(dirname "$0")/extensions" && pwd) || exit 1
ADOC_OPTS="-r $EXT/registres.rb"

# IDs des registres (hypothèses, points ouverts, ADR), en regex étendue.
# Sert aux contrôles 5 (orphelins) et 6 (mentions nues). Ne pas y mettre les
# identifiants internes d'une annexe (critères d'une grille, par exemple) :
# ils n'ont pas vocation à être cités ailleurs.
REG_IDS='H[0-9]+|PO-[0-9]+|ADR-[0-9]+'

rc=0
ko()    { echo "KO     $1"; rc=1; }
avert() { echo "AVERT  $1"; }

# 0. Prérequis et maîtres. Un outil absent ferait passer les contrôles au
#    vert sans rien vérifier : on s'arrête.
for c in "$ASCIIDOCTOR" ruby grep awk; do
  command -v "$c" >/dev/null 2>&1 || ko "prérequis absent : $c"
done
[ $rc -eq 0 ] || [ -n "$asciidoctor_impose" ] ||
  echo "       ni ces outils ni $DOCKER sur le poste : voir doc/howto.adoc, « Installer le poste »"
[ $rc -eq 0 ] || exit 1

root=$(dirname "$1")
for m in "$@"; do
  [ "$(dirname "$m")" = "$root" ] || ko "$m : tous les maîtres doivent être dans le même dossier"
  [ -f "$m" ] || ko "$m : maître introuvable"
done
[ $rc -eq 0 ] || exit 1
for m in "$@"; do
  case $(type_de "$m") in
    memo|dat|note) ;;
    '') ko "$m : pas de :type: dans le header (memo, dat ou note)" ;;
    *) ko "$m : :type: $(type_de "$m") inconnu (memo, dat ou note)" ;;
  esac
done
cd "$root" || exit 1

# Fichiers de l'étude : les .adoc du dossier des maîtres, sauf README.adoc,
# qui documente le dépôt et non l'étude. Noms de fichiers sans espace.
ADOCS=$(ls ./*.adoc | grep -vx './README.adoc')

if ruby -e 'require "asciidoctor-diagram"' >/dev/null 2>&1; then
  ADOC_OPTS="-r asciidoctor-diagram $ADOC_OPTS"
fi

# Les HTML, images et caches générés par le build vont dans un dossier jeté.
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

# 1. Build verbeux de chaque maître.
#    Détecte :
#      - tout WARNING ou ERROR (--failure-level) et tout échec d'Asciidoctor ;
#      - xref sans ancre (« possible invalid reference », simple INFO) ;
#      - include introuvable ;
#      - ID défini deux fois (souvent un fragment inclus deux fois) ;
#      - fragment autonome inclus sans leveloffset (« level 0 sections ») ;
#      - renvoi vers un fichier non inclus dans le maître (voir plus bas) ;
#      - macro registre:: vers un registre inconnu, statut hors liste
#        (registres.rb) ;
#      - bloc diagramme (plantuml, ditaa, graphviz...) non converti — sans
#        asciidoctor-diagram, ou sans ses lignes ---- de délimitation (le
#        bloc devient un paragraphe), Asciidoctor ne lève qu'un DEBUG et
#        rend le code source en texte brut : sans -v, ce message est
#        invisible.
for m in "$@"; do
  m=$(basename "$m")
  log=$("$ASCIIDOCTOR" -v --failure-level WARN $ADOC_OPTS \
          -a diagram-cachedir="$tmp/cache" -a imagesoutdir="$tmp/images" -a appendix-caption=Annexe \
          -D "$tmp" -o check.html "$m" 2>&1)
  st=$?
  # -A5 : un ERROR d'asciidoctor-diagram (PlantUML, Graphviz...) porte sa
  # cause réelle (« cannot include », ligne et caret fautifs) sur les
  # lignes suivantes, pas dans la ligne ERROR elle-même.
  msgs=$(echo "$log" | grep -A5 -E 'WARNING|ERROR|FAILED|possible invalid reference|unknown style for (listing block|paragraph)')
  if [ $st -ne 0 ] || [ -n "$msgs" ]; then
    if [ -n "$msgs" ]; then echo "$msgs"; else echo "$log" | tail -5; fi
    ko "$m : build"
  fi
  dups=$(grep -o 'include::[^[]*' "$m" | sort | uniq -d)
  [ -n "$dups" ] && echo "$dups" && ko "$m : fragment inclus deux fois"
  # Renvoi hors du maître : le livrable est le PDF du maître, où tout renvoi
  # doit être interne. Un xref vers un fichier non inclus (ou un link: vers
  # un fichier local) donne, sans aucun message d'Asciidoctor, un lien vers
  # un fichier qui n'existe pas. Dans le HTML de contrôle, c'est un href
  # relatif : ni ancre (#...), ni URL (schéma:...).
  hrefs=$(grep -oE '<a href="[^"#:][^":]*"' "$tmp/check.html" | sed -E 's/^<a href="//; s/"$//' | sort -u)
  if [ -n "$hrefs" ]; then
    printf '%s\n' "$hrefs" | while IFS= read -r h; do
      f=${h%%#*}; f=${f%.html}
      grep -HnF -e "xref:$f.adoc" -e "link:$f" $ADOCS || echo "$h"
    done
    ko "$m : renvoi vers un document non inclus dans le maître"
  fi
  # Structure selon le type (normes/types.adoc),
  # lue dans le HTML de contrôle, includes résolus. La synthèse est la
  # première section de tout maître.
  prem=$(grep -m1 -o '<h2 id="[^"]*">[^<]*' "$tmp/check.html" | sed 's/.*>//')
  case $prem in
    *Synthèse) ;;
    *) avert "$m : la première section n'est pas la synthèse (« ${prem:-aucune} »)" ;;
  esac
  # Mémo : le corps, jusqu'à la première annexe (libellé « Annexe » imposé
  # au build de contrôle), reste sans code et sur trois niveaux, un de moins que le DAT ; les
  # annexes, destinées aux experts, peuvent être aussi techniques qu'un DAT.
  if [ "$(type_de "$m")" = memo ]; then
    awk '/<h2 id="[^"]*">Annexe [A-Z]/ { exit } { print }' "$tmp/check.html" > "$tmp/corps.html"
    grep -q -E 'class="(listingblock|literalblock)' "$tmp/corps.html" \
      && avert "$m : bloc de code ou littéral dans le corps d'un mémo (annexes admises)"
    grep -q 'class="sect4"' "$tmp/corps.html" \
      && avert "$m : section au-delà de ==== dans le corps d'un mémo (annexes admises)"
  fi
  # Un fragment inclus ne porte pas :type: : il écraserait celui du maître.
  for f in $(grep -o '^include::[^[]*' "$m" | sed 's/^include:://'); do
    [ -f "$f" ] && [ -n "$(type_de "$f")" ] && avert "$f : :type: dans un fragment (réservé au maître)"
  done
done

# 2. Renvois numériques en dur : utiliser <<ID>> ou xref:fichier.adoc#ID[].
#    Si tu cites des § de documents externes, restreins ce motif.
grep -HnE '§ ?[0-9]' $ADOCS && ko "renvoi numérique en dur"

# 3. Restes de LaTeX ou de Markdown (fréquents dans du texte généré).
grep -HnF '$\' $ADOCS && ko "reste de LaTeX"
grep -HnE '\]\(https?://' $ADOCS && ko "lien Markdown"

# 4. Puce collée à une ligne de texte : Asciidoctor la rend en ligne.
#    Ignorés : blocs ---- et .... (mindmaps, WBS, code), et les puces qui
#    suivent la ligne de continuation d'un élément de liste (une phrase par
#    ligne). Heuristique, d'où un simple avertissement.
awk 'FNR == 1 { p = ""; inblk = 0; inlist = 0 }
     /^(----|\.\.\.\.)[ \t]*$/ { inblk = !inblk; p = ""; next }
     inblk { next }
     /^[ \t]*$/ { inlist = 0; p = ""; next }
     /^(\*+|\.+|-) / {
       if (!inlist && p != "" && p !~ "^[[*.+|:=/-]") print FILENAME ":" FNR ": " $0
       inlist = 1
     }
     { p = $0 }' $ADOCS | grep . && avert "puce sans ligne vide avant"

# 5. Orphelins : ID de registre défini par une ancre mais cité nulle part.
#    Ancres reconnues : [[ID]], [[ID,texte]], [#ID], [#ID.role].
#    Citations reconnues : <<ID>>, <<ID,texte>>, xref:ID[], xref:#ID[],
#    xref:fichier.adoc#ID[].
#    Avertissement seulement : un ADR ou un point ouvert peut être récent.
defs=$( { grep -ohE "\[\[($REG_IDS)(,[^]]*)?\]\]" $ADOCS
          grep -ohE "\[#($REG_IDS)([.%,][^]]*)?\]" $ADOCS
        } | sed -E 's/^\[\[?#?//; s/[],.%].*//' | sort -u)
refs=$( { grep -ohE "<<($REG_IDS)(,|>>)" $ADOCS | sed -E 's/^<<//; s/(,|>>)$//'
          grep -ohE "xref:([^[ ]*#)?($REG_IDS)\[" $ADOCS | sed -E 's/.*[:#]//; s/\[$//'
        } | sort -u)
orph=$(printf '%s\n' "$defs" | grep . | while read -r id; do
         printf '%s\n' "$refs" | grep -qx "$id" || echo "$id"
       done)
[ -n "$orph" ] && echo "$orph" && avert "ID de registre jamais cité"

# 6. Mentions nues : un ID de registre écrit en texte simple (« voir H3 »)
#    échappe au build, qui ne vérifie que les xrefs. Sont ignorés : titres,
#    titres de bloc, commentaires, blocs ---- et ...., code inline, ancres,
#    xrefs, et l'ID affiché juste après sa propre ancre ([[H2]]H2, ou
#    « H2:: » sous une ligne [[H2]]). Avertissement : un « H2 » peut aussi
#    désigner autre chose (la base H2) ; ajuste REG_IDS si besoin.
awk -v reg="$REG_IDS" '
  FNR == 1 { inblk = 0; p = "" }
  /^(----|\.\.\.\.)[ \t]*$/ { inblk = !inblk; p = ""; next }
  inblk || /^\/\// || /^=+ / || /^\.[^. ]/ { p = $0; next }
  {
    l = $0
    if (p ~ /^\[(\[[^]]*\]|#[^]]*)\][ \t]*$/) {
      id = p; gsub(/[][# \t]/, "", id); sub(/[,.%].*/, "", id)
      if (index(l, id) == 1) l = substr(l, length(id) + 1)
    }
    gsub(/\[\[[^]]*\]\][A-Za-z0-9-]*/, "", l)
    gsub(/\[#[^]]*\]/, "", l)
    gsub(/<<[^>]*>>/, "", l)
    gsub(/xref:[^[ ]*\[[^]]*\]/, "", l)
    gsub(/`[^`]*`/, "", l)
    if (match(l, "(^|[^A-Za-z0-9_-])(" reg ")([^A-Za-z0-9_-]|$)"))
      print FILENAME ":" FNR ": " $0
    p = $0
  }' $ADOCS | grep . && avert "ID de registre cité sans xref"

# 7. Images introuvables : le build HTML ne vérifie pas qu'une image existe,
#    et asciidoctor-pdf la saute avec un simple WARNING. Les cibles sont
#    résolues depuis images/ (:imagesdir:) ; URL et cibles contenant un
#    attribut ({...}, au début ou au milieu du chemin) sont ignorées.
IMAGESDIR=images
miss=$(grep -HnoE 'image::?[^][:space:][]+\[' $ADOCS | while IFS= read -r l; do
         t=${l#*image:}; t=${t#:}; t=${t%[}
         # Motif ouvert par « ( » : le bash 3.2 de macOS (/bin/sh) prend
         # sinon la « ) » du motif pour la fin de $( ... ) (syntax error
         # near unexpected token ;;). Forme POSIX, admise par tous les shells.
         case $t in (*://*|*\{*) continue ;; esac
         [ -f "$IMAGESDIR/$t" ] || echo "$l"
       done)
[ -n "$miss" ] && echo "$miss" && ko "image introuvable dans $IMAGESDIR/"

# 8. Emojis : la police du PDF n'en contient qu'une partie, les autres
#    s'affichent avec un glyphe faux, sans WARNING. Ruby plutôt que grep :
#    le grep de l'image Docker (BusyBox) ne connaît pas les classes Unicode.
#    Cible : les caractères à présentation emoji par défaut (🚀, ✅) et le
#    sélecteur de variante U+FE0F (⚠️) ; les symboles texte (→, ✓, ©) passent.
ruby -e 're = /[\p{Emoji_Presentation}\u{FE0F}]/
  ARGV.each do |f|
    File.foreach(f, encoding: "UTF-8").with_index(1) do |l, i|
      l = l.scrub
      puts "#{f}:#{i}: #{l}" if l.match?(re)
    end
  end' $ADOCS | grep . && avert "emoji"

# 9. Entrée de registre sans statut : une ancre de registre seule sur sa
#     ligne, suivie d'un titre de section, ouvre une entrée (format de
#     normes/registres.adoc) ; elle doit contenir un titre de
#     bloc .Statut avant la section suivante de même niveau ou plus haute.
awk -v reg="$REG_IDS" '
  function fin() {
    if (id != "" && !statut) print fic ":" lig ": " id
    id = ""
  }
  FNR == 1 { fin(); fic = FILENAME; inblk = 0; ancre = "" }
  /^(----|\.\.\.\.)[ \t]*$/ { inblk = !inblk; next }
  inblk { next }
  $0 ~ "^\\[\\[(" reg ")(,[^]]*)?\\]\\][ \t]*$" {
    ancre = $0; sub(/^\[\[/, "", ancre); sub(/[],].*/, "", ancre); al = FNR; next
  }
  /^=+ / {
    niv = index($0, " ") - 1
    if (id != "" && niv <= nivid) fin()
    if (ancre != "") { id = ancre; nivid = niv; statut = 0; lig = al }
    ancre = ""; next
  }
  /^\.Statut[ \t]*$/ { if (id != "") statut = 1 }
  !/^[ \t]*$/ && !/^\/\// { ancre = "" }
  END { fin() }' $ADOCS | grep . && avert "entrée de registre sans .Statut"

# 10. Admonitions NOTE et CAUTION : une étude n'utilise que TIP, IMPORTANT et
#     WARNING (normes/asciidoc.adoc, « Admonitions »). Formes en ligne
#     (NOTE: texte) et en bloc ([NOTE]), hors blocs ---- et .... d'exemple.
awk 'FNR == 1 { inblk = 0 }
     /^(----|\.\.\.\.)[ \t]*$/ { inblk = !inblk; next }
     !inblk && /^((NOTE|CAUTION): |\[(NOTE|CAUTION)[],])/ { print FILENAME ":" FNR ": " $0 }' $ADOCS \
  | grep . && avert "admonition NOTE ou CAUTION (admises : TIP, IMPORTANT, WARNING)"

# 11. Fragment trop long pour être relu d'un bloc : l'agent travaille dans
#     une fenêtre de 128K tokens, où un chapitre de plus de 40 Ko (environ
#     10 000 tokens) se relit mal avec les normes, les registres et l'historique.
#     Les registres, lus par ID avec rg, font exception.
#     Seuil surchargeable : MAX_FRAGMENT_KO=60 tools/check.sh
MAX_FRAGMENT_KO=${MAX_FRAGMENT_KO:-40}
for f in $ADOCS; do
  case $f in ./hypotheses.adoc|./points-ouverts.adoc|./adr.adoc) continue ;; esac
  t=$(wc -c < "$f")
  [ "$t" -gt $((MAX_FRAGMENT_KO * 1024)) ] && echo "$f : $((t / 1024)) Ko"
done | grep . && avert "fragment de plus de $MAX_FRAGMENT_KO Ko, à découper (normes/fichiers.adoc)"

# 12. Bloc PlantUML sans style commun : sans !include d'un fichier de
#     normes/plantuml/, le schéma sort au style par défaut de PlantUML, sans
#     erreur ni WARNING (normes/schemas.adoc, « Style commun aux schémas »).
#     Un chemin d'!include faux, lui, fait échouer le build (KO en 1).
#     Blocs [plantuml] délimités par ---- ou .... ; la macro plantuml::
#     (fichier externe) n'est pas inspectée.
awk 'FNR == 1 { attend = 0; dans = 0 }
     dans && $0 == fin { if (!style) print FILENAME ":" debut ": bloc PlantUML sans !include normes/plantuml/"; dans = 0; next }
     dans { if ($0 ~ /^[ \t]*!include[ \t]+[^ \t]*normes\/plantuml\//) style = 1; next }
     attend && /^[ \t]*$/ { next }
     attend && /^(----|\.\.\.\.)[ \t]*$/ { dans = 1; style = 0; fin = $0; attend = 0; next }
     { attend = 0 }
     /^\[plantuml[],]/ { attend = 1; debut = FNR }' $ADOCS \
  | grep . && avert "schéma sans style commun : !include normes/plantuml/_<type>.iuml"

exit $rc
