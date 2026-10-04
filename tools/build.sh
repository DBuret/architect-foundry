#!/bin/sh
# build.sh — contrôle puis rendu PDF d'une étude, avec les outils du poste ou,
#            à défaut, dans le conteneur Asciidoctor
# Usage     : tools/build.sh [maitre.adoc ...]
#             depuis n'importe quel dossier ; un maître est relatif à la racine.
#             Sans argument : tous les maîtres de la racine (:type: memo, dat
#             ou note dans le header).
# Prérequis : sur le poste, asciidoctor-pdf, les gems asciidoctor-diagram,
#             asciidoctor-diagram-plantuml, rouge et text-hyphen, et Java ;
#             à défaut, docker (ou podman), dont l'image contient tout.
#             BUILD=docker force le conteneur, pour un rendu aux versions
#             exactes de l'image.
# Réglages : variables d'environnement, à poser une fois par poste dans le
#             profil du shell : BUILD, ASCIIDOCTOR_IMAGE, DOCKER,
#             PDF_HEADER_LOGO, PDF_HEADER_LOGO_WIDTH.
# Sortie    : work/<maître>.pdf pour chaque maître ; schémas dans work/images/.
#             Rien n'est produit si check.sh est en KO.
#
# Les attributs de rendu PDF (thème, page de titre, légendes...) sont posés
# ici et non dans le header des documents : voir normes/fichiers.adoc.
# Suffixe @ : valeur par défaut, qu'un header de document peut remplacer.
# Sans suffixe : imposé, le header ne peut pas le changer.
# hyphens=fr : césure française du texte justifié (gem text-hyphen, présente
# dans l'image) ; sans elle, les mots longs creusent des blancs entre les mots.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)

# Image et lancement du conteneur : tools/conteneur.sh, commun avec check.sh.
. "$root/tools/conteneur.sh"

# Outils du poste d'abord, conteneur à défaut : tous les outils du rendu
# doivent être là, sinon le PDF serait produit sans schémas, sans coloration
# ou sans césure.
outils_locaux() {
  command -v asciidoctor-pdf >/dev/null 2>&1 && command -v java >/dev/null 2>&1 &&
    ruby -e 'require "asciidoctor-diagram"; gem "asciidoctor-diagram-plantuml"; require "rouge"; require "text/hyphen"' >/dev/null 2>&1
}
if [ "${BUILD:-}" != docker ] && outils_locaux; then
  mode=poste
  base=$root
else
  command -v "$DOCKER" >/dev/null 2>&1 || {
    echo "build : ni les outils de rendu sur le poste ni $DOCKER ; voir doc/howto.adoc, « Produire le PDF »" >&2
    exit 1
  }
  mode=conteneur
  base=/documents
fi

# Logo d'en-tête : chemin relatif à la racine, vu sous $base (la racine
# sur le poste, /documents dans le conteneur). Par défaut, tools/pdf-theme/header-logo.png, image neutre à
# remplacer par le logo de l'entreprise sous le même nom ; « aucun » : pas
# de logo. Le thème affiche l'attribut header-logo.
logo=${PDF_HEADER_LOGO:-tools/pdf-theme/header-logo.png}
header_logo=
if [ "$logo" != aucun ]; then
  [ -f "$root/$logo" ] || { echo "build : PDF_HEADER_LOGO introuvable : $root/$logo" >&2; exit 1; }
  header_logo="image:$base/$logo[width=${PDF_HEADER_LOGO_WIDTH:-200}]"
fi

