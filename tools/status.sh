#!/bin/sh
# status.sh — état de l'étude en un coup d'œil : outils, maîtres, registres,
#             contrôles, fraîcheur des PDF, git. Ne modifie rien.
# Usage     : tools/status.sh [--rapide | --comite]
#             depuis n'importe quel dossier.
#             --rapide : sans check.sh (quelques secondes de moins).
#             --comite : seulement ce qui attend une réponse, entrée par
#             entrée : points ouverts (porteur, échéance, échéance passée),
#             hypothèses non validées ou invalidées, ADR proposées.
# Sortie    : code retour 1 si check.sh est en KO, 0 sinon.
#
# Le détail des KO et AVERT reste celui de check.sh : status.sh n'en donne
# que le décompte et les intitulés.

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1

rapide=0; comite=0
case ${1:-} in
  --rapide) rapide=1 ;;
  --comite) comite=1 ;;
  '') ;;
  *) echo "usage : tools/status.sh [--rapide | --comite]" >&2; exit 2 ;;
esac

ok()   { printf '  \342\234\223 %s\n' "$1"; }   # ✓
nok()  { printf '  \342\234\227 %s\n' "$1"; }   # ✗
warn() { printf '  ! %s\n' "$1"; }
titre() { printf '\n%s\n' "$1"; }
has()  { command -v "$1" >/dev/null 2>&1; }

# Header d'un document : du titre à la première ligne vide.
attr() { awk -v a=":$2:" 'NR > 1 && /^[ \t]*$/ { exit } index($0, a) == 1 { sub(/^:[^:]+:[ \t]*/, ""); print; exit }' "$1"; }

maitres=$(grep -l -E '^:type:[[:space:]]*(memo|dat|note)[[:space:]]*$' ./*.adoc 2>/dev/null | sed 's|^\./||')

# En-tête : titre du premier maître, projet.
m1=$(printf '%s\n' "$maitres" | head -1)
if [ -n "$m1" ]; then
  printf 'Étude : %s  (projet : %s)\n' "$(sed -n '1s/^= *//p' "$m1")" "$(attr "$m1" project)"
else
  printf 'Étude : aucun maître (:type: memo, dat ou note) à la racine\n'
fi
printf '%s\n' '────────────────────────────────'

# Vue comité : une ligne par entrée en attente, lue dans les registres.
# entrees <fichier> <rubrique> <rubrique> : ID, intitulé, statut et texte des
# deux rubriques, séparés par le caractère US (\037), qui, à la différence
# d'une tabulation, garde un champ vide à sa place ; rubrique absente, vide.
us=$(printf '\037')
entrees() {
  awk -v r1=".$2" -v r2=".$3" -v us="$us" '
    function sortie() { if (id != "") print id us tit us st us v1 us v2 }
    /^\[\[[A-Z][A-Z0-9-]*\]\][ \t]*$/ { sortie(); id = $0; gsub(/[][ \t]/, "", id)
                                         tit = st = v1 = v2 = cur = ""; next }
    id != "" && tit == "" && /^== / { tit = $0; sub(/^== [^:]*:[ \t]*/, "", tit); next }
    /^\.[^. ]/ { cur = $0; sub(/[ \t]*$/, "", cur); next }
    NF && cur != "" { if (cur == ".Statut" && st == "") st = $0
                      else if (cur == r1 && v1 == "") v1 = $0
                      else if (cur == r2 && v2 == "") v2 = $0
                      cur = "" }
    END { sortie() }' "$1"
}
# Échéance passée : texte de l'échéance en AAAA-MM-JJ, JJ/MM/AAAA,
# « 15 avril 2026 » ou « avril 2026 » (fin du mois) ; sinon, rien à dire.
echeance_passee() {
  printf '%s\n' "$1" | awk -v auj="$(date +%Y%m%d)" '
    BEGIN { split("janvier février mars avril mai juin juillet août septembre octobre novembre décembre", m, " ")
            for (i = 1; i <= 12; i++) mois[m[i]] = i }
    { l = tolower($0); d = 0
      if (match(l, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
        s = substr(l, RSTART, 10); d = substr(s, 1, 4) substr(s, 6, 2) substr(s, 9, 2)
      } else if (match(l, /[0-9][0-9]?\/[0-9][0-9]?\/[0-9][0-9][0-9][0-9]/)) {
        split(substr(l, RSTART, RLENGTH), p, "/"); d = sprintf("%04d%02d%02d", p[3], p[2], p[1])
      } else {
        n = split(l, w, /[^a-z0-9\200-\377]+/)
        for (i = 2; i <= n; i++) if ((w[i - 1] in mois) && w[i] ~ /^[0-9][0-9][0-9][0-9]$/) {
          j = 31; if (i > 2 && w[i - 2] ~ /^[0-9][0-9]?(er)?$/) j = w[i - 2] + 0
          d = sprintf("%04d%02d%02d", w[i], mois[w[i - 1]], j); break
        }
      }
      exit !(d > 0 && d < auj) }'
}
if [ $comite -eq 1 ]; then
  if [ -f points-ouverts.adoc ]; then
    titre "Points ouverts"
    entrees points-ouverts.adoc Porteur Échéance | while IFS=$us read -r id tit st por ech; do
      case $st in Ouvert*) ;; *) continue ;; esac
      marque=; echeance_passee "$ech" && marque='  ÉCHÉANCE PASSÉE'
      printf '  %-7s %s\n          porteur : %s\n          échéance : %s%s\n' "$id" "$tit" "$por" "$ech" "$marque"
    done
  fi
  if [ -f hypotheses.adoc ]; then
    titre "Hypothèses non validées ou invalidées"
    entrees hypotheses.adoc Origine - | while IFS=$us read -r id tit st ori _; do
      case $st in Validée*) continue ;; esac
      printf '  %-7s %s\n          %s\n          origine : %s\n' "$id" "$tit" "$st" "$ori"
    done
  fi
  if [ -f adr.adoc ]; then
    titre "Décisions proposées"
    entrees adr.adoc - - | while IFS=$us read -r id tit st _; do
      case $st in Proposé*) printf '  %-7s %s\n' "$id" "$tit" ;; esac
    done
  fi
  exit 0
