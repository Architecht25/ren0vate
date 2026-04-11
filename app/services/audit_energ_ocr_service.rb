class AuditEnergOcrService < OcrService
  # ─────────────────────────────────────────────────────────────────────────────
  # Rapport d'Audit Logement Wallonie (SPW / Walloreno)
  # Format : PDF multi-pages produit par le logiciel Audit Logement v3.x
  # ─────────────────────────────────────────────────────────────────────────────

  # ── Signal de détection ──────────────────────────────────────────────────────
  SIGNAL_AUDIT_WALLORENO = /rapport\s+d.audit\s+logement|walloreno|audit\s+n[°o]\s*:\s*A\d+|auditeur\s+agr[eé][eé]/i

  # ── Identification (page 2) ──────────────────────────────────────────────────
  NUMERO_AUDIT       = /Audit\s+n[°o]\s*:?\s*(A[\d]+\/\d+)/i
  DATE_ENREGISTREMENT = /Date\s+d.enregistrement\s*:?\s*(\d{1,2}[.\/-]\d{2}[.\/-]\d{4})/i
  DATE_MODIFICATION  = /Date\s+de\s+modification\s*:?\s*(\d{1,2}[.\/-]\d{2}[.\/-]\d{4})/i

  NUMERO_PAE         = /Auditeur\s+agr[eé][eé]\s+n[°o]\s*:?\s*(PAE[\w-]+)/i
  DENOMINATION_AUDIT = /D[eé]nomination\s*:?\s*(.+)/i
  SIEGE_AUDIT        = /Si[eè]ge\s+social\s*:?\s*(.+)/i
  NUM_AUDITEUR       = /N[°o]\s*:?\s*(\d{1,6})\s*\n?\s*Boîte/i
  CP_AUDITEUR        = /CP\s*:?\s*(\d{4})\s*\n?\s*Localit[eé]\s*:?\s*(.+)/i

  # ── Ligne de bouquet ─────────────────────────────────────────────────────────
  # Format : "Bouquet   1"  ou  "Bouquet  (1)"
  BOUQUET_HEADER = /Bouquet\s+\(?(\d+)\)?/i

  # ─────────────────────────────────────────────────────────────────────────────
  # Point d'entrée public
  # ─────────────────────────────────────────────────────────────────────────────
  def extraire_donnees_audit
    ocr_result = call
    unless ocr_result[:success]
      return { success: false, error: ocr_result[:error] || "Impossible d'extraire le texte" }
    end

    texte = ocr_result[:text].to_s
    return { success: false, error: "Document vide ou illisible" } if texte.blank?

    # Normaliser les espaces insécables, tirets conditionnels, etc.
    texte = normaliser_texte(texte)

    unless audit_walloreno?(texte)
      return { success: false, error: "Document non reconnu comme Audit Logement Wallonie" }
    end

    donnees = {
      # Identification
      numero_audit:         extraire_numero_audit(texte),
      date_enregistrement:  extraire_date_enregistrement(texte),
      numero_pae:           extraire_numero_pae(texte),
      denomination_auditeur: extraire_denomination_auditeur(texte),
      adresse_auditeur:     extraire_adresse_auditeur(texte),

      # Labels
      label_initial:        extraire_label_initial(texte),
      label_final:          extraire_label_final(texte),

      # Recommandations bouquets (pages 18-21)
      recommandations_json: extraire_recommandations(texte),

      # Bilan scénario complet (page 21)
      bilan_json:           extraire_bilan(texte),

      # Brut
      texte_ocr_brut: texte
    }

    confiance = calculer_confiance(donnees)
    donnees[:confiance_ocr]       = confiance
    donnees[:extraction_complete] = champs_cles_presents?(donnees)

    { success: true }.merge(donnees)
  end

  private

  # ── Normalisation ─────────────────────────────────────────────────────────────
  def normaliser_texte(texte)
    texte
      .gsub("\u00AD", '-')       # tiret conditionnel → tiret
      .gsub("\u00A0", ' ')       # espace insécable → espace
      .gsub("\u202F", ' ')       # espace fine insécable → espace
      .gsub(/\r\n/, "\n")
      .gsub(/\r/, "\n")
  end

  # ── Détection ────────────────────────────────────────────────────────────────
  def audit_walloreno?(texte)
    texte.match?(SIGNAL_AUDIT_WALLORENO)
  end

  # ── Identification ───────────────────────────────────────────────────────────
  def extraire_numero_audit(texte)
    texte.match(NUMERO_AUDIT)&.captures&.first&.strip
  end

  def extraire_date_enregistrement(texte)
    raw = texte.match(DATE_ENREGISTREMENT)&.captures&.first
    parse_date_audit(raw)
  end

  def extraire_numero_pae(texte)
    texte.match(NUMERO_PAE)&.captures&.first&.strip
  end

  def extraire_denomination_auditeur(texte)
    texte.match(DENOMINATION_AUDIT)&.captures&.first&.strip&.truncate(150)
  end

  def extraire_adresse_auditeur(texte)
    # Cherche le bloc auditeur : "Siège social : Allée des Renards\nN° : 25\nCP : 5170\nLocalité : Profondeville"
    siege = texte.match(SIEGE_AUDIT)&.captures&.first&.strip
    cp_match = texte.match(CP_AUDITEUR)
    cp        = cp_match&.captures&.first
    localite  = cp_match&.captures&.last&.strip&.split("\n")&.first&.strip

    parts = [siege, cp && localite ? "#{cp} #{localite}" : nil].compact_blank
    parts.join(', ').presence
  end

  # ── Labels ───────────────────────────────────────────────────────────────────
  def extraire_label_initial(texte)
    # Case-sensitive : les en-têtes de tableaux utilisent "Label" (minuscule) →
    # on ne match que "LABEL" majuscule pour éviter "Label          Gain réel"
    # Premier match = situation initiale (colonne la plus à gauche)
    label = texte.match(/LABEL\s+([A-G][+]{0,2})/)&.captures&.first&.upcase&.strip
    valider_label(label)
  end

  def extraire_label_final(texte)
    # Scan case-sensitive — tous les LABEL majuscules de la feuille de route
    # (F, E, A, A, A+) → le dernier est l'objectif
    matches = texte.scan(/LABEL\s+([A-G][+]{0,2})/).flatten
    label = matches.last&.upcase&.strip
    valider_label(label)
  end

  def valider_label(label)
    AuditEnergDonnee::LABELS_VALIDES.include?(label) ? label : nil
  end

  # ── Recommandations (pages 18-21) ────────────────────────────────────────────
  def extraire_recommandations(texte)
    recommandations = []

    bouquet_positions = []
    texte.scan(/#{BOUQUET_HEADER.source}/i) do
      bouquet_positions << [$~[1].to_i, $~.begin(0)]
    end
    return [] if bouquet_positions.empty?

    bouquet_positions.each_with_index do |(numero, debut), idx|
      fin  = bouquet_positions[idx + 1]&.last || texte.length
      bloc = texte[debut...fin]

      bloc.each_line do |ligne|
        reco = parser_ligne_reco(ligne, numero)
        recommandations << reco if reco
      end
    end

    recommandations
  end

  # ── Parser une ligne de recommandation ──────────────────────────────────────
  # Le texte OCR du tableau est en colonnes séparées par de nombreux espaces.
  # Stratégie :
  #   1. Normaliser les 2+ espaces en séparateur \t
  #   2. Détecter le type : énergie (contient kWh) ou structurel (finit par "-  NNN")
  #   3. Extraire référence, texte de reco, et nombres finaux
  def parser_ligne_reco(ligne, bouquet_numero)
    return nil if ligne.length < 15
    # Filtres : en-têtes et lignes inutiles
    return nil if ligne.match?(/^\s*U\s*\[W\/m/i)
    return nil if ligne.match?(/^\s*[\d,.]+(?:\s+[\d,.]+)?\s*$/)  # valeurs U seules
    return nil if ligne.match?(/R[eé]f[eé]rence|pertes\s+en\s+%|gain\s+r[eé]el|gain\s+std/i)
    return nil if ligne.match?(/AVANT\s+AM[EÉ]LIORATION|APR[EÈ]S\s+AM[EÉ]LIORATION/i)

    has_kwh        = ligne.match?(/\bkWh\s*$/i) || ligne.scan(/\bkWh\b/i).size >= 2
    has_structural = ligne.match?(/\s-\s+\d+\s*$/)

    return nil unless has_kwh || has_structural

    # Normaliser : 2+ espaces → tabulation comme séparateur de colonnes
    parts = ligne.strip.gsub(/\s{2,}/, "\t").split("\t").map(&:strip).reject(&:blank?)
    return nil if parts.size < 2
    return nil unless parts.first.match?(/^\p{L}/)

    if has_kwh
      # Indices des parts qui se terminent par "kWh"
      kwh_idxs = parts.each_index.select { |i| parts[i].match?(/kWh\s*$/i) }
      return nil if kwh_idxs.empty?

      first_kwh  = kwh_idxs.first
      second_kwh = kwh_idxs[1] || first_kwh

      before_kwh    = parts[0...first_kwh]
      after_second  = parts[(second_kwh + 1)..]

      # Référence : premier token court qui ne ressemble pas à une phrase
      first_token = before_kwh.first.to_s
      ref = (first_token.length <= 35 &&
             !first_token.match?(/^(Faire|Proc|Rendre|Assurer|Installer|Placer|Am[eé]liorer|Viabiliser)/i)) ? first_token : nil

      # Texte de recommandation : partie la plus longue avant kWh
      text_candidates = before_kwh[(ref ? 1 : 0)..]
        .reject { |p| p.match?(/Rendement|^\d+$|^[\d,.]+\s*%$|^[\d,.]+$|kWh\//i) }
      reco_text = text_candidates.max_by(&:length)&.strip.to_s
      return nil if reco_text.length < 5

      # Gain réel kWh
      gain_reel = nettoyer_nombre(parts[first_kwh])

      # 4 derniers nombres après le 2ème kWh : économie, coût, subsides, retour
      num_parts = after_second.select { |p| p.match?(/^[\d\s>]+$/) && p.match?(/\d/) }
      nums = num_parts.map { |n| n.gsub(/\s/, '').to_i }
      retour_raw = after_second.last.to_s.strip
      retour_val = retour_raw.match?(/^\d+|>\s*\d+/) ? retour_raw : nil

      {
        bouquet:          bouquet_numero,
        reference:        ref,
        recommandation:   reco_text.truncate(200),
        gain_reel_kwh:    gain_reel,
        economie_euro_an: nums[-4],
        cout_estime_euro: nums[-3],
        subsides_euro:    nums[-2],
        temps_retour_ans: retour_val
      }
    else
      # Ligne structurelle : se termine par "- NNN" (subsides seulement)
      return nil if parts.size < 3
      return nil unless parts[-2] == '-' && parts.last.match?(/^\d+$/)

      text_parts = parts[0..-3]
      first_token = text_parts.first.to_s
      ref = (first_token.match?(/^[A-Za-z]/) && first_token.length <= 10) ? text_parts.shift : nil
      reco_text = text_parts.join(' ').strip
      return nil if reco_text.length < 5

      {
        bouquet:          bouquet_numero,
        reference:        ref,
        recommandation:   reco_text.truncate(200),
        gain_reel_kwh:    nil,
        economie_euro_an: nil,
        cout_estime_euro: nil,
        subsides_euro:    nettoyer_nombre(parts.last),
        temps_retour_ans: nil
      }
    end
  rescue StandardError
    nil
  end

  # ── Bilan scénario complet ───────────────────────────────────────────────────
  # Ligne type : "     Scénario complet    [espaces]    13 637     37 207      7 401        2"
  # [\ d\s]+ greedy avalerait tout — on normalise par tabs puis on extrait les nums
  def extraire_bilan(texte)
    line = texte.each_line.find { |l| l.match?(/sc[eé]nario\s+complet/i) }
    return {} unless line

    parts    = line.strip.gsub(/\s{2,}/, "\t").split("\t").map(&:strip).reject(&:blank?)
    num_parts = parts.select { |p| p.match?(/^\d[\d ]*$/) }  # ex: "13 637", "2"
    nums     = num_parts.map { |n| n.gsub(' ', '').to_i }.select { |n| n > 0 }

    return {} if nums.size < 2

    {
      economie_an:    nums[-4],
      cout_total:     nums[-3],
      subsides_total: nums[-2],
      temps_retour:   nums.last
    }
  rescue StandardError
    {}
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────
  def nettoyer_nombre(str)
    str.to_s.gsub(/\s/, '').to_i
  end

  def parse_date_audit(str)
    return nil unless str
    # Formats possibles : "07.06.2023"  "07/06/2023"  "07-06-2023"
    parts = str.split(/[.\/-]/)
    return nil unless parts.size == 3
    if parts[2].length == 4
      Date.new(parts[2].to_i, parts[1].to_i, parts[0].to_i)
    else
      # Format ISO : 2023-06-07
      Date.new(parts[0].to_i, parts[1].to_i, parts[2].to_i)
    end
  rescue ArgumentError
    nil
  end

  def calculer_confiance(d)
    score = 0
    score += 25 if d[:numero_audit].present?
    score += 20 if d[:date_enregistrement].present?
    score += 20 if d[:numero_pae].present?
    score += 15 if d[:denomination_auditeur].present?
    score += 10 if d[:recommandations_json]&.any?
    score += 10 if d[:label_initial].present?
    score
  end

  def champs_cles_presents?(d)
    d[:numero_audit].present? && d[:numero_pae].present? && d[:date_enregistrement].present?
  end
end