if [ $# -eq 0 ]; then
  cd "$root"
  set -- $(grep -l -E '^:type:[[:space:]]*(memo|dat|note)[[:space:]]*$' ./*.adoc | sed 's|^\./||')
  [ $# -gt 0 ] || { echo "build : aucun maître (:type: memo, dat ou note) à la racine" >&2; exit 1; }
fi
for m in "$@"; do
  [ -f "$root/$m" ] || { echo "build : maître introuvable : $root/$m" >&2; exit 1; }
done
mkdir -p "$root/work"

# Toute commande s'exécute depuis la racine, sur le poste ou dans le
# conteneur (tools/conteneur.sh).
run() {
  if [ "$mode" = poste ]; then
    (cd "$root" && "$@")
  else
    conteneur "$root" "$@"
  fi
}
echo "build : rendu $( [ "$mode" = poste ] && echo 'avec les outils du poste' || echo "dans le conteneur $IMAGE" )"

# PlantUML mesure chaque texte avec la police des schémas (DejaVu Sans,
# normes/plantuml/_commun.iuml) : absente du poste, il en prend une autre, et
# le PDF étire le texte jusqu'à la largeur mesurée, sans erreur. Fréquent
# sur macOS ; l'image Docker l'a toujours.
if [ "$mode" = poste ] &&
   ! { fc-list 2>/dev/null | grep -qi 'DejaVu Sans'; } &&
   ! ls "$HOME"/Library/Fonts/DejaVuSans*.ttf /Library/Fonts/DejaVuSans*.ttf >/dev/null 2>&1; then
  echo "build : AVERT police DejaVu Sans absente du poste : texte des schémas étiré possible ; l'installer, ou BUILD=docker" >&2
fi

run sh tools/check.sh "$@" || {
  echo "build : check.sh en KO, PDF non produit." >&2
  exit 1
}

# Le cache des schémas (diagram-cachedir) est indexé sur le texte du bloc
# PlantUML dans le .adoc, pas sur le contenu des fichiers !include : éditer
# un style partagé de normes/plantuml/ sans purger le cache laisserait le
# PDF livré avec l'ancien style, silencieusement. On le purge à chaque
# build ; check.sh, lui, utilise déjà un cache neuf à chaque appel.
rm -rf "$root/work/cache"

run asciidoctor-pdf -r asciidoctor-diagram \
  -r ./tools/extensions/pagination.rb \
  -r ./tools/extensions/registres.rb \
  -a pdf-themesdir="$base/tools/pdf-theme" \
  -a pdf-theme=custom \
  -a header-logo="$header_logo" \
  -a title-page@ \
  -a 'title-logo-image=image:logo.png[pdfwidth=60%,align=center]@' \
  -a toc-title=Sommaire@ \
  -a icons=font \
  -a table-caption! -a example-caption! -a listing-caption! -a figure-caption! \
  -a source-highlighter=rouge -a rouge-style=github \
  -a compress \
  -a hyphens=fr@ \
  -a appendix-caption=Annexe@ \
  -a docdate="$(date +%Y-%m-%d)" \
  -D work "$@"

for m in "$@"; do echo "build : work/$(basename "$m" .adoc).pdf"; done

# Textes provisoires du modèle (« À rédiger. », « À désigner. », « À fixer. »)
# restés dans un maître ou ce qu'il inclut : normaux pendant la rédaction,
# donc absents de check.sh, mais à ne pas livrer. AVERT, sans bloquer.
# inclus <fichier> : le fichier et, récursivement, ses include:: (chemins
# relatifs au dossier du fichier qui inclut, comme pour asciidoctor ; hors
# commentaires et chemins à attribut).
inclus() {
  case " $vus " in *" $1 "*) return ;; esac
  vus="$vus $1"
  echo "$1"
  for f in $(sed -n 's/^include::\([^[{]*\)\[.*/\1/p' "$1"); do
    case $1 in */*) f=${1%/*}/$f ;; esac
    [ -f "$f" ] && inclus "$f"
  done
}
cd "$root"
for m in "$@"; do
  vus=
  prov=$(inclus "$m" | xargs grep -n -H -E '^À (rédiger|désigner|fixer)' 2>/dev/null || true)
  [ -n "$prov" ] || continue
  echo "build : AVERT $m : $(printf '%s\n' "$prov" | wc -l | tr -d ' ') texte(s) provisoire(s) dans le PDF :" >&2
  printf '%s\n' "$prov" | sed 's/^/  /' >&2
done
