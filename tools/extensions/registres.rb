# registres.rb — extension Asciidoctor chargée par tools/check.sh et
# tools/build.sh (voir normes/registres.adoc et normes/types.adoc).
#
# 1. Macro de bloc registre::<registre>[] : tableau récapitulatif d'un
#    registre (ID, intitulé, statut), généré à partir des entrées elles-mêmes
#    au moment du rendu. Il ne peut donc pas diverger du registre.
#      registre::hypotheses[]              toutes les hypothèses
#      registre::points-ouverts[incertains] seulement les statuts d'attention
#      registre::adr[]
#    Un titre de bloc posé au-dessus de la macro devient le titre du tableau.
#
# 2. Statut coloré : dans chaque entrée de registre, le paragraphe .Statut
#    reçoit le rôle statut-<classe>, que le thème PDF met en couleur.
#
# Le vocabulaire des statuts est fixé ici, une seule fois. Un statut hors
# liste lève un WARNING : KO de check.sh. Le texte du statut commence par la
# valeur (« Validée ») et peut la préciser (« Validée par le métier le... »).
#
# L'aperçu VS Code ne charge pas cette extension : la macro y reste en texte.

REGISTRES = {
  'hypotheses' => /\AH\d+\z/,
  'points-ouverts' => /\APO-\d+\z/,
  'adr' => /\AADR-\d+\z/,
}.freeze

# Classe de statut => valeurs admises, par registre.
STATUTS = {
  'hypotheses' => { 'Non validée' => 'attention', 'Validée' => 'ok', 'Invalidée' => 'alerte' },
  'points-ouverts' => { 'Ouvert' => 'attention', 'Clos' => 'ok' },
  'adr' => { 'Proposé' => 'attention', 'Accepté' => 'ok', 'Rejeté' => 'inactif', 'Remplacé' => 'inactif' },
}.freeze

# Classes affichées par l'option « incertains » : ce dont la recommandation
# dépend encore.
INCERTAINES = %w(attention alerte).freeze

module Registres
  module_function

  def registre_de id
    REGISTRES.find { |_, rx| rx.match? id }&.first
  end

  # Bloc portant le titre « Statut » dans une section d'entrée : un
  # paragraphe, ou un bloc ouvert si pagination.rb l'a déjà enveloppé.
  def paragraphe_statut section
    b = section.blocks.find { |x| x.title? && (x.instance_variable_get :@title) == 'Statut' }
    b = b.blocks[0] if b && b.context == :open
    b&.context == :paragraph ? b : nil
  end

  # [valeur, classe] ; classe nil si la valeur est hors liste.
  def statut registre, texte
    valeurs = STATUTS[registre]
    v = valeurs.keys.sort_by { |k| -k.length }.find { |k| texte.start_with? k }
    v ? [v, valeurs[v]] : [texte.split(/[ .,;]/)[0].to_s, nil]
  end
end

class RegistreMacro < Asciidoctor::Extensions::BlockMacroProcessor
  use_dsl
  named :registre
  name_positional_attributes 'filtre'

  def process parent, target, attrs
    unless REGISTRES.key? target
      Asciidoctor::LoggerManager.logger.warn %(registre::#{target}[] : registre inconnu (attendu : #{REGISTRES.keys.join ', '}))
    end
    # Le titre de bloc posé au-dessus de la macro arrive dans attrs : il est
    # reporté sur le tableau généré.
    create_open_block parent, [], { 'role' => 'registre-a-generer', 'registre' => target,
                                    'filtre' => attrs['filtre'], 'titre-registre' => attrs['title'] }
  end
end

class RegistreTree < Asciidoctor::Extensions::TreeProcessor
  def process doc
    entrees = Hash.new { |h, k| h[k] = [] }
    doc.find_by(context: :section) { |s| s.id && (Registres.registre_de s.id) }.each do |s|
      reg = Registres.registre_de s.id
      titre = (s.instance_variable_get :@title).to_s.sub(/\A#{Regexp.escape s.id}\s*:\s*/, '')
      valeur, classe = nil
      if (p = Registres.paragraphe_statut s)
        texte = p.lines.join(' ').strip
        valeur, classe = Registres.statut reg, texte
        if classe
          p.add_role %(statut-#{classe})
        else
          Asciidoctor::LoggerManager.logger.warn %(#{s.id} : statut « #{texte} » hors liste (attendu : #{STATUTS[reg].keys.join ', '}))
        end
      end
      entrees[reg] << [s.id, titre, valeur, classe]
    end

    doc.find_by(context: :open) { |b| b.role? 'registre-a-generer' }.each do |ph|
      reg = ph.attr 'registre'
      liste = entrees[reg]
      if ph.attr('filtre') == 'incertains'
        # Hors liste ou sans statut : incertain par prudence.
        liste = liste.select { |e| e[3].nil? || (INCERTAINES.include? e[3]) }
      end
      lignes = []
      lignes << %(.#{ph.attr 'titre-registre'}) if ph.attr? 'titre-registre'
      if liste.empty?
        lignes << '_Aucune entrée._'
      else
        lignes << '[cols="1,6,2"]' << '|===' << '| ID | Intitulé | Statut' << ''
        liste.each do |id, titre, valeur, classe|
          st = valeur ? (classe ? %([.statut-#{classe}]##{valeur}#) : valeur) : '_sans statut_'
          lignes << %(| <<#{id},#{id}>> | #{titre.gsub '|', '\|'} | #{st})
        end
        lignes << '|==='
      end
      bloc = Asciidoctor::Block.new ph.parent, :open, content_model: :compound
      parse_content bloc, lignes
      i = ph.parent.blocks.index ph
      ph.parent.blocks[i] = bloc
    end
    nil
  end
end

Asciidoctor::Extensions.register do
  block_macro RegistreMacro
  tree_processor RegistreTree
end
