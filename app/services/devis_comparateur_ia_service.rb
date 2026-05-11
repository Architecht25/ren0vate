# DevisComparateurIaService
#
# Génère une recommandation IA (Claude) sur un ensemble de devis d'un projet.
# Analyse comparative : rapport qualité/prix, postes manquants, anomalies, conseils.
#
# Usage :
#   result = DevisComparateurIaService.new(project).analyser
#   result[:success]        # true/false
#   result[:recommandation] # texte markdown
#   result[:alerte_anomalie] # true/false

class DevisComparateurIaService
  include HTTParty

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-opus-4-5'
  MAX_TOKENS        = 1200

  def initialize(project)
    @project = project
  end

  def analyser
    api_key = ENV['ANTHROPIC_API_KEY']
    return { success: false, error: 'API IA non configurée' } unless api_key.present?

    devis = @project.devis_donnees
                    .par_categorie('entrepreneur')
                    .avec_montant
                    .includes(:document)
                    .order(created_at: :desc)

    return { success: false, error: 'Aucun devis avec montant disponible' } if devis.empty?

    prompt = construire_prompt(devis)

    response = HTTParty.post(
      ANTHROPIC_API_URL,
      headers: {
        'x-api-key'         => api_key,
        'anthropic-version' => ANTHROPIC_VERSION,
        'anthropic-beta'    => 'prompt-caching-2024-07-31',
        'content-type'      => 'application/json'
      },
      body: {
        model:      MODEL,
        max_tokens: MAX_TOKENS,
        system:     system_prompt,
        messages:   [{ role: 'user', content: prompt }]
      }.to_json,
      timeout: 45
    )

    unless response.success?
      Rails.logger.error "DevisComparateurIaService error #{response.code}: #{response.body[0..200]}"
      return { success: false, error: 'Erreur API IA' }
    end

    texte = response.dig('content', 0, 'text')&.strip
    return { success: false, error: 'Réponse vide' } unless texte.present?

    data = parse_response(texte)
    return { success: false, error: 'Format de réponse invalide' } unless data

    {
      success:          true,
      recommandation:   data['recommandation'],
      meilleur_devis:   data['meilleur_devis'],
      points_attention: Array(data['points_attention']),
      conseils_nego:    Array(data['conseils_negociation']),
      alerte_anomalie:  data['alerte_anomalie'] == true
    }

  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    { success: false, error: 'Délai dépassé — réessayez' }
  rescue StandardError => e
    Rails.logger.error "DevisComparateurIaService: #{e.message}"
    { success: false, error: 'Erreur inattendue' }
  end

  private

  def construire_prompt(devis)
    montants   = devis.map { |d| d.montant_total_htva.to_f }.reject(&:zero?)
    tous_types = devis.flat_map { |d| Array(d.types_travaux_detectes) }.uniq.sort

    lignes = devis.map.with_index(1) do |d, i|
      manquants = (tous_types - Array(d.types_travaux_detectes)).join(', ')
      [
        "Devis ##{i} — #{d.nom_entreprise.presence || 'Entreprise inconnue'}",
        "  BCE : #{d.numero_bce_entreprise.presence || 'non renseigné'}",
        "  Montant HTVA : #{d.montant_total_htva ? "#{d.montant_total_htva.to_f.round(0)} €" : 'non extrait'}",
        "  TVA : #{d.taux_tva ? "#{d.taux_tva.to_i}%" : 'non précisée'}",
        "  Travaux couverts : #{Array(d.types_travaux_detectes).join(', ').presence || 'non détectés'}",
        ("  ⚠️ Postes absents vs autres devis : #{manquants}" if manquants.present?),
        "  Validité : #{d.validite_devis ? d.validite_devis.strftime('%d/%m/%Y') : 'non précisée'}#{d.devis_expire? ? ' (EXPIRÉ)' : ''}",
        "  Surface : #{d.surface_travaux ? "#{d.surface_travaux} m²" : 'non mentionnée'}",
        "  Confiance extraction : #{d.confiance_ocr&.round(0) || '?'}%"
      ].compact.join("\n")
    end

    estimatif = @project.property&.quotes&.order(created_at: :desc)&.first
    ref_line  = estimatif ? "Montant estimatif de référence : #{estimatif.total_avg&.round(0)} € HTVA" : nil

    [
      "Projet : #{@project.name.presence || 'Rénovation'}",
      ref_line,
      "Nombre de devis : #{devis.count}",
      "",
      lignes.join("\n\n")
    ].compact.join("\n")
  end

  def system_prompt
    [{
      type: 'text',
      text: <<~PROMPT,
        Tu es un expert belge en marchés de travaux de rénovation résidentielle.
        Tu aides des particuliers à comparer des devis d'entrepreneurs.
        Sois direct, pratique et concis. Réponds en français.

      Analyse les devis fournis et réponds UNIQUEMENT avec un objet JSON valide :
      {
        "recommandation": "paragraphe de synthèse (max 120 mots) — quel devis recommandes-tu et pourquoi",
        "meilleur_devis": "Nom de l'entreprise recommandée ou null si insuffisant",
        "points_attention": ["point 1", "point 2", ...],
        "conseils_negociation": ["conseil 1", "conseil 2", ...],
        "alerte_anomalie": true|false
      }

      Pour "alerte_anomalie" : true si un devis semble anormalement bas (dumping) ou haut (erreur de périmètre).
      Pour "points_attention" : max 4 points, focus sur postes manquants, validités expirées, BCE absent, écarts de TVA.
      Pour "conseils_negociation" : max 3 conseils concrets à donner au client.
    PROMPT
      cache_control: { type: 'ephemeral' }
    }]
  end

  def parse_response(raw)
    json_str = raw[/\{.*\}/m]
    return nil unless json_str
    JSON.parse(json_str)
  rescue JSON::ParserError => e
    Rails.logger.warn "DevisComparateurIaService JSON parse: #{e.message}"
    nil
  end
end