fi

# Outils. Asciidoctor local sert à check.sh ; Docker, au PDF.
titre "Outils"
# Sans asciidoctor sur le poste, check.sh passe par le conteneur.
for c in asciidoctor ruby java; do
  if has "$c"; then ok "$c"
  elif [ $c = asciidoctor ] && has "${DOCKER:-docker}"; then warn "asciidoctor absent : contrôles dans le conteneur, plus lents"
  else nok "$c absent"; fi
done
if has gem; then
  for g in asciidoctor-diagram asciidoctor-diagram-plantuml; do
    if gem list -i "^$g\$" >/dev/null 2>&1; then ok "gem $g"; else warn "gem $g absente (schémas non contrôlés)"; fi
  done
fi
# PDF : outils du poste d'abord, conteneur à défaut (tools/build.sh).
d=${DOCKER:-docker}
if has asciidoctor-pdf; then ok "asciidoctor-pdf : PDF avec les outils du poste"
elif has "$d"; then ok "$d : PDF dans le conteneur (image : ${ASCIIDOCTOR_IMAGE:-version de build.sh})"
else nok "ni asciidoctor-pdf ni $d : pas de PDF"; fi
if [ "$(git config core.hooksPath 2>/dev/null)" = tools/hooks ]; then ok "hook pre-commit"
else warn "hook pre-commit non installé : git config core.hooksPath tools/hooks"; fi
# Étude rattachée au modèle : le pilote de fusion protège ses fichiers
# (.gitattributes, doc/architecture.adoc « Étude et modèle »).
if git remote get-url modele >/dev/null 2>&1; then
  if [ "$(git config merge.etude.driver 2>/dev/null)" = true ]; then ok "remote modele, fichiers de l'étude protégés à la fusion"
  else warn "remote modele sans pilote de fusion : git config merge.etude.driver true"; fi
