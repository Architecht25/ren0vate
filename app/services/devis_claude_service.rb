# DevisClaudeService
#
# Extraction intelligente des données d'un devis entrepreneur/métré ou
# contrat/devis architecte via l'API Claude (texte).
#
# Couvre les deux catégories exposées par OcrController#scan_devis :
#   - 'entrepreneur' : devis métré, bordereau de prix, offre de prix
#   - 'architecte'   : contrat d'architecte, convention honoraires, offre de services
#
# Stratégie :
#   1. Extraction texte via OcrService (pdftotext → PDF::Reader → Tesseract)
#   2. Envoi à Claude avec prompt adapté à la catégorie → JSON structuré
#   3. Fallback transparent sur DevisOcrService si Claude échoue ou confiance < 40%
#
# Retourne le même hash que DevisOcrService#extraire_donnees_devis.

class DevisClaudeService < OcrService
  include HTTParty

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-opus-4-5'
  MAX_TOKENS        = 1500
  MAX_TEXT_CHARS    = 80_000

  # Liste des types de travaux reconnus (à synchroniser avec DevisOcrService::MOTS_CLES_TRAVAUX)
  TYPES_TRAVAUX_VALIDES = %w[
    isolation_toit isolation_facade isolation_sol isolation_murs
    chassis_vitrage chauffage sanitaire electricite gaz
    maconnerie carrelage_revetement plafonnage_peinture toiture
    pompe_chaleur ventilation eclairage photovoltaique
    chauffe_eau_thermodynamique audit_energetique renovation_generale
  ].freeze

  def initialize(file, categorie: 'entrepreneur', language: 'fra+nld')
    super(file, language: language)
    @categorie = categorie
  end

  def extraire_donnees_devis
    api_key = ENV['ANTHROPIC_API_KEY']
    unless api_key.present?
      Rails.logger.warn 'DevisClaudeService: ANTHROPIC_API_KEY absent → fallback OCR'
      return fallback_ocr
    end

    ocr_result = call
    unless ocr_result[:success]
      return { success: false, error: ocr_result[:error] }
    end

    texte = ocr_result[:text].to_s.strip
    if texte.length < 80
      Rails.logger.warn 'DevisClaudeService: texte trop court → fallback OCR'
      return fallback_ocr
    end

    raw_response = call_claude(texte, api_key)
    unless raw_response
      Rails.logger.warn 'DevisClaudeService: pas de réponse Claude → fallback OCR'
      return fallback_ocr
    end

    data = parse_claude_response(raw_response)
    unless data
      Rails.logger.warn 'DevisClaudeService: JSON invalide → fallback OCR'
      return fallback_ocr
    end

    build_result(data, texte, ocr_result)

  rescue StandardError => e
    Rails.logger.error "DevisClaudeService error: #{e.message}"
    fallback_ocr
  end

  private

  # ── Appel API Claude ──────────────────────────────────────────────────────────

  def call_claude(texte, api_key)
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
          content: "Catégorie déclarée : #{@categorie}\n\nTexte extrait du document :\n\n#{texte_tronque}\n\nExtrait les données en JSON."
        }]
      }.to_json,
      timeout: 45
    )

    if response.success?
      response.dig('content', 0, 'text')&.strip
    else
      Rails.logger.error "DevisClaudeService Claude #{response.code}: #{response.body[0..300]}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn 'DevisClaudeService: timeout Claude'
    nil
  end

  # ── Prompt système ────────────────────────────────────────────────────────────

  def system_prompt
    types_liste = TYPES_TRAVAUX_VALIDES.join(', ')

    [{
      type: 'text',
      text: <<~PROMPT,
        Tu es un expert en marchés de travaux de rénovation résidentielle en Belgique.
        Tu analyses des devis d'entrepreneurs, métrés de travaux et contrats/devis d'architectes.

      RÈGLES D'EXTRACTION :

      Pour "nom_entreprise" :
      - Entrepreneur : nom de la société ou de l'artisan qui réalise les travaux (émetteur du devis).
      - Architecte : nom du cabinet ou de l'architecte indépendant.
      - Si le document est adressé à un client mais émis par une société, retourne le nom de l'émetteur.

      Pour "numero_bce_entreprise" : numéro BCE belge de l'émetteur (format BExxxxxxxxxx).
        Exemples valides : BE0451.232.320, TVA-BE-0426.778.125 → retourne "BE0426778125"

      Pour "montant_total_htva" : montant TOTAL hors TVA de l'offre/devis.
        - En Belgique, "HTVA" = hors TVA, "excl. TVA" = idem.
        - Pour un devis architecte, c'est souvent les honoraires HT.
        - Si seul le TVAC est présent et le taux TVA connu, déduis le HTVA.

      Pour "montant_total_tvac" : montant total TVA comprise.
        - "TVAC", "TTC", "incl. TVA", "Total incl. TVA" sont équivalents.

      Pour "taux_tva" : taux en % (6 pour les rénovations résidentielles, 21 pour neuf ou prestations intellectuelles architecte).

      Pour "date_devis" : date d'émission du document au format "DD/MM/YYYY".

      Pour "numero_devis" : référence unique du document (ex : LD 260111, BRUX72491TG, 2026-045…).

      Pour "validite_devis" : date limite de validité de l'offre, format "DD/MM/YYYY". Peut être exprimée en durée (ex "valable 1 mois") → calcule la date limite si la date d'émission est connue. Sinon null.

      Pour "types_travaux_detectes" : tableau des types de travaux présents dans le document.
        Valeurs autorisées (utilise UNIQUEMENT ces valeurs) : #{types_liste}
        Sois conservateur : ne cite que les types clairement mentionnés.

      Pour "surface_travaux" : surface en m² mentionnée dans le devis (superficie totale des travaux). Null si non mentionné.

      Pour "categorie_devis" : "architecte" si le document est un contrat/devis d'architecte ou une convention d'honoraires ; "entrepreneur" dans tous les autres cas.

      Réponds UNIQUEMENT avec un objet JSON valide (aucun markdown, aucune explication) :
      {
        "nom_entreprise": "string ou null",
        "numero_bce_entreprise": "BExxxxxxxxxx ou null",
        "numero_tva_entreprise": "BExxxxxxxxxx ou null",
        "montant_total_htva": nombre ou null,
        "montant_total_tvac": nombre ou null,
        "taux_tva": nombre ou null,
        "date_devis": "DD/MM/YYYY ou null",
        "numero_devis": "string ou null",
        "validite_devis": "DD/MM/YYYY ou null",
        "types_travaux_detectes": ["type1", "type2"],
        "surface_travaux": nombre ou null,
        "categorie_devis": "entrepreneur|architecte",
        "confiance": entier 0-100
      }
    PROMPT
      cache_control: { type: 'ephemeral' }
    }]
  end

  # ── Parsing réponse Claude ───────────────────────────────────────────────────

  def parse_claude_response(raw)
    json_str = raw[/\{[^{}]*(?:\{[^{}]*\}[^{}]*)?\}/m] || raw[/\{.*\}/m]
    return nil unless json_str

    JSON.parse(json_str)
  rescue JSON::ParserError => e
    Rails.logger.warn "DevisClaudeService JSON parse: #{e.message}"
    nil
  end

  # ── Construction du hash de résultat normalisé ────────────────────────────────

  def build_result(data, texte, ocr_result)
    conf = [[data['confiance'].to_i, 0].max, 100].min

    if conf < 40
      Rails.logger.warn "DevisClaudeService: confiance #{conf}% → fallback OCR"
      return fallback_ocr
    end

    htva       = parse_float(data['montant_total_htva'])
    tvac       = parse_float(data['montant_total_tvac'])
    tva        = parse_float(data['taux_tva'])
    surface    = parse_float(data['surface_travaux'])
    date_d     = parse_date(data['date_devis'])
    validite   = parse_date(data['validite_devis'])
    types      = filter_types_travaux(data['types_travaux_detectes'])

    extraction_complete = htva.present? && data['nom_entreprise'].present? && date_d.present?

    donnees = {
      nom_entreprise:        data['nom_entreprise']&.strip.presence,
      numero_bce_entreprise: normaliser_bce(data['numero_bce_entreprise']),
      numero_tva_entreprise: normaliser_bce(data['numero_tva_entreprise']),
      montant_total_htva:    htva,
      montant_total_tvac:    tvac,
      taux_tva:              tva,
      date_devis:            date_d,
      numero_devis:          data['numero_devis']&.strip.presence,
      validite_devis:        validite,
      types_travaux_detectes: types,
      surface_travaux:       surface
    }

    ocr_result.merge(
      success:                true,
      donnees_devis:          donnees,
      nom_entreprise:         donnees[:nom_entreprise],
      numero_bce_entreprise:  donnees[:numero_bce_entreprise],
      numero_tva_entreprise:  donnees[:numero_tva_entreprise],
      montant_total_htva:     htva,
      montant_total_tvac:     tvac,
      taux_tva:               tva,
      date_devis:             date_d,
      numero_devis:           donnees[:numero_devis],
      validite_devis:         validite,
      types_travaux_detectes: types,
      surface_travaux:        surface,
      confiance_extraction:   conf.to_f,
      extraction_complete:    extraction_complete,
      texte_brut:             texte,
      source:                 'claude'
    )
  end

  # ── Fallback OCR regex ────────────────────────────────────────────────────────

  def fallback_ocr
    Rails.logger.info 'DevisClaudeService: using DevisOcrService fallback'
    result = DevisOcrService.new(@file, language: @language).extraire_donnees_devis
    result[:source] = 'ocr_fallback' if result[:success]
    result
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  def parse_float(val)
    return nil if val.nil? || val.to_s == 'null'
    val.is_a?(Numeric) ? val.to_f.nonzero? : val.to_s.tr(',', '.').to_f.nonzero?
  rescue
    nil
  end

  def parse_date(str)
    return nil unless str.present? && str != 'null'
    Date.strptime(str, '%d/%m/%Y')
  rescue ArgumentError, TypeError
    nil
  end

  def normaliser_bce(str)
    return nil unless str.present? && str != 'null'
    # Normaliser en BExxxxxxxxxx (10 chiffres)
    chiffres = str.gsub(/[^0-9]/, '')
    return nil unless chiffres.length == 10
    "BE#{chiffres}"
  end

  def filter_types_travaux(arr)
    return [] unless arr.is_a?(Array)
    arr.map(&:to_s).select { |t| TYPES_TRAVAUX_VALIDES.include?(t) }.uniq
  end
end
