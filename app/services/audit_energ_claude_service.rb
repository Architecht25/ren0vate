# AuditEnergClaudeService
#
# Extraction intelligente d'un rapport d'Audit Logement Wallonie (Walloreno/PAE)
# via l'API Claude, en lecture NATIVE du PDF (bloc "document" base64) plutôt que
# du texte pré-extrait par pdftotext/Tesseract.
#
# Pourquoi le PDF natif plutôt que le texte OCR (AuditEnergOcrService) :
#   Ce rapport est mis en page en colonnes multiples avec jauges de labels et
#   diagrammes — l'extraction texte linéaire mélange les colonnes voisines
#   (ex: "Perte de chal / Pour les rédui / indic_a_teur de la..."). Les
#   tableaux "Bouquets de travaux" (le cœur actionnable du rapport) sont
#   quasiment illisibles en texte brut mais parfaitement lisibles visuellement.
#   Claude en lecture PDF native (vision) lit la mise en page réelle.
#
# Stratégie :
#   1. Validation du fichier (taille, magic bytes) via OcrService
#   2. Envoi du PDF complet à Claude en bloc "document" + prompt structuré → JSON
#   3. Fallback transparent sur AuditEnergOcrService (regex) si Claude échoue,
#      si la confiance est trop basse, ou si le fichier n'est pas un PDF
#
# Usage :
#   result = AuditEnergClaudeService.new(file).extraire_donnees_audit
#   # Retourne un hash compatible avec les colonnes AuditEnergDonnee