fi

# Maîtres et leurs fragments.
titre "Documents"
if [ -z "$maitres" ]; then nok "aucun maître"; fi
for m in $maitres; do
  n=$(grep -c '^include::' "$m")
  ok "$m ($(attr "$m" type), $n inclusions)"
done

# Registres : nombre d'entrées et répartition par statut (première valeur
# du paragraphe qui suit « .Statut »).
titre "Registres"
for r in hypotheses:Hypothèses points-ouverts:"Points ouverts" adr:ADR; do
  f=${r%%:*}.adoc; lib=${r#*:}
  if [ ! -f "$f" ]; then printf '    -  %s : absent\n' "$lib"; continue; fi
  awk -v lib="$lib" '
    /^\[\[[A-Z][A-Z0-9-]*\]\]/ { n++; attendu = 0 }
    /^\.Statut[ \t]*$/ { attendu = 1; next }
    attendu && NF { s = $0; sub(/[ .,;].*$/, "", s)
                    if ($0 ~ /^Non validée/) s = "Non validée"
                    c[s]++; attendu = 0 }
    END {
      d = ""; for (k in c) d = d (d ? ", " : "") c[k] " " k
      printf "  %3d  %s%s\n", n, lib, (d ? " (" d ")" : "")
    }' "$f"
done

# Contrôles : décompte de check.sh.
titre "Contrôles (check.sh)"
rc=0
if [ $rapide -eq 1 ]; then
  warn "non lancés (--rapide)"
else
  out=$(sh tools/check.sh 2>&1); rc=$?
  nko=$(printf '%s\n' "$out" | grep -c '^KO ')
  nav=$(printf '%s\n' "$out" | grep -c '^AVERT ')
  refs=$(cat ./*.adoc 2>/dev/null | grep -oE '<<[^>]+>>|xref:[^[ ]*\[' | wc -l | tr -d ' ')
  ok "$refs renvois (xref et <<>>)"
  if [ "$nko" -eq 0 ]; then ok "aucun KO"; else nok "$nko KO"; fi
  printf '%s\n' "$out" | grep -E '^(KO|AVERT) ' | sed -E 's/^KO +/    KO     /; s/^AVERT +/    AVERT  /'
  [ "$nav" -eq 0 ] && ok "aucun AVERT"
fi

# Rendu : un PDF est à jour s'il est plus récent que toute source de l'étude
# (.adoc de la racine hors README, images/, normes/, thème et extensions).
titre "Rendu"
for m in $maitres; do
  pdf=work/$(basename "$m" .adoc).pdf
  if [ ! -f "$pdf" ]; then warn "$pdf : non généré (tools/build.sh)"; continue; fi
  recent=$(find ./*.adoc images normes tools/pdf-theme tools/extensions -type f ! -name README.adoc -newer "$pdf" 2>/dev/null | head -1)
  if [ -n "$recent" ]; then warn "$pdf : périmé (${recent#./} modifié depuis)"
  else ok "$pdf : à jour"; fi
done

# Git.
titre "Git"
if git rev-parse --git-dir >/dev/null 2>&1; then
  br=$(git branch --show-current)
  ok "branche ${br:-détachée}"
  nm=$(git status --porcelain | grep -vc '^??')
  nn=$(git status --porcelain | grep -c '^??')
  if [ "$nm" -eq 0 ] && [ "$nn" -eq 0 ]; then ok "arbre propre"
  else warn "$nm fichier(s) modifié(s), $nn non suivi(s)"; fi
  if up=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null); then
    set -- $(git rev-list --left-right --count "HEAD...$up")
    [ "$1" -gt 0 ] && warn "$1 commit(s) non poussé(s) vers $up"
    [ "$2" -gt 0 ] && warn "$2 commit(s) de $up non récupéré(s)"
    [ "$1" -eq 0 ] && [ "$2" -eq 0 ] && ok "synchronisé avec $up"
  fi
fi

exit $rc
