class DevisAvancementService
  # Analyse le texte d'un devis (OCR brut ou tapé) et propose une architecture
  # d'état d'avancement structurée en thématiques + sous-secteurs + postes.
  #
  # Usage :
  #   result = DevisAvancementService.new(texte: texte_brut, project: project).call
  #   result[:success]      #=> true
  #   result[:thematiques]  #=> [{ code:, label:, sous_secteur:, lignes: [...] }]
  #   result[:resume]       #=> "Synthèse textuelle…"

  include HTTParty

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-sonnet-4-5-20250929'
  MAX_TOKENS        = 4096

  # ── 15 thématiques canoniques de la rénovation belge ─────────────────────────
  THEMATIQUES = [
    { code: 'demolition',        label: 'Démolition & Dépose' },
    { code: 'gros_oeuvre',       label: 'Gros Œuvre & Structure' },
    { code: 'toiture',           label: 'Toiture & Charpente' },
    { code: 'facades',           label: 'Façades & Isolation Extérieure' },
    { code: 'menuiseries_ext',   label: 'Menuiseries Extérieures' },
    { code: 'isolation',         label: 'Isolation Intérieure' },
    { code: 'cloisons_pla',      label: 'Cloisons & Plâtrerie' },
    { code: 'electricite',       label: 'Électricité' },
    { code: 'chauffage_vmc',     label: 'Chauffage, PAC & Ventilation' },
    { code: 'plomberie',         label: 'Plomberie & Sanitaires' },
    { code: 'energies_renouv',   label: 'Énergies Renouvelables' },
    { code: 'revetements_sol',   label: 'Carrelage & Revêtements de Sol' },
    { code: 'peinture_finitions',label: 'Peinture & Finitions' },
    { code: 'menuiseries_int',   label: 'Menuiseries Intérieures' },
    { code: 'abords_divers',     label: 'Abords, Terrasse & Divers' }
  ].freeze

  def initialize(texte:, project: nil, devis_donnee: nil)
    @texte        = texte.to_s.strip
    @project      = project
    @devis_donnee = devis_donnee
    @api_key      = ENV['ANTHROPIC_API_KEY']
  end

  def call
    return error_result('Clé API Anthropic manquante') unless @api_key.present?
    return error_result('Texte du devis vide') if @texte.blank?

    raw = call_claude
    return error_result('Pas de réponse de Claude') unless raw

    parsed = parse_response(raw)
    parsed.merge(success: true)
  rescue => e
    Rails.logger.error "DevisAvancementService error: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    error_result("Erreur d'analyse : #{e.message}")
  end

  private

  # ── Appel Claude ────────────────────────────────────────────────────────────
  def call_claude
    response = HTTParty.post(
      ANTHROPIC_API_URL,
      headers: {
        'x-api-key'         => @api_key,
        'anthropic-version' => ANTHROPIC_VERSION,
        'anthropic-beta'    => 'prompt-caching-2024-07-31',
        'content-type'      => 'application/json'
      },
      body: {
        model:      MODEL,
        max_tokens: MAX_TOKENS,
        system:     system_prompt,
        messages:   [{ role: 'user', content: user_prompt }]
      }.to_json,
      timeout: 90
    )

    if response.success?
      response.dig('content', 0, 'text')&.strip
    else
      Rails.logger.error "DevisAvancementService Claude #{response.code}: #{response.body[0..300]}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn 'DevisAvancementService: timeout Claude'
    nil
  end

  # ── Prompt système ───────────────────────────────────────────────────────────
  def system_prompt
    thematiques_list = THEMATIQUES.map { |t| "  - #{t[:code]} : #{t[:label]}" }.join("\n")

    [{
      type: 'text',
      text: <<~PROMPT,
        Tu es un expert en gestion de chantier et en états d'avancement (bordereaux de paiement)
        pour la construction et la rénovation résidentielle en Belgique.

      Ton rôle est d'analyser le texte brut d'un devis d'entrepreneur ou d'un métré d'architecte
      et de proposer une architecture structurée d'état d'avancement.

      Tu dois classifier chaque poste du devis dans l'une des 15 thématiques canoniques suivantes :
#{thematiques_list}

      Pour chaque poste détecté, tu dois extraire ou estimer :
      - La thématique (code exact de la liste ci-dessus)
      - Le sous-secteur précis (ex: "charpente bois", "couverture ardoises", "VMC double flux")
      - La désignation exacte du poste tel qu'il apparaît dans le devis
      - La référence du poste si présente (ex: "1.2", "A3")
      - La quantité et l'unité si présentes
      - Le prix unitaire HTVA si présent
      - Le montant total HTVA du poste
      - Ton niveau de confiance pour ce poste : "haute" (extrait clairement), "moyenne" (interprété),
        "faible" (estimé ou peu clair)

      Règles importantes :
      1. Ne crée PAS de poste fictif si il n'y a rien dans le devis pour cette thématique.
      2. Si un montant est présent en TVAC uniquement, indique-le en TVAC et précise-le.
      3. Préserve les désignations originales du devis, ne les reformule pas.
      4. Si le devis est en néerlandais, traduis les désignations en français.
      5. Fournis toujours un résumé en 2-3 phrases sur la nature et l'envergure du chantier.

      Réponds UNIQUEMENT avec un JSON valide respectant exactement ce schéma :
      {
        "resume": "<2-3 phrases résumant le chantier>",
        "montant_total_htva": <nombre ou null>,
        "thematiques": [
          {
            "code": "<code_thematique>",
            "label": "<label_thematique>",
            "poids_estime_pct": <0-100 représentant le poids financier estimé>,
            "sous_secteurs": ["<sous_secteur_1>", "<sous_secteur_2>"],
            "lignes": [
              {
                "reference": "<ref ou null>",
                "designation": "<libellé du poste>",
                "sous_secteur": "<sous-secteur de ce poste>",
                "unite": "<m², u, forfait, ml…>",
                "quantite": <nombre ou null>,
                "prix_unitaire": <nombre HTVA ou null>,
                "montant_marche": <nombre HTVA ou null>,
                "position": <entier>,
                "ia_confiance": "haute|moyenne|faible"
              }
            ]
          }
        ]
      }
      Ne renvoie QUE le JSON, sans texte avant ni après.
    PROMPT
      cache_control: { type: 'ephemeral' }
    }]
  end

  # ── Prompt utilisateur ───────────────────────────────────────────────────────
  def user_prompt
    context = []
    context << "Projet : #{@project.nom}" if @project&.nom.present?
    context << "Bien : #{@project.property&.adresse}" if @project&.property&.respond_to?(:adresse)
    context << "Catégorie source : #{@devis_donnee.categorie_emetteur}" if @devis_donnee&.categorie_emetteur.present?
    context << "Montant total connu : #{@devis_donnee.montant_total_htva} € HTVA" if @devis_donnee&.montant_total_htva.present?

    header = context.any? ? "Contexte :\n#{context.join("\n")}\n\n" : ''

    <<~PROMPT
      #{header}Voici le texte brut du devis à analyser :

      ---
      #{@texte.first(8000)}
      ---

      Analyse ce devis et génère l'architecture d'état d'avancement au format JSON demandé.
    PROMPT
  end

  # ── Parse la réponse JSON ────────────────────────────────────────────────────
  def parse_response(raw)
    json_str = raw[/\{.*\}/m]
    raise "Aucun JSON trouvé dans la réponse Claude" unless json_str

    data = JSON.parse(json_str)

    thematiques = Array(data['thematiques']).filter_map do |t|
      next if Array(t['lignes']).empty?

      {
        code:            t['code'].to_s,
        label:           t['label'].to_s,
        poids_estime_pct: t['poids_estime_pct'].to_i,
        sous_secteurs:   Array(t['sous_secteurs']),
        lignes:          Array(t['lignes']).each_with_index.map do |l, idx|
          {
            reference:     l['reference']&.to_s,
            designation:   l['designation'].to_s,
            sous_secteur:  l['sous_secteur']&.to_s,
            unite:         l['unite']&.to_s || 'forfait',
            quantite:      safe_decimal(l['quantite']),
            prix_unitaire: safe_decimal(l['prix_unitaire']),
            montant_marche: safe_decimal(l['montant_marche']),
            position:      l['position']&.to_i || idx,
            ia_confiance:  l['ia_confiance'].to_s.in?(%w[haute moyenne faible]) ? l['ia_confiance'].to_s : 'moyenne',
            ia_suggere:    true
          }
        end
      }
    end

    {
      resume:           data['resume'].to_s,
      montant_total_htva: safe_decimal(data['montant_total_htva']),
      thematiques:      thematiques,
      nb_postes:        thematiques.sum { |t| t[:lignes].size },
      nb_thematiques:   thematiques.size
    }
  rescue JSON::ParserError => e
    Rails.logger.warn "DevisAvancementService: JSON parse failed — #{e.message} — raw[0..300]: #{raw[0..300]}"
    { resume: 'Analyse partielle — JSON invalide reçu.', thematiques: [], nb_postes: 0, nb_thematiques: 0 }
  end

  def safe_decimal(val)
    return nil if val.nil?
    BigDecimal(val.to_s).round(2)
  rescue ArgumentError
    nil
  end

  def error_result(message)
    { success: false, error: message }
  end
end
