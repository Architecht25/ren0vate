# Service de comparaison produits & matériaux
# Calculs personnalisés selon le projet + recommandation IA
#
# Usage :
#   service = ProductComparatorService.new(project: @project)
#   result  = service.compare(category: 'insulation', subcategory: 'toiture')

class ProductComparatorService
  include HTTParty

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-haiku-4-5-20251001'

  # Primes moyennes par catégorie (Wallonie) pour le calcul ROI affiché
  GRANT_ESTIMATES = {
    'insulation' => { rate: 0.60, max: 5_000 },  # 60% plafonné
    'windows'    => { rate: 0.50, max: 3_500 },
    'heating'    => { rate: 0.40, max: 8_000 },
    'solar'      => { rate: 0.30, max: 4_000 },
    'hot_water'  => { rate: 0.40, max: 2_000 }
  }.freeze

  def initialize(project: nil, property: nil, priorities: %w[performance ecology price])
    @project    = project
    @property   = property || project&.property
    @priorities = priorities
    @api_key    = ENV['ANTHROPIC_API_KEY']
  end

  # Compare tous les produits d'une catégorie + sous-catégorie
  # skip_ai: true = retour instantané sans appel Claude (reco chargée séparément)
  def compare(category:, subcategory: nil, skip_ai: false)
    products = Product.active.by_category(category)
    products = products.by_subcategory(subcategory) if subcategory.present?
    products = products.ordered

    return { products: [], recommendation: nil, context: {} } if products.empty?

    context = build_context(category)
    enriched = products.map { |p| enrich_product(p, context) }
    enriched.sort_by! { |e| -e[:global_score] }

    recommendation = skip_ai ? nil : generate_recommendation(enriched, context, category)

    {
      products:       enriched,
      recommendation: recommendation,
      context:        context,
      category:       category,
      subcategory:    subcategory
    }
  end

  # Liste les catégories disponibles avec nombre de produits
  def available_categories
    Product.active
           .group(:category)
           .count
           .map do |cat, count|
      {
        key:   cat,
        label: Product::CATEGORIES[cat],
        count: count
      }
    end
  end

  private

  # ─── Contexte du projet ──────────────────────────────────────────────────

  def build_context(category)
    surface = project_surface(category)
    region  = @property&.region&.downcase || 'wallonie'
    year    = @property&.annee_construction&.to_i || 1975

    {
      surface:        surface,
      region:         region,
      property_year:  year,
      energy_cost:    energy_cost_per_kwh(region),
      current_r:      current_r_value(category),
      grant_rate:     GRANT_ESTIMATES.dig(category, :rate) || 0.5,
      grant_max:      GRANT_ESTIMATES.dig(category, :max)  || 3_000,
      project_name:   @project&.name || 'votre projet'
    }
  end

  def project_surface(category)
    return 120.0 unless @project  # valeur par défaut

    case category
    when 'insulation'
      @property&.surface_habitable&.to_f&.*(0.8) || 100.0
    when 'windows'
      nil  # unité = fenêtre, pas m²
    else
      nil
    end
  end

  def energy_cost_per_kwh(region)
    # Tarif moyen Belgique 2026
    0.28
  end

  def current_r_value(category)
    return 0.5 if category != 'insulation'

    year = @property&.annee_construction&.to_i || 1975
    case year
    when ..1970 then 0.3   # Pratiquement pas isolé
    when 1971..1990 then 1.0
    when 1991..2005 then 2.0
    else 3.0
    end
  end

  # ─── Enrichissement produit ───────────────────────────────────────────────

  def enrich_product(product, context)
    surface = context[:surface]
    region  = context[:region]

    # Prix total projet
    total_price = if surface && product.price_unit == 'm2'
                    product.price_for_surface(surface)
                  else
                    product.price_per_unit&.to_i
                  end

    # Prime estimée
    grant = estimate_grant(total_price, product, region, context)

    # Coût net après prime
    net_cost = total_price ? [total_price - grant, 0].max : nil

    # Économie annuelle (isolants uniquement)
    annual_saving = product.annual_saving_euros(
      surface_m2:       surface || 100,
      current_r_value:  context[:current_r],
      energy_cost_per_kwh: context[:energy_cost]
    )

    # ROI
    roi = product.roi_years(
      surface_m2:      surface || 100,
      current_r_value: context[:current_r],
      grant_amount:    grant
    )

    # Savings sur 20 ans
    savings_20y = annual_saving ? annual_saving * 20 : nil

    # Score global
    score = product.weighted_score(priorities: @priorities)

    # R-value à 16cm (isolants)
    r16 = product.category == 'insulation' ? product.r_value_at(16) : nil

    {
      product:        product,
      total_price:    total_price,
      grant_estimate: grant,
      net_cost:       net_cost,
      annual_saving:  annual_saving,
      savings_20y:    savings_20y,
      roi_years:      roi,
      global_score:   score,
      r_value_16cm:   r16,
      grant_eligible: product.grant_eligible_for?(region)
    }
  end

  def estimate_grant(total_price, product, region, context)
    return 0 unless total_price&.positive?
    return 0 unless product.grant_eligible_for?(region)

    raw = (total_price * context[:grant_rate]).round(0)
    [raw, context[:grant_max]].min
  end

  # ─── Recommandation IA ────────────────────────────────────────────────────

  def generate_recommendation(enriched_products, context, category)
    return nil unless @api_key.present?
    return nil if enriched_products.empty?

    top3 = enriched_products.first(3).map do |e|
      p = e[:product]
      {
        nom:          p.name,
        marque:       p.brand,
        prix_total:   e[:total_price],
        prime:        e[:grant_estimate],
        cout_net:     e[:net_cost],
        economie_an:  e[:annual_saving],
        roi_ans:      e[:roi_years],
        score:        e[:global_score],
        biosource:    p.biosourced?,
        recyclable:   p.recyclable?,
        lambda:       p.technical_specs['lambda'],
        r_16cm:       e[:r_value_16cm]
      }
    end

    prompt = build_prompt(top3, context, category)
    call_claude(prompt)
  rescue => e
    Rails.logger.error "ProductComparatorService#generate_recommendation: #{e.message}"
    nil
  end

  def build_prompt(top3, context, category)
    cat_label = Product::CATEGORIES[category] || category
    surface_txt = context[:surface] ? "#{context[:surface].to_i}m²" : "non précisée"

    <<~PROMPT
      Tu es expert en rénovation énergétique belge. En 3-4 phrases maximum,
      recommande le meilleur choix parmi ces #{cat_label.downcase} pour ce projet.

      PROJET:
      - Surface: #{surface_txt}
      - Région: #{context[:region].capitalize}
      - Maison #{context[:property_year]}
      - Priorités: #{@priorities.join(', ')}

      TOP 3 OPTIONS (classées par score):
      #{top3.to_json}

      CONSIGNES:
      - Recommande clairement la 1ère option et explique pourquoi en langage simple
      - Mentionne l'économie concrète (€/an ou économie prime)
      - Signale si option biosourcée est pertinente selon priorités
      - Maximum 80 mots, ton direct et rassurant
      - Réponse en français uniquement
    PROMPT
  end

  def call_claude(prompt)
    response = self.class.post(
      ANTHROPIC_API_URL,
      headers: {
        'Content-Type'    => 'application/json',
        'x-api-key'       => @api_key,
        'anthropic-version' => ANTHROPIC_VERSION
      },
      body: {
        model:      MODEL,
        max_tokens: 200,
        messages:   [{ role: 'user', content: prompt }]
      }.to_json,
      timeout: 15
    )

    return nil unless response.code == 200

    data = JSON.parse(response.body)
    data.dig('content', 0, 'text')&.strip
  rescue
    nil
  end
end
