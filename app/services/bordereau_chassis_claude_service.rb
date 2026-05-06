# BordereauChassisClaudeService
#
# Extraction intelligente des données d'un devis ou bordereau de commande châssis
# via l'API Claude (texte). Plus fiable que les regex pour des documents à structure
# très variable (Belisol, Lemmens/WinPro, Reynaers, Velux, etc.).
#
# Stratégie :
#   1. Extraction du texte brut via OcrService (pdftotext → PDF::Reader → Tesseract)
#   2. Envoi du texte à Claude avec un prompt structuré → JSON
#   3. Fallback transparent sur BordereauChassisOcrService si Claude échoue
#
# Usage :
#   result = BordereauChassisClaudeService.new(file).extraire_donnees_bordereau
#   # Retourne le même hash que BordereauChassisOcrService

class BordereauChassisClaudeService < OcrService
  include HTTParty

  ANTHROPIC_API_URL  = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION  = '2023-06-01'
  MODEL              = 'claude-opus-4-5'
  MAX_TOKENS         = 1500
  MAX_TEXT_CHARS     = 80_000  # ~20k tokens — suffisant pour un devis 20 pages

  def extraire_donnees_bordereau
    api_key = ENV['ANTHROPIC_API_KEY']
    unless api_key.present?
      Rails.logger.warn 'BordereauChassisClaudeService: ANTHROPIC_API_KEY absent → fallback OCR'
      return fallback_ocr
    end

    # 1. Extraire le texte brut
    ocr_result = call
    unless ocr_result[:success]
      return { success: false, error: ocr_result[:error] }
    end

    texte = ocr_result[:text].to_s.strip
    if texte.length < 100
      Rails.logger.warn 'BordereauChassisClaudeService: texte trop court → fallback OCR'
      return fallback_ocr
    end

    # 2. Appel Claude
    raw_response = call_claude(texte, api_key)
    unless raw_response
      Rails.logger.warn 'BordereauChassisClaudeService: pas de réponse Claude → fallback OCR'
      return fallback_ocr
    end

    # 3. Parser le JSON retourné par Claude
    data = parse_claude_response(raw_response)
    unless data
      Rails.logger.warn 'BordereauChassisClaudeService: JSON invalide → fallback OCR'
      return fallback_ocr
    end

    # 4. Construire le hash de résultat normalisé
    build_result(data, texte)

  rescue StandardError => e
    Rails.logger.error "BordereauChassisClaudeService error: #{e.message}"
    fallback_ocr
  end

  private

  # ── Appel API Claude ──────────────────────────────────────────────────────────

  def call_claude(texte, api_key)
    # Tronquer si nécessaire (devis 20+ pages)
    texte_tronque = texte.length > MAX_TEXT_CHARS ? texte[0, MAX_TEXT_CHARS] + "\n[texte tronqué]" : texte

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
        messages:   [{
          role:    'user',
          content: "Voici le texte extrait d'un devis ou bordereau de commande châssis/fenêtres belge :\n\n#{texte_tronque}\n\nExtrait les données demandées en JSON."
        }]
      }.to_json,
      timeout: 45
    )

    if response.success?
      response.dig('content', 0, 'text')&.strip
    else
      Rails.logger.error "BordereauChassisClaudeService Claude #{response.code}: #{response.body[0..300]}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn 'BordereauChassisClaudeService: timeout Claude'
    nil
  end

  # ── Prompt système ────────────────────────────────────────────────────────────

  def system_prompt
    [{
      type: 'text',
      text: <<~PROMPT,
        Tu es un expert en menuiserie extérieure et en primes énergie belges.
        Tu analyses des devis et bordereaux de commande châssis/fenêtres et extrais les données techniques clés.

      RÈGLES IMPORTANTES :
      - Pour "valeur_uw" : retourne la valeur Uw GLOBALE/MOYENNE PONDÉRÉE du projet, pas la valeur d'un châssis individuel.
        Si le document contient un tableau récapitulatif avec une valeur Uw globale (ex : "58,61 m² → Uw = 1,20"), utilise celle-là.
        Si plusieurs valeurs Uw sont présentes par châssis mais pas de globale, calcule ou estime la valeur représentative.
        Si le document ne mentionne pas Uw du tout (ex : certains devis commerciaux), retourne null pour "valeur_uw".
      - Pour "valeur_ug" : coefficient thermique du vitrage seul (Ug). Format "4/16/4 U 1.0" → ug = 1.0
      - Pour "nom_fabricant" : nom du fabricant/marque du système châssis (ex : Belisol, Kömmerling, Reynaers, Veka…).
        Si le document est un devis d'un revendeur qui vend ses propres produits (ex : BELISOL, LEMMENS), retourne le nom du revendeur
        comme fabricant si aucune marque système n'est mentionnée, sinon retourne la marque système (ex : Kömmerling).
      - Pour "nom_poseur" : entreprise qui pose les châssis (si différente du fabricant). Souvent l'émetteur du devis.
      - Pour "type_chassis" : "pvc", "aluminium", "bois", ou "mixte"
      - Pour "type_vitrage" : "double", "triple", "hr_plus_plus" (HR++), "hr_plus" (HR+), ou "monolithique"
      - Pour "montant_htva" et "montant_tvac" : montants TOTAUX du devis (pas par châssis individuel)
      - Pour "taux_tva" : taux TVA en % (6 ou 21 généralement en Belgique)
      - Pour "surface_totale" : surface totale vitrée/châssis en m². Si présente dans un tableau récapitulatif, utilise-la.
      - Pour "nombre_unites" : nombre total de châssis/fenêtres/portes
      - Pour "date_document" : date du devis au format "DD/MM/YYYY"
      - Pour "numero_document" : numéro de référence du devis

      Réponds UNIQUEMENT avec un objet JSON valide (pas de markdown, pas d'explication) :
      {
        "nom_fabricant": "string ou null",
        "nom_poseur": "string ou null",
        "numero_bce_poseur": "BEXXXXXXXXX ou null",
        "reference_produit": "string ou null",
        "valeur_uw": nombre ou null,
        "valeur_ug": nombre ou null,
        "valeur_uf": nombre ou null,
        "facteur_solaire": nombre ou null,
        "type_chassis": "pvc|aluminium|bois|mixte ou null",
        "type_vitrage": "double|triple|hr_plus_plus|hr_plus|monolithique ou null",
        "surface_totale": nombre ou null,
        "nombre_unites": entier ou null,
        "date_document": "DD/MM/YYYY ou null",
        "numero_document": "string ou null",
        "montant_htva": nombre ou null,
        "montant_tvac": nombre ou null,
        "taux_tva": nombre ou null,
        "confiance": entier 0-100
      }
    PROMPT
      cache_control: { type: 'ephemeral' }
    }]  end

  # ── Parsing réponse Claude ───────────────────────────────────────────────────

  def parse_claude_response(raw)
    # Extraire le JSON même si Claude ajoute du texte autour
    json_str = raw[/\{[^{}]*(?:\{[^{}]*\}[^{}]*)?\}/m] || raw[/\{.*\}/m]
    return nil unless json_str

    JSON.parse(json_str)
  rescue JSON::ParserError => e
    Rails.logger.warn "BordereauChassisClaudeService JSON parse: #{e.message}"
    nil
  end

  # ── Construction du hash de résultat normalisé ────────────────────────────────

  def build_result(data, texte)
    uw     = parse_float(data['valeur_uw'])
    ug     = parse_float(data['valeur_ug'])
    uf     = parse_float(data['valeur_uf'])
    g      = parse_float(data['facteur_solaire'])
    htva   = parse_float(data['montant_htva'])
    tvac   = parse_float(data['montant_tvac'])
    tva    = parse_float(data['taux_tva'])
    surf   = parse_float(data['surface_totale'])
    units  = data['nombre_unites'].to_i.nonzero?
    date   = parse_date(data['date_document'])
    conf   = [[data['confiance'].to_i, 0].max, 100].min

    # Si Claude a moins de 40% de confiance → fallback
    if conf < 40
      Rails.logger.warn "BordereauChassisClaudeService: confiance #{conf}% trop basse → fallback OCR"
      return fallback_ocr
    end

    {
      success:              true,
      texte_brut:           texte,
      nom_fabricant:        data['nom_fabricant']&.strip.presence,
      nom_poseur:           data['nom_poseur']&.strip.presence,
      numero_bce_poseur:    data['numero_bce_poseur']&.strip.presence,
      reference_produit:    data['reference_produit']&.strip.presence,
      valeur_uw:            uw,
      valeur_ug:            ug,
      valeur_uf:            uf,
      facteur_solaire:      g,
      type_vitrage:         data['type_vitrage'].presence,
      type_chassis:         data['type_chassis'].presence,
      surface_totale:       surf,
      nombre_unites:        units,
      date_document:        date,
      numero_document:      data['numero_document']&.strip.presence,
      montant_htva:         htva,
      montant_tvac:         tvac,
      taux_tva:             tva,
      detail_chassis:       [],  # Non extrait en mode Claude (coût/complexité)
      confiance_extraction: conf.to_f,
      extraction_complete:  (uw || ug).present? && htva.present?,
      source:               'claude',
      donnees_bordereau: {
        uw: uw, ug: ug, uf: uf, g_value: g,
        fabricant: data['nom_fabricant']&.strip.presence,
        type_vitrage: data['type_vitrage'].presence,
        type_chassis: data['type_chassis'].presence
      }
    }
  end

  # ── Fallback OCR regex ────────────────────────────────────────────────────────

  def fallback_ocr
    Rails.logger.info 'BordereauChassisClaudeService: using regex OCR fallback'
    result = BordereauChassisOcrService.new(@file).extraire_donnees_bordereau
    result.merge(source: 'ocr_fallback') if result[:success]
    result
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  def parse_float(val)
    return nil if val.nil? || val == 'null'
    val.is_a?(Numeric) ? val.to_f.nonzero? : val.to_s.tr(',', '.').to_f.nonzero?
  rescue
    nil
  end

  def parse_date(str)
    return nil unless str.present?
    Date.strptime(str, '%d/%m/%Y')
  rescue ArgumentError, TypeError
    nil
  end
end
