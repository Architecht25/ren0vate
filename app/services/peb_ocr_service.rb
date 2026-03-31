class PebOcrService < OcrService
  # ─────────────────────────────────────────────────────────────────────────────
  # Certificat PEB (Performance Energétique des Bâtiments) — 3 régions belges
  # Flandre  : Energieprestatiecertificaat (VEKA)
  # Wallonie : Certificat de Performance Energétique (UNILAB/SPW)
  # Bruxelles: Certificat de Performance Energétique (Bruxelles Environnement)
  # ─────────────────────────────────────────────────────────────────────────────

  # ── Détection de région ──────────────────────────────────────────────────────
  SIGNAL_FLANDRE   = /energieprestatiecertificaat|certificaatnummer|vlaanderen\.be\/epc|bruikbare\s+vloeroppervlakte/i
  SIGNAL_WALLONIE  = /b[aâ]timent\s+r[eé]sidentiel\s+existant|energie\.wallonie\.be|certif-p\d|validit[eé]\s+maximale/i
  SIGNAL_BRUXELLES = /r[eé]gion\s+de\s+bruxelles.capitale|bruxelles\s+environnement|homegrade\.brussels|kwhep\//i

  # ── Numéro de certificat ─────────────────────────────────────────────────────
  # Flandre   : 20240507-0003240119-RES-1
  NUMERO_FLANDRE   = /certificaatnummer\s*:?\s*([0-9]{8}-[0-9]{10}-\w+-\d+)/i
  # Wallonie  : 20170213000118  (peut être sur la ligne suivante après "Numéro :")
  NUMERO_WALLONIE  = /num[eé]ro\s*:\s*[\r\n\s]*(\d{14})/im
  # Bruxelles : 20221005-0000622216-01-8  (idem)
  NUMERO_BRUXELLES = /num[eé]ro\s*:\s*[\r\n\s]*(\d{8}-\d{10}-\d{2}-\d)/im

  # ── Label PEB ────────────────────────────────────────────────────────────────
  # Flandre : "Uw energielabel: F" ou dans le graphique "F" isolé avec contexte
  LABEL_FLANDRE_1  = /uw\s+energielabel\s*:?\s*\n?\s*([A-G][+]{0,2})/i
  LABEL_FLANDRE_2  = /energielabel\s+([A-G][+]{0,2})\b/i
  # Wallonie : "Ce logement obtient une classe G" ou "classe G"
  LABEL_WALLONIE_1 = /logement\s+obtient\s+une\s+classe\s+([A-G][+]{0,2})/i
  LABEL_WALLONIE_2 = /[Cc]lasse\s+([A-G][+]{0,2})\b/
  LABEL_WALLONIE_3 = /E_spec\s*>\s*\d+\s+([A-G][+]{0,2})\s+\d+/
  # Bruxelles : "Classe énergétique" puis lettre
  LABEL_BRUXELLES_1 = /classe\s+[eé]nerg[eé]tique\b.*?([A-G][+]{0,2})\s*\n/im
  LABEL_BRUXELLES_2 = /[Cc]lasse\s+([A-G][+]{0,2})\b/

  # ── Score EP (kWh/m².an) ─────────────────────────────────────────────────────
  # Flandre : "817 kWh / (m² jaar)" ou "Berekende energiescore ... 817"
  SCORE_FLANDRE_1  = /(\d{2,4})\s+kWh\s*\/\s*\(m[²2]\s*jaar\)/i
  SCORE_FLANDRE_2  = /berekende\s+energiescore[^0-9]*(\d{2,4})/i
  # Wallonie : "753 kWh/m²\.an" ou "Consommation spécifique.*753"
  SCORE_WALLONIE_1 = /(\d{2,4})\s+kWh\/m[²2]\.an/i
  SCORE_WALLONIE_2 = /consommation\s+sp[eé]cifique[^0-9]*(\d{2,4})/i
  SCORE_WALLONIE_3 = /E_spec[^0-9]*(\d{2,4})/i
  # Bruxelles : "653 [kWhEP/(m².an)]" ou "annuelle par m² 653"
  SCORE_BRUXELLES_1 = /(\d{2,4})\s+\[kWhEP\/\(m[²2]\.an\)\]/i
  SCORE_BRUXELLES_2 = /annuelle\s+par\s+m[²2]\s+(\d{2,4})/i
  SCORE_BRUXELLES_3 = /(\d{2,4})\s+kWhEP\/\(m[²2]\.an\)/i

  # ── Surface de référence ─────────────────────────────────────────────────────
  SURFACE_FLANDRE   = /oppervlakte[:\s]*(\d{2,4})\s*m[²2]/i
  SURFACE_WALLONIE  = /surface\s+de\s+plancher\s+chauff[eé]e[^0-9]*(\d{2,4})\s*m[²2]/i
  SURFACE_BRUXELLES = /surface\s+brute[^0-9]*(\d{2,4})\s*m[²2]/i

  # ── Dates ────────────────────────────────────────────────────────────────────
  # Flandre  : "Datum: 07-05-2024"
  DATE_CERT_FLANDRE   = /datum\s*:?\s*(\d{1,2}[-\/]\d{1,2}[-\/]\d{4})/i
  DATE_VALID_FLANDRE  = /geldig\s+tot\s+en\s+met\s+(\d{1,2}\s+\w+\s+\d{4})/i
  # Wallonie : "Établi le :  06/03/2017" — É majuscule ne matche pas [eé]/i dans une classe Ruby
  DATE_CERT_WALLONIE  = /tabli\s+le\s*:?\s*(\d{1,2}\/\d{2}\/\d{4})/i
  DATE_VALID_WALLONIE = /validit\S*\s+maximale\s*:?\s*(\d{1,2}\/\d{2}\/\d{4})/i
  # Bruxelles : "valide jusqu'au : 05/10/2032" + "Établi" pour cert
  DATE_VALID_BRUXELLES = /valide\s+jusqu.au\s*:?\s*[\r\n\s]*(\d{1,2}\/\d{2}\/\d{4})/im
  DATE_CERT_BRUXELLES  = /tabli\s+le\s*:?\s*(\d{1,2}\/\d{2}\/\d{4})/i  # même pattern que Wallonie

  MOIS_NL = {
    'januari' => 1, 'februari' => 2, 'maart' => 3, 'april' => 4,
    'mei' => 5, 'juni' => 6, 'juli' => 7, 'augustus' => 8,
    'september' => 9, 'oktober' => 10, 'november' => 11, 'december' => 12
  }.freeze

  # ─────────────────────────────────────────────────────────────────────────────
  # Point d'entrée
  # ─────────────────────────────────────────────────────────────────────────────
  def extraire_donnees_peb
    ocr_result = call
    return { success: false, error: ocr_result[:error] || "Impossible d'extraire le texte du document" } unless ocr_result[:success]

    texte = ocr_result[:text].to_s
    return { success: false, error: "Document vide ou illisible" } if texte.blank?

    region = detecter_region(texte)

    donnees = {
      region:             region,
      numero_certificat:  extraire_numero(texte, region),
      label_peb:          extraire_label(texte, region),
      score_ep:           extraire_score(texte, region),
      surface_reference:  extraire_surface(texte, region),
      date_certificat:    extraire_date_certificat(texte, region),
      date_validite:      extraire_date_validite(texte, region),
      texte_ocr_brut:     texte
    }

    # Fallback label : déduction depuis le score si non trouvé en texte
    # (le label est souvent dans un graphique vectoriel non lisible par pdf-reader)
    if donnees[:label_peb].blank? && donnees[:score_ep].present?
      donnees[:label_peb] = deduire_label_depuis_score(donnees[:score_ep], region)
    end

    confiance = calculer_confiance(donnees)
    donnees[:confiance_ocr]      = confiance
    donnees[:extraction_complete] = champs_cles_presents?(donnees)

    { success: true }.merge(donnees)
  end

  private

  # ── Détection de région ──────────────────────────────────────────────────────
  def detecter_region(texte)
    return 'flandre'   if texte.match?(SIGNAL_FLANDRE)
    return 'wallonie'  if texte.match?(SIGNAL_WALLONIE)
    return 'bruxelles' if texte.match?(SIGNAL_BRUXELLES)
    nil
  end

  # ── Numéro ──────────────────────────────────────────────────────────────────
  def extraire_numero(texte, region)
    case region
    when 'flandre'
      texte.match(NUMERO_FLANDRE)&.captures&.first ||
        texte.match(/(\d{8}-\d{10}-\w{2,5}-\d+)/)&.captures&.first
    when 'wallonie'
      texte.match(NUMERO_WALLONIE)&.captures&.first
    when 'bruxelles'
      texte.match(NUMERO_BRUXELLES)&.captures&.first ||
        texte.match(/num[eé]ro\s*:?\s*(\d{8}-\d{10}-\d{2}-\d)/i)&.captures&.first
    end
  end

  # ── Label PEB ────────────────────────────────────────────────────────────────
  def extraire_label(texte, region)
    raw = case region
    when 'flandre'
      texte.match(LABEL_FLANDRE_1)&.captures&.first ||
        texte.match(LABEL_FLANDRE_2)&.captures&.first
    when 'wallonie'
      texte.match(LABEL_WALLONIE_1)&.captures&.first ||
        texte.match(LABEL_WALLONIE_3)&.captures&.first ||
        texte.match(LABEL_WALLONIE_2)&.captures&.first
    when 'bruxelles'
      texte.match(LABEL_BRUXELLES_1)&.captures&.first ||
        texte.match(LABEL_BRUXELLES_2)&.captures&.first
    end
    label = raw&.strip&.upcase
    PebDonnee::LABELS_VALIDES.include?(label) ? label : nil
  end

  # ── Score EP ────────────────────────────────────────────────────────────────
  def extraire_score(texte, region)
    raw = case region
    when 'flandre'
      texte.match(SCORE_FLANDRE_1)&.captures&.first ||
        texte.match(SCORE_FLANDRE_2)&.captures&.first
    when 'wallonie'
      texte.match(SCORE_WALLONIE_1)&.captures&.first ||
        texte.match(SCORE_WALLONIE_2)&.captures&.first ||
        texte.match(SCORE_WALLONIE_3)&.captures&.first
    when 'bruxelles'
      texte.match(SCORE_BRUXELLES_1)&.captures&.first ||
        texte.match(SCORE_BRUXELLES_2)&.captures&.first ||
        texte.match(SCORE_BRUXELLES_3)&.captures&.first
    end
    val = raw&.to_f
    (val && val > 0 && val < 2000) ? val.round(2) : nil
  end

  # ── Surface ─────────────────────────────────────────────────────────────────
  def extraire_surface(texte, region)
    raw = case region
    when 'flandre'   then texte.match(SURFACE_FLANDRE)&.captures&.first
    when 'wallonie'  then texte.match(SURFACE_WALLONIE)&.captures&.first
    when 'bruxelles' then texte.match(SURFACE_BRUXELLES)&.captures&.first
    end
    val = raw&.to_f
    (val && val > 5 && val < 5000) ? val.round(2) : nil
  end

  # ── Date certificat ──────────────────────────────────────────────────────────
  def extraire_date_certificat(texte, region)
    case region
    when 'flandre'
      raw = texte.match(DATE_CERT_FLANDRE)&.captures&.first
      parse_date_flexible(raw)
    when 'wallonie'
      raw = texte.match(DATE_CERT_WALLONIE)&.captures&.first
      parse_date_slash(raw)
    when 'bruxelles'
      # La date est encodée dans les 8 premiers chiffres du numéro
      raw = texte.match(NUMERO_BRUXELLES)&.captures&.first
      if raw
        d = raw.split('-').first
        parse_date_from_numero(d)
      end
    end
  rescue ArgumentError
    nil
  end

  # ── Date validité ────────────────────────────────────────────────────────────
  def extraire_date_validite(texte, region)
    case region
    when 'flandre'
      raw = texte.match(DATE_VALID_FLANDRE)&.captures&.first
      parse_date_nl(raw)
    when 'wallonie'
      raw = texte.match(DATE_VALID_WALLONIE)&.captures&.first
      parse_date_slash(raw)
    when 'bruxelles'
      raw = texte.match(DATE_VALID_BRUXELLES)&.captures&.first
      parse_date_slash(raw)
    end
  rescue ArgumentError
    nil
  end

  # ── Parsers de dates ─────────────────────────────────────────────────────────
  def parse_date_slash(str)
    return nil unless str
    parts = str.split('/')
    return nil unless parts.size == 3
    Date.new(parts[2].to_i, parts[1].to_i, parts[0].to_i)
  rescue ArgumentError
    nil
  end

  def parse_date_flexible(str)
    return nil unless str
    # "07-05-2024" ou "07/05/2024"
    parts = str.split(/[-\/]/)
    return nil unless parts.size == 3
    Date.new(parts[2].to_i, parts[1].to_i, parts[0].to_i)
  rescue ArgumentError
    nil
  end

  def parse_date_nl(str)
    return nil unless str
    # "7 mei 2034"
    m = str.match(/(\d{1,2})\s+(\w+)\s+(\d{4})/)
    return nil unless m
    mois = MOIS_NL[m[2].downcase]
    return nil unless mois
    Date.new(m[3].to_i, mois, m[1].to_i)
  rescue ArgumentError
    nil
  end

  def parse_date_from_numero(str)
    return nil unless str&.length == 8
    # "20221005" → 2022-10-05
    Date.new(str[0..3].to_i, str[4..5].to_i, str[6..7].to_i)
  rescue ArgumentError
    nil
  end

  # ── Confiance ────────────────────────────────────────────────────────────────
  def calculer_confiance(d)
    score = 0
    score += 25 if d[:region].present?
    score += 20 if d[:label_peb].present?
    score += 20 if d[:score_ep].present?
    score += 15 if d[:numero_certificat].present?
    score += 10 if d[:surface_reference].present?
    score += 5  if d[:date_certificat].present?
    score += 5  if d[:date_validite].present?
    score
  end

  def champs_cles_presents?(d)
    d[:region].present? && d[:label_peb].present? && d[:score_ep].present?
  end

  def resultat_echec(msg)
    { success: false, error: msg }
  end

  # ── Déduction du label depuis le score ───────────────────────────────────────
  # Les seuils Wallonie et Bruxelles sont identiques pour le résidentiel
  # Flandre : label toujours explicite dans le document → pas de déduction
  # Grille officielle Wallonie (et Bruxelles résidentiel) — Réglementation E_spec kWh/m².an
  # Source : certificat PEB wallon officiel
  # A++ : E_spec ≤ 0
  # A+  : 0  < E_spec ≤  45
  # A   : 45 < E_spec ≤  85
  # B   : 85 < E_spec ≤ 170
  # C   : 170< E_spec ≤ 255
  # D   : 255< E_spec ≤ 340
  # E   : 340< E_spec ≤ 425
  # F   : 425< E_spec ≤ 510
  # G   : E_spec > 510
  def deduire_label_depuis_score(score, region)
    return nil unless score && %w[wallonie bruxelles].include?(region)
    val = score.to_f
    if    val <= 0   then 'A++'
    elsif val <= 45  then 'A+'
    elsif val <= 85  then 'A'
    elsif val <= 170 then 'B'
    elsif val <= 255 then 'C'
    elsif val <= 340 then 'D'
    elsif val <= 425 then 'E'
    elsif val <= 510 then 'F'
    else                  'G'
    end
  end
end
