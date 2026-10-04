#!/bin/sh
# rendu.sh — PDF de démonstration du thème, pour relire le rendu après une
#            modification de tools/pdf-theme/, tools/extensions/,
#            tools/build.sh ou normes/plantuml/.
# Usage    : tools/tests/rendu.sh
# Sortie   : work/rendu.pdf ; rien n'est produit si check.sh est en KO.
#
# Les sources, dans tools/tests/rendu/, sont un maître et ses fragments
# comme ceux d'une étude. Ils sont copiés dans work/rendu/, avec des liens
# relatifs vers normes/ et images/ : les chemins des !include PlantUML et des
# images y sont les mêmes qu'à la racine d'une étude, et restent valides dans
# le conteneur de build.sh, qui monte la racine du dépôt.

set -eu

root=$(cd "$(dirname "$0")/../.." && pwd)
d="$root/work/rendu"
rm -rf "$d"
mkdir -p "$d"
cp "$root"/tools/tests/rendu/*.adoc "$d"/
ln -s ../../normes "$d/normes"
ln -s ../../images "$d/images"
exec "$root/tools/build.sh" work/rendu/rendu.adoc
