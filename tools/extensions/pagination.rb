# pagination.rb — extension Asciidoctor chargée par tools/build.sh
#
# Corrige des coupures de page qu'asciidoctor-pdf laisse passer et que le
# thème ne sait pas régler (aucune clé ne les couvre).
#
# 1. Blocs de code et blocs littéraux courts (au plus MAX_LIGNES lignes) :
#    gardés d'un seul tenant, par l'option %unbreakable. Sans elle, un bloc
#    de six lignes peut être coupé en bas de page, une ligne d'un côté,
#    cinq de l'autre. Un bloc plus long reste sécable : le reporter entier
#    laisserait jusqu'à une page presque blanche. Un bloc marqué %breakable
#    dans le source n'est pas touché.
#
# 2. Admonitions et encadré de recommandation : toujours d'un seul tenant.
#    Ce sont des blocs courts, dont le titre ou l'icône ne doit pas rester
#    seul en bas de page. Un bloc plus haut qu'une page reste sécable
#    (asciidoctor-pdf ignore alors l'option).
#
# 3. Paragraphes titrés (.Statut, .Contexte... des registres) : le titre
#    d'un paragraphe n'est pas lié à son texte et peut rester seul en bas
#    de page. Le paragraphe est placé dans un bloc ouvert qui porte le
#    titre : asciidoctor-pdf garde le titre d'un bloc avec son contenu.
#    Le rendu est le même, seule la coupure change.

MAX_LIGNES = 15

Asciidoctor::Extensions.register do
  tree_processor do
    process do |doc|
      (doc.find_by(context: :listing) + doc.find_by(context: :literal)).each do |b|
        next if b.option?('breakable') || b.lines.size > MAX_LIGNES
        b.set_option 'unbreakable'
      end

      (doc.find_by(context: :admonition) + doc.find_by(context: :sidebar)).each do |b|
        b.set_option 'unbreakable' unless b.option? 'breakable'
      end

      doc.find_by(context: :paragraph) { |p| p.title? }.each do |p|
        parent = p.parent
        next unless (i = parent.blocks.index p)
        ouvert = Asciidoctor::Block.new parent, :open, content_model: :compound
        ouvert.title = p.title
        p.title = nil
        p.parent = ouvert
        ouvert << p
        parent.blocks[i] = ouvert
      end
      nil
    end
  end
end
