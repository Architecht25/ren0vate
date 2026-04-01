class DevisOcrService < FactureOcrService
  # ─────────────────────────────────────────────────────────────────────────────
  # Devis / Métré — documents techniques de chantier de rénovation (Belgique)
  # Hérite de FactureOcrService pour les patterns montant, date, BCE, TVA, entreprise
  # Enrichissements : surface de travaux, validité du devis, détection types de travaux
  # Formats supportés : PDF texte, PDF scanné, JPEG, PNG
  # ─────────────────────────────────────────────────────────────────────────────

  # ── Date de validité du devis ─────────────────────────────────────────────────
  VALIDITE_PATTERNS = [
    /valable?\s+jusqu['']?au?\s*[:\-]?\s*([0-3]?\d[\/\-\.][0-1]?\d[\/\-\.](?:20)?\d{2})/i,
    /offre\s+valable\s+(?:jusqu(?:'|au)\s+)?(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i,
    /expir[ae]\s*[:\-]?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i,
    /(?:date\s+)?(?:d[''])?expiration\s*[:\-]?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i,
    /(?:geldig|geldigheid)\s*(?:tot|t\.e\.m\.)\s*[:\-]?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i,
  ].freeze

  # ── Surface de travaux ────────────────────────────────────────────────────────
  SURFACE_PATTERNS = [
    /(\d+(?:[.,]\d+)?)\s*m[²2]/i,
    /surface\s*[:\-]?\s*(\d+(?:[.,]\d+)?)\s*m/i,
    /(\d+(?:[.,]\d+)?)\s*m(?:ètres?\s+carrés?|etres?\s+carres?)/i,
  ].freeze

  # ── Numéro de devis ───────────────────────────────────────────────────────────
  NUMERO_DEVIS_PATTERNS = [
    /(?:devis|offre|cotation|ref(?:érence)?)\s*n[°o]?\s*[:\-]?\s*([A-Z0-9\-\/\.]{3,25})/i,
    /(?:bestek|offerte|ref(?:erentie)?)\s*n[°o]?\s*[:\-]?\s*([A-Z0-9\-\/\.]{3,25})/i,
    /n[°o]\s*(?:devis|offre)\s*[:\-]?\s*([A-Z0-9\-\/\.]{3,25})/i,
  ].freeze

  # ── Mots-clés de détection des types de travaux ───────────────────────────────
  MOTS_CLES_TRAVAUX = {
    'isolation_toit' => [
      /\bisol(?:ation|ant)\s+(?:de\s+)?(?:la\s+)?toit(?:ure)?/i,
      /\bisol(?:ation|ant)\s+(?:en\s+)?(?:grenier|comble|toiture)/i,
      /\bdakisolatie\b/i,
      /\bzolderisolatie\b/i,
    ],
    'isolation_facade' => [
      /\bisol(?:ation|ant)\s+(?:des?\s+)?fa[cç]ade[sx]?/i,
      /\bisol(?:ation|ant)\s+(?:par\s+)?(?:l[''])?ext[eé]rieure?/i,
      /\bgevelisolatie\b/i,
      /\beps\s+(?:graphit[eé]|fa[cç]ade)\b/i,
    ],
    'isolation_sol' => [
      /\bisol(?:ation|ant)\s+(?:du\s+)?(?:plancher|sol|dalle)/i,
      /\bvloerisolatie\b/i,
      /\bdalvloer(?:isolatie)?\b/i,
    ],
    'isolation_murs' => [
      /\bisol(?:ation|ant)\s+(?:des?\s+)?mur[sx]?/i,
      /\bisolation\s+(?:par\s+)?l['']int[eé]rieure?/i,
      /\bmuuisolatie\b/i,
    ],
    'chassis_vitrage' => [
      /\bch[aâ]ssis\b/i,
      /\bvitr(?:age|ages?)\b/i,
      /\bfen[eê]tre(?:s)?\b/i,
      /\bporte(?:s)?\s+(?:ext[eé]rieures?|entr[eé]e)\b/i,
      /\bHr[\+]+\s+(?:glas|vitrage)\b/i,
      /\bdubbelglas\b/i,
      /\bdrieglas\b/i,
      /\bramen?\b/i,
      /\bvelux\b/i,
    ],
    'chauffage' => [
      /\bchaudi[eè]re\b/i,
      /\bchauffage\b/i,
      /\bradiateur\b/i,
      /\btubage\b/i,
      /\bketel\b/i,
      /\bverwarm(?:ing|ingsinstallatie)\b/i,
    ],
    'sanitaire' => [
      /\bsanitaire\b/i,
      /\b[eé]gouttage\b/i,
      /\b[eé]gout\b/i,
      /\bsanitair\b/i,
      /\btuyauterie\s+(?:eau|sanitaire)/i,
      /\brobinet\b/i,
      /\bcullasse\b/i,
      /\bdistributeur\s+eau/i,
    ],
    'electricite' => [
      /\b[eé]lectricit[eé]\b/i,
      /\binstallation\s+[eé]lectrique\b/i,
      /\btableau\s+[eé]lectrique\b/i,
      /\bdisjoncteur\b/i,
      /\bdiff[eé]rentiel\b/i,
      /\bcoffret\b/i,
      /\bprise(?:s)?\b/i,
      /\binterrupteur\b/i,
      /\belectriciteit\b/i,
    ],
    'gaz' => [
      /\bgaz\b/i,
      /\btuyauterie\s+gaz\b/i,
      /\bconformit[eé]\s+gaz\b/i,
      /\bgas(?:leiding|installatie)?\b/i,
    ],
    'maconnerie' => [
      /\bmaçonnerie\b/i,
      /\bch(?:ape|appe)\b/i,
      /\bbeton\b/i,
      /\bdallage\b/i,
      /\bpavage\b/i,
      /\bmetselwerk\b/i,
    ],
    'carrelage_revetement' => [
      /\bcarrelage\b/i,
      /\bparquet\b/i,
      /\brevetement\s+(?:sol|mur)/i,
      /\btegels?\b/i,
      /\bvloer(?:tegels?|bekleding)\b/i,
    ],
    'plafonnage_peinture' => [
      /\bplafonn(?:age|er)\b/i,
      /\bpeinture\b/i,
      /\benduit\b/i,
      /\bgyp(?:lak|se|lat)\b/i,
      /\bplafond\s+suspendu\b/i,
      /\bpleisterwerk\b/i,
    ],
    'toiture' => [
      /\btoiture\b/i,
      /\bzinc\b/i,
      /\bgoutti[eè]re[sx]?\b/i,
      /\bartisans?\s+couvreur/i,
      /\bdakwerken?\b/i,
      /\bdakbedekking\b/i,
    ],
    'pompe_chaleur' => [
      /\bpompe\s+[aà]\s+chaleur\b/i,
      /\bpac\b/i,
      /\bwarmtepomp\b/i,
      /\bheat\s+pump\b/i,
    ],
    'ventilation' => [
      /\bventil(?:ation|ateur)\b/i,
      /\bvmc\b/i,
      /\bdouble\s+flux\b/i,
      /\bventilatie\b/i,
    ],
    'eclairage' => [
      /\b[eé]cl(?:airage|aire)\b/i,
      /\bpoint(?:s)?\s+lumineux\b/i,
      /\bluminaire\b/i,
      /\bverlichting\b/i,
      /\bled\s+lamp/i,
    ],
    'photovoltaique' => [
      /\bphotovolta[ïi]que\b/i,
      /\bpanneau(?:x)?\s+solaires?\b/i,
      /\bzonnepanelen?\b/i,
    ],
    'chauffe_eau_thermodynamique' => [
      /\bchauffe[\-\s]eau\s+(?:thermodynamique|solaire|thermo)\b/i,
      /\bcet\b/i,
      /\bboiler\s+thermodynamique\b/i,
      /\bwarmtepompboiler\b/i,
    ],
    'audit_energetique' => [
      /\baudit\s+[eé]nerg[eé]tique\b/i,
      /\benergieaudit\b/i,
    ],
    'renovation_generale' => [
      /r[eé]novation\s+(?:g[eé]n[eé]rale|complète|maison|immeuble)/i,
      /\br[eé]nover\s+(?:une?\s+)?(?:maison|immeuble|b[aâ]timent)/i,
      /transformation\s+(?:de\s+)?(?:maison|appartement|immeuble)/i,
      /r[eé]habilitation\s+(?:compl[eè]te|totale|maison)/i,
      /travaux\s+(?:de\s+)?r[eé]novation/i,
    ],
  }.freeze

  def initialize(file, language: 'fra+nld')
    super(file, language: language)
  end

  # ── Point d'entrée principal ──────────────────────────────────────────────────
  def extraire_donnees_devis
    ocr_result = call
    return ocr_result unless ocr_result[:success]

    texte = ocr_result[:text].to_s

    donnees = extraire_champs_devis(texte)
    confiance = calculer_confiance_devis(donnees, ocr_result[:confidence])

    ocr_result.merge(
      donnees_devis:          donnees,
      nom_entreprise:         donnees[:nom_entreprise],
      numero_bce_entreprise:  donnees[:numero_bce_entreprise],
      numero_tva_entreprise:  donnees[:numero_tva_entreprise],
      montant_total_htva:     donnees[:montant_total_htva],
      montant_total_tvac:     donnees[:montant_total_tvac],
      taux_tva:               donnees[:taux_tva],
      date_devis:             donnees[:date_devis],
      numero_devis:           donnees[:numero_devis],
      validite_devis:         donnees[:validite_devis],
      types_travaux_detectes: donnees[:types_travaux_detectes],
      surface_travaux:        donnees[:surface_travaux],
      confiance_extraction:   confiance,
      extraction_complete:    extraction_complete_devis?(donnees),
      texte_brut:             texte
    )
  end

  private

  def extraire_champs_devis(texte)
    # Récupérer les champs hérités de FactureOcrService
    champs_facture = {
      nom_entreprise:        extraire_nom_entreprise(texte),
      numero_bce_entreprise: extraire_numero_bce(texte),
      taux_tva:              extraire_taux_tva(texte),
    }

    montant_ht   = extraire_montant_ht(texte)
    montant_tvac = extraire_montant_tvac_devis(texte)

    champs_facture.merge(
      numero_tva_entreprise:  extraire_numero_tva(texte),
      montant_total_htva:     montant_ht,
      montant_total_tvac:     montant_tvac || calculer_tvac(montant_ht, champs_facture[:taux_tva]),
      date_devis:             extraire_date_devis(texte),
      numero_devis:           extraire_numero_devis(texte),
      validite_devis:         extraire_validite_devis(texte),
      types_travaux_detectes: detecter_types_travaux(texte),
      surface_travaux:        extraire_surface_travaux(texte),
    )
  end

  # ── Numéro TVA entreprise ──────────────────────────────────────────────────────
  def extraire_numero_tva(texte)
    patterns = [
      /(?:t\.?v\.?a\.?|tva|btw)\s*(?:n[°o]\.?|number|num)?\s*[:\-]?\s*(?:BE\s*)?([\d]{4}[.\s]?[\d]{3}[.\s]?[\d]{3})/i,
      /(?:be|belgique)\s*([\d]{4}[.\s]?[\d]{3}[.\s]?[\d]{3})/i,
    ]
    patterns.each do |pattern|
      m = texte.match(pattern)
      if m
        tva = m[1].gsub(/[\.\s]/, '')
        return "BE#{tva}" if tva.match?(/^\d{10}$/)
      end
    end
    nil
  end

  # ── Montant total TVAC (devis) ────────────────────────────────────────────────
  def extraire_montant_tvac_devis(texte)
    patterns = [
      # Format belge : TOTAL TTC 16.006,00 €
      /(?:total\s*(?:ttc|tvac)|montant\s*(?:ttc|tvac)|somme\s*(?:ttc|tvac))\s*[:\-]?\s*([0-9]{1,3}(?:[.\s][0-9]{3})*(?:,[0-9]{1,2})?)\s*[€]/i,
      /(?:total\s*(?:ttc|tvac)|montant\s*(?:ttc|tvac)|somme\s*(?:ttc|tvac))\s*[:\-]?\s*([0-9]{1,3}(?:[,\s][0-9]{3})*(?:\.[0-9]{1,2})?)\s*[€]/i,
      /([0-9]{1,3}(?:[.\s][0-9]{3})*(?:,[0-9]{1,2})?)\s*[€]\s*(?:tvac|ttc)/i,
      /(?:total\s+(?:général|general|devis))\s*[:\-]?\s*([0-9]{1,3}(?:[.\s][0-9]{3})*(?:,[0-9]{1,2})?)\s*[€]/i,
    ]
    patterns.each do |pattern|
      m = texte.match(pattern)
      if m
        val = parse_montant_belge(m[1])
        return val.round(2) if val && val > 0 && val < 10_000_000
      end
    end
    nil
  end

  # ── Date de devis ─────────────────────────────────────────────────────────────
  def extraire_date_devis(texte)
    patterns = [
      /(?:date\s+(?:du\s+)?devis|devis\s+(?:du|en\s+date\s+du))\s*[:\-]?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i,
      /(?:datum\s+(?:offerte|bestek))\s*[:\-]?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i,
      /(?:date\s*:|le\s*:)\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i,
    ]
    patterns.each do |pattern|
      m = texte.match(pattern)
      return parse_date_devis(m[1]) if m
    end

    # Fallback : première date raisonnable trouvée dans le texte
    m = texte.match(/(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/)
    m ? parse_date_devis(m[1]) : nil
  end

  # ── Numéro de devis ───────────────────────────────────────────────────────────
  def extraire_numero_devis(texte)
    NUMERO_DEVIS_PATTERNS.each do |pattern|
      m = texte.match(pattern)
      if m
        num = m[1].strip
        return num if num.length.between?(3, 25)
      end
    end
    nil
  end

  # ── Date de validité ──────────────────────────────────────────────────────────
  def extraire_validite_devis(texte)
    VALIDITE_PATTERNS.each do |pattern|
      m = texte.match(pattern)
      return parse_date_devis(m[1]) if m
    end
    nil
  end

  # ── Surface de travaux ────────────────────────────────────────────────────────
  # Renvoie la plus grande valeur m² plausible (la plus petite pourrait
  # être un numéro d'appartement ou une dimension partielle).
  def extraire_surface_travaux(texte)
    surfaces = []
    SURFACE_PATTERNS.each do |pattern|
      texte.scan(pattern) do |m|
        val = m[0].gsub(',', '.').to_f
        surfaces << val if val.between?(5, 10_000)
      end
    end
    surfaces.max&.round(2)
  end

  # ── Détection des types de travaux ────────────────────────────────────────────
  def detecter_types_travaux(texte)
    types = []
    MOTS_CLES_TRAVAUX.each do |type, patterns|
      detected = patterns.any? { |pattern| texte.match?(pattern) }
      types << type if detected
    end

    # Fallback : si aucun type n'est détecté mais que le texte est non vide
    types << 'autre' if types.empty? && texte.length > 100

    types.uniq
  end

  # ── Calcul TVAC depuis HTVA + taux ───────────────────────────────────────────
  def calculer_tvac(montant_ht, taux_tva)
    return nil unless montant_ht.present? && taux_tva.present?
    (montant_ht * (1 + taux_tva / 100.0)).round(2)
  end

  # ── Parse date ───────────────────────────────────────────────────────────────
  def parse_date_devis(str)
    return nil if str.blank?

    %w[%d/%m/%Y %d-%m-%Y %d.%m.%Y %d/%m/%y %d-%m-%y %d.%m.%y].each do |fmt|
      begin
        date = Date.strptime(str, fmt)
        return date if date.between?(Date.new(2010), Date.current + 2.years)
      rescue ArgumentError
        next
      end
    end
    nil
  end

  # ── Score de confiance spécifique aux devis ───────────────────────────────────
  def calculer_confiance_devis(donnees, confiance_ocr)
    points = 0
    total  = 100

    # Montant HTVA (critique)
    points += 35 if donnees[:montant_total_htva].present?
    # Date du devis (important)
    points += 20 if donnees[:date_devis].present?
    # Types de travaux détectés (valeur métier principale)
    points += 20 if Array(donnees[:types_travaux_detectes]).any?
    # Entreprise
    points += 10 if donnees[:nom_entreprise].present?
    # Numéro de devis ou BCE
    points += 10 if donnees[:numero_devis].present? || donnees[:numero_bce_entreprise].present?
    # Surface bonus
    points += 5  if donnees[:surface_travaux].present?

    confiance_donnees = (points.to_f / total * 100).round(1).clamp(0, 100)

    if confiance_ocr
      (confiance_donnees * 0.6 + confiance_ocr * 0.4).round(1)
    else
      confiance_donnees
    end
  end

  def extraction_complete_devis?(donnees)
    donnees[:montant_total_htva].present? &&
      donnees[:date_devis].present? &&
      Array(donnees[:types_travaux_detectes]).any?
  end
end
