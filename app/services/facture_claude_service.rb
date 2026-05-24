# FactureClaudeService
#
# Extraction intelligente des données d'une facture, acompte, état d'avancement
# ou solde via l'API Claude (texte).
#
# Couvre tous les types de documents financiers liés à un chantier belge :
#   - facture       : facture standard de travaux
#   - acompte       : facture d'acompte / avance sur travaux
#   - solde         : facture de solde / dernière facture
#   - etat_avancement : situation de travaux périodique
#   - devis         : devis (détection au cas où le document serait mal catégorisé)
#
# Stratégie :
#   1. Extraction texte via OcrService (pdftotext → PDF::Reader → Tesseract)
#   2. Envoi à Claude avec prompt métier → JSON structuré
#   3. Fallback transparent sur FactureOcrService si Claude échoue ou confiance < 40%
#
# Retourne le même hash que FactureOcrService#extraire_donnees_facture.

class FactureClaudeService < OcrService
  include HTTParty

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-opus-4-5'
  MAX_TOKENS        = 1500
  MAX_TEXT_CHARS    = 80_000

  TYPES_FACTURE_VALIDES      = %w[facture acompte solde etat_avancement devis].freeze
  TYPES_INTERVENANT_VALIDES  = %w[architecte entrepreneur autre].freeze

  def initialize(file, language: 'fra+nld')
    super(file, language: language)
  end

  def extraire_donnees_facture
    api_key = ENV['ANTHROPIC_API_KEY']
    unless api_key.present?
      Rails.logger.warn 'FactureClaudeService: ANTHROPIC_API_KEY absent → fallback OCR'
      return fallback_ocr
    end

    ocr_result = call
    unless ocr_result[:success]
      return { success: false, error: ocr_result[:error] }
    end

    texte = ocr_result[:text].to_s.strip
    if texte.length < 80
      Rails.logger.warn 'FactureClaudeService: texte trop court → fallback OCR'
      return fallback_ocr
    end

    raw_response = call_claude(texte, api_key)
    unless raw_response
      Rails.logger.warn 'FactureClaudeService: pas de réponse Claude → fallback OCR'
      return fallback_ocr
    end

    data = parse_claude_response(raw_response)
    unless data
      Rails.logger.warn 'FactureClaudeService: JSON invalide → fallback OCR'
      return fallback_ocr
    end

    build_result(data, texte, ocr_result)

  rescue StandardError => e
    Rails.logger.error "FactureClaudeService error: #{e.message}"
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
          content: "Texte extrait du document :\n\n#{texte_tronque}\n\nExtrait les données en JSON."
        }]
      }.to_json,
      timeout: 45
    )

    if response.success?
      response.dig('content', 0, 'text')&.strip
    else
      Rails.logger.error "FactureClaudeService Claude #{response.code}: #{response.body[0..300]}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn 'FactureClaudeService: timeout Claude'
    nil
  end

  # ── Prompt système ────────────────────────────────────────────────────────────

  def system_prompt
    [{
      type: 'text',
      text: <<~PROMPT,
        Tu es un expert en facturation de chantiers de rénovation résidentielle en Belgique.
        Tu analyses des factures, acomptes, états d'avancement et soldes émis par des entrepreneurs et architectes.

        RÈGLES D'EXTRACTION :

        Pour "montant_tvac" : montant TOTAL TVA comprise (à payer).
          - "TVAC", "TTC", "Total incl. TVA", "Net à payer", "Montant dû" sont équivalents.
          - C'est le montant final que le client doit payer.
          - Si plusieurs montants partiels : prendre le TOTAL final.

        Pour "montant_htva" : montant hors TVA.
          - "HTVA", "HT", "excl. TVA", "Sous-total HT" sont équivalents.
          - Si absent mais taux TVA connu : déduis-le depuis le TVAC.

        Pour "montant_tva" : montant de la TVA seule (pas le taux, mais la valeur en €).

        Pour "taux_tva" : taux en % (6 pour rénovations résidentielles, 21 pour neuf ou honoraires architecte).
          - Si plusieurs taux présents, retourne le taux dominant.

        Pour "date_facture" : date d'émission de la facture au format "DD/MM/YYYY".

        Pour "numero_facture" : référence unique du document.
          - Cherche "Facture N°", "N°", "Ref", "Invoice no"…
          - Si absent, retourne null.

        Pour "nom_entreprise" : nom de la société ou de l'artisan ÉMETTEUR (celui qui envoie la facture).
          - Ne pas confondre avec le nom du client destinataire.
          - Pour un architecte : nom du cabinet ou de l'architecte.

        Pour "numero_bce" : numéro BCE belge de l'émetteur.
          - Format attendu en sortie : "BExxxxxxxxxx" (10 chiffres après BE).
          - Cherche "BCE", "TVA BE", "BTW BE", "N° entreprise"…
          - Exemples : "BE 0451.232.320" → "BE0451232320"

        Pour "adresse_entreprise" : adresse postale complète de l'émetteur. Null si absent.

        Pour "telephone_entreprise" : numéro de téléphone de l'émetteur. Null si absent.

        Pour "email_entreprise" : adresse email de l'émetteur. Null si absent.

        Pour "type_document" : nature du document.
          Valeurs autorisées : facture, acompte, solde, etat_avancement, devis
          - "acompte", "avance", "advance", "deposit" → "acompte"
          - "solde", "final", "finale", "balance", "reliquat" → "solde"
          - "état d'avancement", "situation de travaux", "décompte" → "etat_avancement"
          - "devis", "offre", "estimation" → "devis"
          - Sinon → "facture" (par défaut)

        Pour "type_intervenant" : qui a émis le document.
          Valeurs autorisées : architecte, entrepreneur, autre
          - "architecte", "cabinet d'architecture", "ordre des architectes" → "architecte"
          - "entrepreneur", "entreprise de construction", artisan… → "entrepreneur"
          - Sinon → "entrepreneur" (par défaut)

        Pour "confiance" : ton niveau de confiance global (0-100) dans l'extraction.
          - 90+ : tous les champs principaux extraits avec certitude
          - 70-89 : montant et date extraits, quelques champs manquants
          - 40-69 : extraction partielle, montant ou date manquant
          - < 40 : document illisible ou hors scope

        Réponds UNIQUEMENT avec un objet JSON valide (aucun markdown, aucune explication) :
        {
          "montant_tvac": nombre ou null,
          "montant_htva": nombre ou null,
          "montant_tva": nombre ou null,
          "taux_tva": nombre ou null,
          "date_facture": "DD/MM/YYYY ou null",
          "numero_facture": "string ou null",
          "nom_entreprise": "string ou null",
          "numero_bce": "BExxxxxxxxxx ou null",
          "adresse_entreprise": "string ou null",
          "telephone_entreprise": "string ou null",
          "email_entreprise": "string ou null",
          "type_document": "facture|acompte|solde|etat_avancement|devis",
          "type_intervenant": "architecte|entrepreneur|autre",
          "confiance": entier 0-100
        }
      PROMPT
      cache_control: { type: 'ephemeral' }
    }]
  end

  # ── Parsing réponse Claude ────────────────────────────────────────────────────

  def parse_claude_response(raw)
    json_str = raw[/\{[^{}]*(?:\{[^{}]*\}[^{}]*)?\}/m] || raw[/\{.*\}/m]
    return nil unless json_str

    JSON.parse(json_str)
  rescue JSON::ParserError => e
    Rails.logger.warn "FactureClaudeService JSON parse: #{e.message}"
    nil
  end

  # ── Construction du hash de résultat normalisé ────────────────────────────────

  def build_result(data, texte, ocr_result)
    conf = [[data['confiance'].to_i, 0].max, 100].min

    if conf < 40
      Rails.logger.warn "FactureClaudeService: confiance #{conf}% → fallback OCR"
      return fallback_ocr
    end

    montant_tvac = parse_float(data['montant_tvac'])
    montant_htva = parse_float(data['montant_htva'])
    montant_tva  = parse_float(data['montant_tva'])
    taux_tva     = parse_float(data['taux_tva'])
    date_f       = parse_date(data['date_facture'])

    type_facture     = filter_value(data['type_document'],     TYPES_FACTURE_VALIDES,     'facture')
    type_intervenant = filter_value(data['type_intervenant'],  TYPES_INTERVENANT_VALIDES, 'entrepreneur')

    donnees = {
      montant:               montant_tvac,
      date_facture:          date_f,
      numero_facture:        data['numero_facture']&.strip.presence,
      nom_entreprise:        data['nom_entreprise']&.strip.presence,
      numero_bce:            normaliser_bce(data['numero_bce']),
      adresse_entreprise:    data['adresse_entreprise']&.strip.presence,
      telephone_entreprise:  data['telephone_entreprise']&.strip.presence,
      email_entreprise:      data['email_entreprise']&.strip.presence,
      montant_ht:            montant_htva,
      montant_tva:           montant_tva,
      taux_tva:              taux_tva,
      type_facture:          type_facture,
      type_intervenant:      type_intervenant
    }

    extraction_complete = donnees[:montant].present? &&
                          (donnees[:date_facture].present? || donnees[:numero_facture].present?) &&
                          donnees[:type_facture].present?

    ocr_result.merge(
      success:              true,
      donnees_facture:      donnees,
      confiance_extraction: conf.to_f,
      extraction_complete:  extraction_complete,
      texte_brut:           texte,
      source:               'claude'
    )
  end

  # ── Fallback OCR regex ────────────────────────────────────────────────────────

  def fallback_ocr
    Rails.logger.info 'FactureClaudeService: using FactureOcrService fallback'
    result = FactureOcrService.new(@file, language: @language).extraire_donnees_facture
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
    chiffres = str.gsub(/[^0-9]/, '')
    return nil unless chiffres.length == 10
    "BE#{chiffres}"
  end

  def filter_value(val, allowed, default)
    v = val.to_s.strip
    allowed.include?(v) ? v : default
  end
end
