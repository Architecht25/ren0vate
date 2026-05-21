# BudgetOptimiseurService
#
# Analyse IA des devis d'un projet et propose des pistes d'économies :
# alternatives matériaux, alertes hausse pétrolière, regroupements de lots.
# Retourne un score d'optimisation 0-100 et des économies estimées en €.
#
# Usage :
#   result = BudgetOptimiseurService.new(project).analyser
#   result[:success]            # true/false
#   result[:score_optimisation] # 0-100
#   result[:economies_estimees] # montant en €
#   result[:alternatives]       # [{poste:, alternative:, economie_estimee:, ...}]

class BudgetOptimiseurService
  include HTTParty

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-opus-4-5'
  MAX_TOKENS        = 1500

  # Postes dont le prix est exposé aux cours du pétrole (dérivés pétroliers dans la fabrication)
  ITEMS_PETROLIERS = %w[
    chassis_pvc
    etancheite_toiture
    isolation_toiture
    isolation_murs_ext
    isolation_murs_int
    isolation_murs_coulisse
    isolation_plancher
    peinture_int
    enduit_murs_ext
    enduit_murs_int
  ].freeze

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
      Rails.logger.error "BudgetOptimiseurService error #{response.code}: #{response.body[0..200]}"
      return { success: false, error: 'Erreur API IA' }
    end

    texte = response.dig('content', 0, 'text')&.strip
    return { success: false, error: 'Réponse vide' } unless texte.present?

    data = parse_response(texte)
    return { success: false, error: 'Format de réponse invalide' } unless data

    {
      success:            true,
      score_optimisation: data['score_optimisation'].to_i.clamp(0, 100),
      synthese:           data['synthese'],
      alternatives:       Array(data['alternatives']),
      risques_petroliers: Array(data['risques_petroliers']),
      optimisations_lots: Array(data['optimisations_lots']),
      economies_estimees: data['economies_estimees'].to_i
    }

  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    { success: false, error: 'Délai dépassé — réessayez' }
  rescue StandardError => e
    Rails.logger.error "BudgetOptimiseurService: #{e.message}"
    { success: false, error: 'Erreur inattendue' }
  end

  private

  def construire_prompt(devis)
    tous_types    = devis.flat_map { |d| Array(d.types_travaux_detectes) }.uniq.sort
    montant_total = devis.sum { |d| d.montant_total_htva.to_f }
    surface       = devis.filter_map(&:surface_travaux).first

    postes = tous_types.filter_map do |key|
      wt = WorkType.find(key)
      next unless wt

      petrolier     = ITEMS_PETROLIERS.include?(key)
      prix_m2_label = wt.forfait? ? "forfait #{wt.price_min}–#{wt.price_max} €" : "#{wt.price_min}–#{wt.price_max} €/#{wt.unit}"

      "- #{wt.name}: référence marché belge #{prix_m2_label}" \
        "#{petrolier ? ' | ⚠️ SENSIBLE AU PÉTROLE' : ''}"
    end

    petroliers_detectes = tous_types.select { |t| ITEMS_PETROLIERS.include?(t) }

    lines = [
      "Projet : #{@project.name.presence || 'Rénovation'}",
      "Montant total devis : #{montant_total.round(0).to_i} € HTVA",
      "Nombre de devis entrepreneur : #{devis.count}",
      ("Surface de travaux : #{surface} m²" if surface.present?),
      "",
      "Postes de travaux identifiés vs fourchettes de marché belge :",
      postes.join("\n"),
      "",
      "Postes exposés aux cours pétroliers : #{petroliers_detectes.map { |t| WorkType.find(t)&.name }.compact.join(', ').presence || 'aucun'}"
    ]

    lines.compact.join("\n")
  end

  def system_prompt
    catalogue_ref = WorkType::CATALOGUE.map do |item|
      flag = ITEMS_PETROLIERS.include?(item[:key].to_s) ? ' [PÉTROLIER]' : ''
      unit_label = item[:forfait] ? "forfait" : item[:unit]
      "#{item[:key]}: #{item[:name]} — #{item[:price_min]}–#{item[:price_max]} €/#{unit_label}#{flag}"
    end.join("\n")

    [{
      type: 'text',
      text: <<~PROMPT,
        Tu es un expert belge en optimisation budgétaire de chantiers de rénovation résidentielle.
        Tu connais les matériaux disponibles en Belgique, leurs alternatives moins chères à performance équivalente,
        et les postes dont le prix est exposé aux fluctuations des matières premières pétrolières.

        Catalogue de référence — fourchettes de marché belge 2026 :
        #{catalogue_ref}

        Analyse le projet fourni et réponds UNIQUEMENT avec un objet JSON valide :
        {
          "score_optimisation": 0-100,
          "synthese": "2-3 phrases résumant le potentiel d'économies du projet",
          "alternatives": [
            {
              "poste": "nom du poste de travaux",
              "materiau_propose": "matériau ou solution dans le devis",
              "alternative": "matériau ou solution alternative recommandée",
              "economie_estimee": "fourchette ex: 500–800 € ou 8–12%",
              "performance": "équivalente | supérieure | légèrement inférieure",
              "remarque": "disponibilité belge, éligibilité prime, ou nuance importante"
            }
          ],
          "risques_petroliers": [
            {
              "poste": "nom du poste",
              "risque": "description du risque de hausse lié au pétrole",
              "recommandation": "action concrète (clause révision prix, commander avant, etc.)"
            }
          ],
          "optimisations_lots": [
            "conseil concret de regroupement, phasage ou négociation"
          ],
          "economies_estimees": montant_total_prudent_en_euros_entier
        }

        Règles strictes :
        - score_optimisation : 100 = devis déjà très bien optimisé, 0 = fort potentiel inexploité. Sois réaliste.
        - alternatives : max 4. Uniquement si économie significative (>5%) ET matériau disponible en Belgique en 2026.
        - risques_petroliers : uniquement pour les postes marqués PÉTROLIER dans le catalogue.
        - optimisations_lots : max 3 conseils pratiques et actionnables.
        - economies_estimees : estimation conservative en euros entiers. Prudence > optimisme.
        - Réponds en français. Sois direct et concis.
      PROMPT
      cache_control: { type: 'ephemeral' }
    }]
  end

  def parse_response(raw)
    json_str = raw[/\{.*\}/m]
    return nil unless json_str
    JSON.parse(json_str)
  rescue JSON::ParserError => e
    Rails.logger.warn "BudgetOptimiseurService JSON parse: #{e.message}"
    nil
  end
end
