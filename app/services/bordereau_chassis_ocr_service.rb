class BordereauChassisOcrService < OcrService
  # ─────────────────────────────────────────────────────────────────────────────
  # Bordereau de commande / fiche technique châssis (Belgique)
  # Extrait les valeurs thermiques Uw/Ug/Uf, type de vitrage, fabricant,
  # surface et nombre d'unités — données clés pour l'éligibilité prime châssis.
  # Supporte : PDF texte, PDF scanné, JPEG/PNG, billingue fr+nl
  # ─────────────────────────────────────────────────────────────────────────────

  # ── Valeur Uw (coeff global fenêtre) ─────────────────────────────────────────
  UW_PATTERNS = [
    # Pattern prioritaire : Uw global dans un tableau récapitulatif (ex WinPro/Lemmens)
    # Cherche une ligne finale de total : "<surface_total_m2> <uw_global>" hors contexte d'un châssis individuel
    /^\s*\d+[.,]\d+\s+\d+[.,]\d+\s*m[²2]\s+(\d+[.,]\d+)\s*$/m,
    /\bUw\s*[=:≤≥]\s*(\d+[.,]\d+)\s*(?:W\s*[\/\\]?\s*m[²2][.,]?K?)?/i,
    /\bU(?:w|fenêtre|window)\s*[=:]\s*(\d+[.,]\d+)/i,
    /\bvaleur\s+Uw?\s*[=:]\s*(\d+[.,]\d+)/i,
    /\bwarmtedoorgangswaarde\s*Uw?\s*[=:]\s*(\d+[.,]\d+)/i,
    /\bU\s*[-–]\s*waarde\s+raam\s*[=:]\s*(\d+[.,]\d+)/i,
    /\bcoefficient\s+de\s+transmission\s+thermique\s+Uw?\s*[=:]\s*(\d+[.,]\d+)/i,
    /\bthermische\s+transmissiecoëff[^=]*[=:]\s*(\d+[.,]\d+)/i,
  ].freeze

  # ── Valeur Ug (coeff vitrage seul) ────────────────────────────────────────────
  UG_PATTERNS = [
    /\bUg\s*[=:]\s*(\d+[.,]\d+)\s*(?:W\s*\/\s*m[²2]K?)?/i,
    /\bU\s*vitrage\s*[=:]\s*(\d+[.,]\d+)/i,
    /\bU\s*glas\s*[=:]\s*(\d+[.,]\d+)/i,
    /\bUg(?:las)?\s*[=:]\s*(\d+[.,]\d+)/i,
    /\btransmittance\s+(?:thermique\s+)?(?:du\s+)?vitrage\s*[=:]\s*(\d+[.,]\d+)/i,
  ].freeze

  # ── Valeur Uf (coeff cadre / châssis) ─────────────────────────────────────────
  UF_PATTERNS = [
    /\bUf\s*[=:]\s*(\d+[.,]\d+)\s*(?:W\s*\/\s*m[²2]K?)?/i,
    /\bU\s*cadre\s*[=:]\s*(\d+[.,]\d+)/i,
    /\bU\s*frame\s*[=:]\s*(\d+[.,]\d+)/i,
    /\bUf(?:rame)?\s*[=:]\s*(\d+[.,]\d+)/i,
  ].freeze

  # ── Facteur solaire g (g-value) ───────────────────────────────────────────────
  G_VALUE_PATTERNS = [
    /\bg\s*[=:]\s*(0[.,]\d+)/i,
    /\bfacteur\s+solaire\s*[=:]\s*(0[.,]\d+)/i,
    /\bzonnefactor\s*[=:]\s*(0[.,]\d+)/i,
    /\bg[\-\s]?value\s*[=:]\s*(0[.,]\d+)/i,
    /\btransmittance\s+solaire\s+totale\s*[=:]\s*(0[.,]\d+)/i,
  ].freeze

  # ── Type de vitrage ──────────────────────────────────────────────────────────
  VITRAGE_PATTERNS = {
    'triple'       => [/\btriple\s*(?:vitrage|glazing|glass|glas)\b/i, /\bdrieglas\b/i, /\b3\s*(?:fach|triple)\b/i],
    'double'       => [/\bdouble\s*(?:vitrage|glazing|glass|glas)\b/i, /\bdubbelglas\b/i, /\b2\s*fach\b/i],
    'hr_plus_plus' => [/\bHR\s*\+{2,}\b/i, /\bhoog\s*rendements?\s*glas\b/i],
    'hr_plus'      => [/\bHR\s*\+\b/i],
    'monolithique' => [/\bsimple\s*vitrage\b/i, /\bsimplex\b/i, /\benkelglas\b/i],
  }.freeze

  # ── Type de châssis / matériau ────────────────────────────────────────────────
  CHASSIS_TYPE_PATTERNS = {
    'pvc'       => [/\bP\.?V\.?C\.?\b/i, /\bpolyvinylchloride\b/i, /\bkunststof\b/i],
    'aluminium' => [/\balu(?:minium|minio)?\b/i, /\baluminium\b/i],
    'bois'      => [/\bbois\b/i, /\bhout(?:en)?\b/i, /\bholz\b/i],
    'mixte'     => [/\bbois\s*[–\-]\s*alu/i, /\bhout\s*[–\-]\s*alu/i, /\bcomposit[e]?\b/i],
  }.freeze

  # ── Fabricants connus ─────────────────────────────────────────────────────────
  FABRICANTS_CONNUS = %w[
    Reynaers Technal Schüco Schueco Veka Internorm AGC Velux
    Roto Winkhaus Siegenia Deceuninck Cortizo SAPA Hydro
    Nordan Unilux Jansen Alumil Heroal Aluk
    Kommerling Kömmerling Trocal Profine
    Belisol Lemmens Menuiserie Alumil Aliplast
  ].freeze

  # ── Patterns surface et unités ───────────────────────────────────────────────
  SURFACE_CHASSIS_PATTERNS = [
    /surface\s+(?:totale\s+)?(?:de\s+)?(?:châssis|vitrage|fenêtres?)\s*[=:]\s*(\d+[.,]\d*)\s*m[²2]/i,
    /(\d+[.,]\d*)\s*m[²2]\s+(?:de\s+)?(?:châssis|vitrage|fenêtres?)/i,
    /totale?\s+(?:opp(?:ervlak(?:te)?)?|surface)\s*[=:]\s*(\d+[.,]\d*)\s*m[²2]/i,
  ].freeze

  UNITES_PATTERNS = [
    /(\d+)\s*(?:fenêtres?|portes?\s+fenêtres?|porte-fenêtres?|baies?|châssis|ramen?|kozijnen?)/i,
    /\bnombre\s+d['']unités?\s*[=:]\s*(\d+)/i,
    /\baantal\s+(?:ramen?|stuks?|eenheden?)\s*[=:]\s*(\d+)/i,
    /\bqt[eé]?\s*[=:]\s*(\d+)\s+(?:fenêtres?|châssis)/i,
  ].freeze

  # ── Point d'entrée ────────────────────────────────────────────────────────────
  def extraire_donnees_bordereau
    ocr_result = call
    texte = ocr_result[:text].to_s

    return { success: false, error: ocr_result[:error] } unless ocr_result[:success]

    uw             = extraire_valeur_thermique(texte, UW_PATTERNS)
    ug             = extraire_valeur_thermique(texte, UG_PATTERNS)
    uf             = extraire_valeur_thermique(texte, UF_PATTERNS)
    g_value        = extraire_valeur_thermique(texte, G_VALUE_PATTERNS)
    type_vitrage   = detecter_type_vitrage(texte)
    type_chassis   = detecter_type_chassis(texte)
    fabricant      = detecter_fabricant(texte)
    reference      = extraire_reference(texte)
    poseur         = extraire_poseur(texte)
    bce_poseur     = extraire_bce_poseur(texte)
    surface        = extraire_surface_chassis(texte)
    nb_unites      = extraire_nombre_unites(texte)
    date_doc       = extraire_date_document(texte)
    numero_doc     = extraire_numero_document(texte)

    detail         = extraire_detail_chassis(texte)
    montant_htva   = extraire_montant_htva_chassis(texte)
    montant_tvac   = extraire_montant_tvac_chassis(texte)
    taux_tva       = extraire_taux_tva_chassis(texte)
    # Affiner nb_unites depuis le détail si non trouvé
    nb_unites    ||= detail.sum { |d| d[:quantite] || 1 } if detail.any?
    # Calculer surface totale depuis les cotes si non trouvée par pattern
    if surface.nil? && detail.any?
      surfaces_detail = detail.filter_map do |d|
        next unless d[:surface_m2].to_f > 0
        d[:surface_m2].to_f * (d[:quantite] || 1)
      end
      surface = surfaces_detail.sum.round(2) if surfaces_detail.any?
    end

    confiance = calculer_confiance(uw, ug, type_vitrage, fabricant, surface, montant_htva)

    {
      success:              true,
      texte_brut:           texte,
      nom_fabricant:        fabricant,
      nom_poseur:           poseur,
      numero_bce_poseur:    bce_poseur,
      reference_produit:    reference,
      valeur_uw:            uw,
      valeur_ug:            ug,
      valeur_uf:            uf,
      facteur_solaire:      g_value,
      type_vitrage:         type_vitrage,
      type_chassis:         type_chassis,
      surface_totale:       surface,
      nombre_unites:        nb_unites,
      date_document:        date_doc,
      numero_document:      numero_doc,
      montant_htva:         montant_htva,
      montant_tvac:         montant_tvac,
      taux_tva:             taux_tva,
      detail_chassis:       detail,
      confiance_extraction: confiance,
      extraction_complete:  confiance >= 60,
      donnees_bordereau: {
        uw: uw, ug: ug, uf: uf, g_value: g_value,
        fabricant: fabricant, type_vitrage: type_vitrage, type_chassis: type_chassis
      }
    }
  rescue StandardError => e
    Rails.logger.error "BordereauChassisOcrService error: #{e.message}\n#{e.backtrace.first(3).join("\n")}"
    { success: false, error: "Erreur lors de l'extraction: #{e.message}" }
  end

  private

  # Extrait une valeur décimale depuis une liste de patterns (renvoie Float ou nil)
  def extraire_valeur_thermique(texte, patterns)
    patterns.each do |pattern|
      if (m = texte.match(pattern))
        val = m[1].tr(',', '.').to_f
        return val if val > 0
      end
    end
    nil
  end

  def detecter_type_vitrage(texte)
    VITRAGE_PATTERNS.each do |type, patterns|
      return type if patterns.any? { |p| texte.match?(p) }
    end
    nil
  end

  def detecter_type_chassis(texte)
    CHASSIS_TYPE_PATTERNS.each do |type, patterns|
      return type if patterns.any? { |p| texte.match?(p) }
    end
    nil
  end

  def detecter_fabricant(texte)
    FABRICANTS_CONNUS.each do |fab|
      return fab if texte.match?(/\b#{Regexp.escape(fab)}\b/i)
    end
    # Fallback : cherche un mot suivi de "chassis" ou "profil"
    if (m = texte.match(/\b([A-Z][A-Za-z]{3,20})\s+(?:profil|châssis|système|system)\b/))
      return m[1]
    end
    nil
  end

  def extraire_reference(texte)
    patterns = [
      /r[eé]f(?:érence)?\s*[.:\-]?\s*([A-Z0-9][\w\-\.\/]{3,30})/i,
      /(?:profil|système|modèle)\s*[:\-]?\s*([A-Z][\w\-]{3,25})/i,
      /article\s*[:\-]?\s*([A-Z0-9][\w\-]{3,25})/i,
    ]
    patterns.each do |p|
      return $1 if texte.match(p)
    end
    nil
  end

  def extraire_poseur(texte)
    patterns = [
      /poseur\s*[:\-]?\s*([A-Z][A-Za-zÀ-ÿ\s\-&]{3,50})/i,
      /installateur\s*[:\-]?\s*([A-Z][A-Za-zÀ-ÿ\s\-&]{3,50})/i,
      /plaatser\s*[:\-]?\s*([A-Z][A-Za-zÀ-ÿ\s\-&]{3,50})/i,
      /entrepreneur\s*[:\-]?\s*([A-Z][A-Za-zÀ-ÿ\s\-&]{3,50})/i,
    ]
    patterns.each do |p|
      return $1.strip if texte.match(p)
    end
    nil
  end

  def extraire_bce_poseur(texte)
    if (m = texte.match(/(?:N[°o]?\s*d['']?entreprise|BCE|BTW|KBO)\s*[:\-]?\s*(BE\s*0?\d{3}[\s\.\-]?\d{3}[\s\.\-]?\d{3})/i))
      m[1].gsub(/[\s\.\-]/, '').upcase
    end
  end

  def extraire_surface_chassis(texte)
    SURFACE_CHASSIS_PATTERNS.each do |p|
      if (m = texte.match(p))
        val = m[1].tr(',', '.').to_f
        return val if val > 0
      end
    end
    nil
  end

  def extraire_nombre_unites(texte)
    UNITES_PATTERNS.each do |p|
      if (m = texte.match(p))
        val = m[1].to_i
        return val if val > 0 && val < 1000
      end
    end
    nil
  end

  def extraire_date_document(texte)
    patterns = [
      /(?:date|datum|le)\s*[:\-]?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.](?:20)?\d{2})/i,
      /(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]20\d{2})/,
    ]
    patterns.each do |p|
      if (m = texte.match(p))
        begin
          return Date.parse(m[1].gsub(/[-\.]/, '/'))
        rescue Date::Error
          next
        end
      end
    end
    nil
  end

  def extraire_numero_document(texte)
    patterns = [
      /(?:bordereau|bon\s+de\s+commande|fiche\s+technique|offre)\s*[n°no]?\s*[:\-]?\s*([A-Z0-9\-\/\.]{3,25})/i,
      /r[eé]f(?:érence)?\s*bordereau\s*[:\-]?\s*([A-Z0-9\-\/\.]{3,25})/i,
      /doc(?:ument)?\s*[n°]\s*[:\-]?\s*([A-Z0-9\-\/\.]{3,20})/i,
    ]
    patterns.each do |p|
      return $1 if texte.match(p)
    end
    nil
  end

  # ── Extraction postes numérotés du bordereau ─────────────────────────────────
  # Format Global Home / Drutex : "N) Description ... Prix HT ... X,XX EUR Y Pc X,XX EUR"
  def extraire_detail_chassis(texte)
    detail = []

    # Pattern principal : "1) Description ... X,XX EUR  Y Pc  X,XX EUR  X,XX EUR"
    pattern = /(\d+)\)\s+(.{5,120}?)\s+(\d+[.,]\d{2})\s*EUR\s+(\d+)\s*Pc\s+(\d+[.,]\d{2})\s*EUR/im
    texte.scan(pattern) do |num, desc, prix_unit, qty, montant|
      desc_clean = desc.gsub(/\s+/, ' ').strip
                       .gsub(/Prix\s+HT.*$/i, '').strip
                       .gsub(/\n/, ' ')[0..120]
      next if desc_clean.length < 3 || desc_clean.match?(/^[\s\d.,]+$/)

      entry = {
        numero:        num.to_i,
        description:   desc_clean,
        prix_unitaire: parse_montant_belge(prix_unit) || prix_unit.tr(',', '.').to_f,
        quantite:      qty.to_i,
        montant_ht:    parse_montant_belge(montant) || montant.tr(',', '.').to_f
      }

      # Extraire dimensions (ex: "2050 x 1866") et calculer surface en m²
      if (dim = desc_clean.match(/(\d{3,4})\s*[xX×]\s*(\d{3,4})/))
        w_mm    = dim[1].to_f
        h_mm    = dim[2].to_f
        surf_m2 = (w_mm * h_mm / 1_000_000.0).round(3)
        if surf_m2 > 0.1 && surf_m2 < 50
          entry[:dimensions] = "#{dim[1]} x #{dim[2]} mm"
          entry[:surface_m2] = surf_m2
        end
      end

      detail << entry
    end

    # Fallback : lignes numérotées avec montant seul (ventilation, services, etc.)
    if detail.empty?
      pattern2 = /^(\d+)\)\s+(.{5,80}?)\s+(\d+[.,]\d{2})\s*EUR/im
      texte.scan(pattern2) do |num, desc, montant|
        desc_clean = desc.gsub(/\s+/, ' ').strip[0..120]
        next if desc_clean.length < 3
        detail << {
          numero:      num.to_i,
          description: desc_clean,
          montant_ht:  parse_montant_belge(montant) || montant.tr(',', '.').to_f
        }
      end
    end

    detail.uniq { |d| d[:numero] }.sort_by { |d| d[:numero] }
  end

  # ── Total HTVA ────────────────────────────────────────────────────────────────
  def extraire_montant_htva_chassis(texte)
    patterns = [
      # "Total général  5 491,07 EUR  0,00 EUR  5 491,07 EUR" → premier montant = HTVA
      /Total\s+g[eé]n[eé]ral[^\n]*\n[^\n]*(\d[\d\s.]*[,]\d{2})\s*EUR/im,
      /Total\s+g[eé]n[eé]ral.*?(\d[\d.,]+)\s*EUR/im,
      /Montant\s+HT\s*\n\s*(\d[\d.,\s]+)\s*EUR/im,
      /SOUS[-\s]?TOTAL\s*[\n\s]*([\d.,\s]+)\s*[€EUR]/i,
      /Total(?:\s+hors\s+TVA|\s+HT)[:\s]+(\d[\d.,\s]+)\s*[€EUR]/i,
    ]
    patterns.each do |p|
      if (m = texte.match(p))
        val = parse_montant_belge(m[1])
        return val if val && val > 0
      end
    end
    nil
  end

  # ── Total TVAC ────────────────────────────────────────────────────────────────
  def extraire_montant_tvac_chassis(texte)
    patterns = [
      # Format Global Home : "Total général  HT  TVA  TTC" → dernier montant = TVAC
      /Total\s+g[eé]n[eé]ral.*?(\d[\d.,\s]+)\s*EUR\s+\d[\d.,\s]*\s*EUR\s+(\d[\d.,\s]+)\s*EUR/im,
      /TOTAL\s+TTC[:\s]*(\d[\d.,\s]+)\s*[€EUR]/i,
      /Total\s+TTC[:\s]*\n?[\s]*(\d[\d.,\s]+)\s*[€EUR]/im,
      /Montant\s+TTC[:\n\s]*(\d[\d.,\s]+)\s*EUR/im,
    ]
    patterns.each do |p|
      if (m = texte.match(p))
        val = parse_montant_belge(m.captures.last)
        return val if val && val > 0
      end
    end
    nil
  end

  # ── Taux TVA ──────────────────────────────────────────────────────────────────
  def extraire_taux_tva_chassis(texte)
    patterns = [
      /TVA\s+(\d+)\s*%/i,
      /(\d+)\s*%\s*(?:de\s+)?TVA/i,
      /BTW\s+(\d+)\s*%/i,
    ]
    patterns.each do |p|
      if (m = texte.match(p))
        val = m[1].to_f
        return val if val >= 0 && val <= 100
      end
    end
    nil
  end

  def calculer_confiance(uw, ug, type_vitrage, fabricant, surface, montant_htva = nil)
    score = 0

    score += 35 if uw.present?          # Uw = champ prime le plus important
    score += 15 if ug.present?          # Ug
    score += 15 if type_vitrage.present? # Type vitrage
    score += 10 if fabricant.present?   # Fabricant
    score += 10 if montant_htva.present? # Montant total extrait
    score += 5  if surface.present?     # Surface
    score += 10 if uw.present? && ug.present? && type_vitrage.present? # Bonus complétude

    score.clamp(0, 100).to_f
  end
end
