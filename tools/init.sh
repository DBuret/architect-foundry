#!/bin/sh
# init.sh — mise en place d'une étude clonée depuis le modèle, en une commande.
# Usage     : tools/init.sh --projet NOM [--kb BASE] [--sites URL,URL]
#                           [--maitres memo,dat,note] [--depot URL]
#             depuis n'importe quel dossier. Sans option et dans un terminal,
#             il demande les valeurs.
#   --projet  : valeur de :project: dans chaque maître gardé.
#   --kb      : base de connaissances du projet (:kb-projet:), telle que
#               déclarée dans ~/.pi/agent/rag.json. Sans elle, :kb-projet:
#               reste vide : l'étude n'a pas de base projet.
#   --sites   : URL des sites de référence du projet (:sites-projet:),
#               séparées par des virgules ; vide par défaut.
#   --maitres : maîtres à garder ; les autres sont supprimés (git rm).
#               Par défaut, tous ceux présents.
#   --depot   : URL du dépôt de l'étude. Le remote origin, qui pointe sur le
#               modèle après le clone, devient modele, et origin pointe sur
#               cette URL. Rien n'est poussé.
# Effets    : hook pre-commit ; pilote de fusion merge=etude si un remote
#             modele existe ; attributs des maîtres gardés ; check.sh.
#             Relancé, il remplace les valeurs par les nouvelles.
# Sortie    : code retour de check.sh ; 2 sur une erreur d'usage.

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1

usage() { sed -n '3,4p' "$0" | sed 's/^# Usage     : /usage : /; s/^#//' >&2; exit 2; }

projet=; kb=; sites=; maitres=; depot=; vu_sites=0
while [ $# -gt 0 ]; do
  case $1 in
    --projet)  [ $# -ge 2 ] || usage; projet=$2; shift 2 ;;
    --kb)      [ $# -ge 2 ] || usage; kb=$2; shift 2 ;;
    --sites)   [ $# -ge 2 ] || usage; sites=$2; vu_sites=1; shift 2 ;;
    --maitres) [ $# -ge 2 ] || usage; maitres=$2; shift 2 ;;
    --depot)   [ $# -ge 2 ] || usage; depot=$2; shift 2 ;;
    *) usage ;;
  esac
done

presents=$(grep -l -E '^:type:[[:space:]]*(memo|dat|note)[[:space:]]*$' ./*.adoc 2>/dev/null | sed 's|^\./||; s|\.adoc$||' | tr '\n' ',' | sed 's/,$//')
[ -n "$presents" ] || { echo "KO     aucun maître (:type: memo, dat ou note) à la racine" >&2; exit 1; }

# Valeurs manquantes : demandées dans un terminal, erreur sinon.
demander() {  # demander <variable> <question> <défaut>
  eval "v=\$$1"
  [ -n "$v" ] && return
  [ -t 0 ] || { echo "valeur manquante : --$1" >&2; usage; }
  printf '%s%s : ' "$2" "${3:+ [$3]}" >&2; read -r v
  [ -n "$v" ] || v=$3
  eval "$1=\$v"
}
demander projet "Nom du projet (:project:)" ""
[ -n "$projet" ] || usage
if [ -z "$kb" ] && [ -t 0 ]; then
  printf 'Base de connaissances du projet (:kb-projet:) [aucune] : ' >&2; read -r kb
fi
if [ $vu_sites -eq 0 ] && [ -t 0 ]; then
  printf 'Sites de référence, séparés par des virgules (:sites-projet:) [aucun] : ' >&2; read -r sites
fi
if [ -z "$maitres" ] && [ -t 0 ]; then
  demander maitres "Maîtres à garder" "$presents"
fi
[ -n "$maitres" ] || maitres=$presents

# Maîtres : chaque nom gardé doit exister ; les autres sont supprimés.
for m in $(echo "$maitres" | tr ',' ' '); do
  case ,$presents, in *,$m,*) ;; *) echo "maître inconnu : $m (présents : $presents)" >&2; exit 2 ;; esac
done
for m in $(echo "$presents" | tr ',' ' '); do
  case ,$maitres, in
    *,$m,*) ;;
    *) if git ls-files --error-unmatch "$m.adoc" >/dev/null 2>&1; then git rm -q "$m.adoc"; else rm -f "$m.adoc"; fi
       echo "supprimé : $m.adoc" ;;
  esac
done

# Attributs du header (du titre à la première ligne vide) de chaque maître
# gardé. awk -v garde les URL telles quelles, sans échappement de sed.
for m in $(echo "$maitres" | tr ',' ' '); do
  f=$m.adoc
  awk -v p="$projet" -v k="$kb" -v s="$sites" '
    NR > 1 && /^[ \t]*$/ { h = 1 }
    !h && /^:project:/      { print ":project: " p; next }
    !h && /^:kb-projet:/    { print ":kb-projet:" (k == "" ? "" : " " k); next }
    !h && /^:sites-projet:/ { print ":sites-projet:" (s == "" ? "" : " " s); next }
    { print }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  if [ -n "$kb" ]; then b="base $kb"; else b="sans base projet"; fi
  echo "renseigné : $f (projet $projet, $b)"
done

# Git : hook, remotes, pilote de fusion.
git config core.hooksPath tools/hooks && echo "hook pre-commit activé"
if [ -n "$depot" ]; then
  if git remote get-url modele >/dev/null 2>&1; then
    git remote set-url origin "$depot" 2>/dev/null || git remote add origin "$depot"
  else
    git remote rename origin modele && git remote add origin "$depot"
  fi
  echo "remotes : modele → $(git remote get-url modele), origin → $depot"
fi
if git remote get-url modele >/dev/null 2>&1; then
  git config merge.etude.driver true && echo "pilote de fusion merge=etude configuré"
fi

if [ -n "$kb" ]; then
  base="la base $kb dans ~/.pi/agent/rag.json, puis ingest run <dossier> --kb $kb"
else
  base="sans base projet, l'agent ne vérifie rien dans les entrants : pour en ajouter une, relancer avec --kb"
fi

echo
tools/check.sh; rc=$?

cat <<EOF

Reste à faire à la main :
  - le titre de chaque maître gardé ($maitres) ;
  - les logos : tools/pdf-theme/header-logo.png et images/logo.png ;
  - $base ;
  - les entrées d'exemple H1, PO-01 et ADR-01 ;
  - git commit, puis git push -u origin main.
EOF
exit $rc
