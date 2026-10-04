# conteneur.sh — image et lancement du conteneur Asciidoctor, communs à
#                build.sh et check.sh. Sourcé par eux, jamais exécuté seul.
# Réglages : ASCIIDOCTOR_IMAGE, DOCKER (variables d'environnement du poste).

# Image épinglée : changer de version est un choix explicite, pas un effet
# de bord d'un pull. Un miroir d'entreprise : ASCIIDOCTOR_IMAGE.
IMAGE=${ASCIIDOCTOR_IMAGE:-asciidoctor/docker-asciidoctor:1.108.0}
DOCKER=${DOCKER:-docker}

# conteneur <racine> <commande...> : lance la commande dans l'image, la
# racine montée sur /documents et prise comme dossier courant. L'utilisateur
# courant, pour que work/ ne devienne pas propriété de root ; un HOME
# inscriptible (Java, fontconfig) ; DANS_CONTENEUR, pour qu'un script lancé
# dedans ne cherche pas à s'y relancer.
conteneur() {
  r=$1; shift
  "$DOCKER" run --rm -u "$(id -u):$(id -g)" -e HOME=/tmp -e DANS_CONTENEUR=1 \
    -v "$r":/documents -w /documents "$IMAGE" "$@"
}