class AuditEnergClaudeService < OcrService
  include HTTParty
  require 'base64'

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-opus-4-5'
  # Un audit complet (8-9 bouquets, chacun avec plusieurs travaux + étapes +
  # alertes + performance détaillée x3 états) génère un JSON volumineux.
  # 4000 tokens s'est révélé insuffisant en pratique, puis 8192 également sur
  # un audit à 56 travaux (réponse tronquée en plein milieu d'un tableau →
  # JSON invalide → bascule silencieuse sur l'OCR fallback, qui n'a pas les
  # champs structurés par intervention : type_element, reference, labels de
  # performance avant/après). Voir aussi la consigne de concision dans le
  # prompt système pour limiter le risque de troncature. Le job tourne sur le
  # dyno worker (pas de timeout routeur Heroku) donc pas de contrainte de
  # latence stricte côté requête sortante — cf. timeout du call_claude ci-dessous.
  MAX_TOKENS        = 24_000

  def extraire_donnees_audit
    api_key = ENV['ANTHROPIC_API_KEY']
    unless api_key.present?
      Rails.logger.warn 'AuditEnergClaudeService: ANTHROPIC_API_KEY absent → fallback OCR'
      return fallback_ocr
    end

    validation = validate_file
    return validation unless validation[:success]

    # Un audit énergétique est toujours un PDF multi-pages en pratique — une
    # image isolée (page scannée seule) ne contiendrait de toute façon pas le
    # rapport complet, on laisse l'ancien pipeline regex/Tesseract la gérer.
    unless file.content_type == 'application/pdf'
      Rails.logger.info 'AuditEnergClaudeService: fichier non-PDF → fallback OCR direct'
      return fallback_ocr
    end

    pdf_base64 = encode_pdf_base64
    unless pdf_base64
      Rails.logger.warn 'AuditEnergClaudeService: encodage PDF échoué → fallback OCR'
      return fallback_ocr
    end

    raw_response = call_claude(pdf_base64, api_key)
    unless raw_response
      Rails.logger.warn 'AuditEnergClaudeService: pas de réponse Claude → fallback OCR'
      return fallback_ocr
    end

    data = parse_claude_response(raw_response)
    unless data
      Rails.logger.warn 'AuditEnergClaudeService: JSON invalide → fallback OCR'
      return fallback_ocr
    end

    build_result(data)

  rescue StandardError => e
    Rails.logger.error "AuditEnergClaudeService error: #{e.message}"
    fallback_ocr
  end

  private

  # ── Lecture du fichier ────────────────────────────────────────────────────────

  def encode_pdf_base64
    file.rewind
    Base64.strict_encode64(file.read)
  rescue StandardError => e
    Rails.logger.warn "AuditEnergClaudeService: encode base64 échoué: #{e.message}"
    nil
  end

  # ── Appel API Claude ──────────────────────────────────────────────────────────

  def call_claude(pdf_base64, api_key)
    response = HTTParty.post(
      ANTHROPIC_API_URL,
      headers: {
        'x-api-key'         => api_key,
        'anthropic-version' => ANTHROPIC_VERSION,
        'anthropic-beta'    => 'pdfs-2024-09-25',
        'content-type'      => 'application/json'
      },
      body: {
        model:      MODEL,
        max_tokens: MAX_TOKENS,
        system:     system_prompt,
        messages:   [{
          role:    'user',
          content: [
            {
              type:   'document',
              source: { type: 'base64', media_type: 'application/pdf', data: pdf_base64 }
            },
            {
              type: 'text',
              text: "Voici un rapport d'Audit Logement Wallonie (format Walloreno/PAE). " \
                    "Analyse-le intégralement (toutes les pages) et extrait les données demandées en JSON."
            }
          ]
        }]
      }.to_json,
      timeout: 400 # généreux : tourne sur le worker Solid Queue, pas derrière le routeur Heroku (H12)
    )

    if response.success?
      if response['stop_reason'] == 'max_tokens'
        Rails.logger.warn "AuditEnergClaudeService: réponse tronquée (max_tokens=#{MAX_TOKENS} atteint) " \
                           "— le JSON sera probablement invalide, augmenter MAX_TOKENS"
      end
      response.dig('content', 0, 'text')&.strip
    else
      Rails.logger.error "AuditEnergClaudeService Claude #{response.code}: #{response.body[0..300]}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn 'AuditEnergClaudeService: timeout Claude'
    nil
  end

  # ── Prompt système ────────────────────────────────────────────────────────────

  def system_prompt
    [{
      type: 'text',
      text: <<~PROMPT,
        Tu es un expert en audit énergétique résidentiel wallon (procédure PAE2 / Audit Logement
        Walloreno) et en primes Habitation belges. Tu analyses un rapport d'audit PDF de 30 à 50
        pages et en extrais les données essentielles pour un propriétaire, en ignorant le jargon
        technique et les schémas indigestes qui n'apportent rien à la décision.

        RÈGLES IMPORTANTES :
        - Reste CONCIS partout : ce rapport peut compter 50 pages et 8-9 bouquets de travaux, le
          JSON de sortie doit rester dans le budget de tokens alloué. Toute chaîne de texte
          ("description", "adresse", etc.) doit être une phrase courte (idéalement moins de 15
          mots) — jamais un paragraphe recopié du rapport. Ne répète JAMAIS le texte des notes de
          bas de page ou des conditions techniques d'éligibilité aux primes (R minimum, Uw
          maximum…) dans "description" : ce sont des critères génériques du dispositif wallon, pas
          une information propre à ce logement.
        - Le rapport contient TROIS situations comparées : "situation initiale", "situation
          initiale modifiée" (= mêmes travaux mais périmètre/secteurs corrigés, souvent SANS
          coût réel — ne pas confondre avec des travaux) et "situation après travaux de
          rénovation". La section "initiale modifiée" est parfois absente : dans ce cas retourne
          null pour "initiale_modifiee".
        - Les LABELS (G à A++) apparaissent à de très nombreux endroits (feuille de route,
          tableaux de bouquets, paroi par paroi). Pour "label_global_initial" et
          "label_global_final", ne retourne QUE le label de la feuille de route (page 1) —
          colonne "SITUATION INITIALE" et dernière colonne de droite (objectif final), jamais un
          label intermédiaire d'une paroi ou d'un bouquet individuel.
        - "etapes" correspond à la feuille de route (page 1) : chaque flèche/carte représente une
          étape avec un label cible, un coût CUMULÉ et des primes CUMULÉES jusqu'à cette étape
          (pas le coût de cette étape seule). Associe à chaque étape la liste des numéros de
          bouquets qu'elle regroupe (visibles dans le contenu de chaque carte "TRAVAUX À
          RÉALISER").
        - "recommandations" correspond aux tableaux "BOUQUETS DE TRAVAUX DE RÉNOVATION" (plusieurs
          pages) ET à leur détail dans "DÉTAILS DES TRAVAUX DE RÉNOVATION" (une page dédiée par
          intervention, avec le libellé précis de la technique recommandée). Une ligne par
          intervention.
          - "reference" : UNIQUEMENT le code technique exact tel qu'imprimé sur le rapport à côté
            de la paroi/du système (ex: "T1", "F8", "CC", "ECS1", "M2"). Ne mets JAMAIS un mot
            descriptif ou générique (ex: "Aération", "Ventilation") dans "reference" — si
            l'intervention n'a pas de code de paroi/système associé (ex: "Rendre conforme
            l'installation électrique", "Faire appel à un architecte"), retourne null.
          - "description" : le libellé PRÉCIS et concret de la technique recommandée, tel qu'il
            apparaît dans le rapport (colonne "Recommandations" du tableau de bouquet, ou titre de
            la page de détail correspondante) — ex: "Toiture Sarking", "Isolation par l'intérieur",
            "Remplacer la chaudière → générateur plus performant", "Installer un système C pour
            la santé des occupants". N'utilise JAMAIS une reformulation vague ou générique comme
            "Autre technique d'isolation" — si deux interventions concernent le même type de
            travaux (ex: deux toitures isolées différemment), reprends le libellé spécifique
            propre à CHACUNE telle qu'imprimée dans le rapport, même s'il se ressemble.
          - "type_element" doit être l'une de : toiture, mur, plancher, menuiserie, chauffage,
            ecs, ventilation, etancheite, photovoltaique, non_energetique.
          - "performance_avant"/"performance_apres" : résume la valeur technique pertinente en une
            courte chaîne (ex: "U = 5,00 W/m²K", "Label G", "Rendement 85 %") — ne mets PAS de
            tableau de composition de paroi, juste la valeur clé avant/après. null si non pertinent
            (ex: obligations administratives comme "Faire appel à un architecte").
        - "alertes_non_energetiques" correspond aux sections "ASPECTS NON ÉNERGÉTIQUES" et leurs
          détails (détection incendie, installation électrique, radon, évacuation des eaux,
          infiltrations/humidité, risque de chute, appareils à combustion). "categorie" doit être
          l'une de : detection_incendie, installation_electrique, radon, evacuation_eaux,
          infiltrations_humidite, risque_chute, appareils_combustion. "conforme" = false si le
          rapport signale un défaut/non-conformité pour cette catégorie, true si explicitement
          conforme, et à omettre entièrement si la catégorie n'est pas traitée dans le rapport.
        - "peb_projection" vient de la page "VERS LE CERTIFICAT PEB" (projection Epw avant/après +
          5 sous-indicateurs qualitatifs). Les valeurs des sous-indicateurs doivent être choisies
          UNIQUEMENT parmi les échelles imprimées sur le schéma :
          besoins_chaleur: excessifs|eleves|moyens|faibles|minimes
          performance_chauffage / performance_ecs: mediocre|insuffisante|satisfaisante|bonne|excellente
          ventilation: absent|tres_partiel|partiel|incomplet|complet
          renouvelables: liste des pictogrammes activés parmi sol_thermique|sol_photovoltaique|biomasse|pompe_a_chaleur|cogeneration
        - Tous les montants en euros sont des nombres (pas de "€", pas de séparateur de milliers).
          Toutes les dates au format "DD/MM/YYYY".
        - Si une information n'est vraiment pas présente dans le document, retourne null — n'invente
          jamais de valeur.

        Réponds UNIQUEMENT avec un objet JSON valide (pas de markdown, pas d'explication), avec
        exactement cette structure :
        {
          "identification": {
            "numero_audit": "string ou null",
            "date_enregistrement": "DD/MM/YYYY ou null",
            "date_modification": "DD/MM/YYYY ou null",
            "valable_jusquau": "DD/MM/YYYY ou null",
            "numero_pae": "string ou null",
            "denomination_auditeur": "string ou null",
            "adresse_auditeur": "string ou null"
          },
          "bien": {
            "adresse": "string ou null",
            "type_logement": "string ou null",
            "annee_construction": "string ou null",
            "volume_protege_m3": nombre ou null,
            "surface_deperdition_m2": nombre ou null,
            "surface_plancher_chauffe_m2": nombre ou null
          },
          "label_global_initial": "A++|A+|A|B|C|D|E|F|G ou null",
          "label_global_final": "A++|A+|A|B|C|D|E|F|G ou null",
          "performance": {
            "initiale": { "niveau_k": entier ou null, "label_besoins_chauffage": "string ou null", "label_systeme_chauffage": "string ou null", "label_systeme_ecs": "string ou null", "energie_finale_kwh": entier ou null, "energie_primaire_kwh": entier ou null, "pourcentage_renouvelable": entier ou null, "emissions_co2_t": nombre ou null },
            "initiale_modifiee": { même structure ou null },
            "apres_travaux": { même structure ou null }
          },
          "peb_projection": {
            "epw_initial": entier ou null,
            "epw_apres": entier ou null,
            "besoins_chaleur": { "initial": "string ou null", "apres": "string ou null" },
            "performance_chauffage": { "initial": "string ou null", "apres": "string ou null" },
            "performance_ecs": { "initial": "string ou null", "apres": "string ou null" },
            "ventilation": { "initial": "string ou null", "apres": "string ou null" },
            "renouvelables": { "initial": ["..."], "apres": ["..."] }
          },
          "etapes": [
            { "numero": entier, "label_cible": "string", "gain_pct_an": nombre ou null, "cout_cumule_euro": nombre ou null, "primes_cumule_euro": nombre ou null, "bouquets": [entiers] }
          ],
          "recommandations": [
            { "bouquet": entier, "reference": "string ou null", "type_element": "string", "description": "string", "performance_avant": "string ou null", "performance_apres": "string ou null", "gain_reel_kwh": nombre ou null, "economie_euro_an": nombre ou null, "cout_estime_euro": nombre ou null, "subsides_euro": nombre ou null, "temps_retour_ans": "string ou null" }
          ],
          "alertes_non_energetiques": [
            { "categorie": "string", "conforme": booléen, "description": "string" }
          ],
          "bilan_scenario_complet": {
            "cout_total_euro": nombre ou null,
            "subsides_total_euro": nombre ou null,
            "economie_annuelle_euro": nombre ou null,
            "temps_retour": "string ou null"
          },
          "confiance": entier 0-100
        }
      PROMPT
      cache_control: { type: 'ephemeral' }
    }]
  end

  # ── Parsing réponse Claude ───────────────────────────────────────────────────

  def parse_claude_response(raw)
    json_str = raw[/\{.*\}/m]
    return nil unless json_str

    JSON.parse(json_str)
  rescue JSON::ParserError => e
    Rails.logger.warn "AuditEnergClaudeService JSON parse: #{e.message}"
    nil
  end

  # ── Construction du hash de résultat normalisé ────────────────────────────────

  def build_result(data)
    conf = [[data['confiance'].to_i, 0].max, 100].min
    if conf < 40
      Rails.logger.warn "AuditEnergClaudeService: confiance #{conf}% trop basse → fallback OCR"
      return fallback_ocr
    end

    ident = data['identification'] || {}
    bien  = data['bien']            || {}
    perf  = data['performance']     || {}
    peb   = data['peb_projection']  || {}
    bilan = data['bilan_scenario_complet'] || {}

    {
      success: true,

      numero_audit:          ident['numero_audit']&.strip.presence,
      date_enregistrement:   parse_date(ident['date_enregistrement']),
      date_modification:     parse_date(ident['date_modification']),
      valable_jusquau:       parse_date(ident['valable_jusquau']),
      numero_pae:            ident['numero_pae']&.strip.presence,
      denomination_auditeur: ident['denomination_auditeur']&.strip.presence,
      adresse_auditeur:      ident['adresse_auditeur']&.strip.presence,

      adresse_bien:                bien['adresse']&.strip.presence,
      type_logement:               bien['type_logement']&.strip.presence,
      annee_construction:          bien['annee_construction']&.strip.presence,
      volume_protege_m3:           parse_float(bien['volume_protege_m3']),
      surface_deperdition_m2:      parse_float(bien['surface_deperdition_m2']),
      surface_plancher_chauffe_m2: parse_float(bien['surface_plancher_chauffe_m2']),

      label_initial: valider_label(data['label_global_initial']),
      label_final:   valider_label(data['label_global_final']),

      performance_json:    perf.presence || {},
      peb_projection_json: peb.presence  || {},
      etapes_json:         Array(data['etapes']),
      recommandations_json: Array(data['recommandations']),
      alertes_json:        Array(data['alertes_non_energetiques']),

      cout_total_scenario:        parse_float(bilan['cout_total_euro']),
      subsides_total_scenario:    parse_float(bilan['subsides_total_euro']),
      economie_annuelle_scenario: parse_float(bilan['economie_annuelle_euro']),
      temps_retour_scenario:      bilan['temps_retour']&.to_s&.strip.presence,

      bilan_json: {
        cout_total:     parse_float(bilan['cout_total_euro']),
        subsides_total: parse_float(bilan['subsides_total_euro']),
        economie_an:    parse_float(bilan['economie_annuelle_euro']),
        temps_retour:   bilan['temps_retour']
      },

      confiance_ocr:       conf.to_f,
      extraction_complete: ident['numero_audit'].present? && ident['numero_pae'].present?,
      source_extraction:   'claude',
      texte_ocr_brut:      nil
    }
  end

  # ── Fallback OCR regex ────────────────────────────────────────────────────────

  def fallback_ocr
    Rails.logger.info 'AuditEnergClaudeService: using regex OCR fallback'
    result = AuditEnergOcrService.new(@file).extraire_donnees_audit
    result[:success] ? result.merge(source_extraction: 'ocr_fallback') : result
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  def valider_label(label)
    AuditEnergDonnee::LABELS_VALIDES.include?(label.to_s.upcase.strip) ? label.to_s.upcase.strip : nil
  end

  def parse_float(val)
    return nil if val.nil? || val == 'null'
    val.is_a?(Numeric) ? val.to_f.nonzero? : val.to_s.tr(',', '.').to_f.nonzero?
  rescue StandardError
    nil
  end

  def parse_date(str)
    return nil unless str.present?
    Date.strptime(str, '%d/%m/%Y')
  rescue ArgumentError, TypeError
    nil
  end
end
