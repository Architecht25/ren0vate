class LabelEnergetiqueOcrService < OcrService
  # ─────────────────────────────────────────────────────────────────────────────
  # Label énergétique européen (directive ErP/2010/30/UE puis 2017/1369/UE)
  # S'applique aux appareils électroménagers, chauffe-eau thermodynamiques (CET),
  # pompes à chaleur, etc.
  # L'étiquette est typiquement une photo : on lit la lettre de classe, le COP
  # (ou SCOP/COP ECS), la capacité (en L pour les CET) et le modèle.
  # Langues : français + néerlandais (Belgique), + anglais pour les fiches prod.
  # ─────────────────────────────────────────────────────────────────────────────

  # ── Classe énergétique (A+++ … G) ──────────────────────────────────────────
  # Sur l'étiquette réglementaire la lettre est en gros caractères, souvent
  # précédée de « Classe » ou isolée, éventuellement avec des « + »
  LABEL_CLASSE_EXPLICIT = /\bclasse\s+[eé]nerg[eé]tique\s*[:\-]?\s*([A-G][+]{0,3})(?![A-Za-z0-9+])/i
  LABEL_CLASSE_NL       = /\benergieclass[ae]\s*[:\-]?\s*([A-G][+]{0,3})(?![A-Za-z0-9+])/i
  LABEL_CLASSE_ARROW    = /(?<![A-Za-z0-9])([A-G][+]{0,3})\s*(?:>>>|→|=>|►|\|)/i  # flèche sur étiquette
  # \b ne fonctionne pas après + (non-word char) → utiliser lookbehind/lookahead
  LABEL_CLASSE_ISOLEE   = /(?<![A-Za-z0-9])([A-G]\+{1,3})(?![A-Za-z0-9+])|(?<![A-Za-z0-9\+])([A-G])(?![A-Za-z0-9+])/

  # ── COP / SCOP / COP ECS ────────────────────────────────────────────────────
  # Chauffe-eau thermo : « COP » ou « COP ECS » ou « COPdhw »
  COP_LABEL_FR   = /\bCOP\s*(?:ECS|eau\s+chaude|DHW)?\s*[:\-=]?\s*(\d+(?:[.,]\d{1,2})?)\b/i
  COP_LABEL_NL   = /\bCOP\s*(?:SWW|warmwater)?\s*[:\-=]?\s*(\d+(?:[.,]\d{1,2})?)\b/i
  SCOP_LABEL     = /\bSCOP\s*[:\-=]?\s*(\d+(?:[.,]\d{1,2})?)\b/i
  # Fiche produit : "Coefficient de performance : 3,2"
  COP_FICHE      = /coefficient\s+de\s+performance\s*[:\-=]?\s*(\d+(?:[.,]\d{1,2})?)/i

  # ── Capacité stockage (CET uniquement, en litres) ──────────────────────────
  CAPACITE_FR  = /\bcapacit[eé]\s*[:\-=]?\s*(\d{2,4})\s*(?:l|litre?s?)\b/i
  CAPACITE_NL  = /\binhoud\s*[:\-=]?\s*(\d{2,4})\s*(?:l|liter)\b/i
  CAPACITE_ISO = /(\d{2,4})\s*l\b/i   # fallback : nombre suivi de « L »

  # ── Profil de soutirage / load profile (A–XL) ──────────────────────────────
  PROFIL_FR = /profil\s+(?:de\s+soutirage|de\s+charge)\s*[:\-]?\s*([A-Z]{1,2})\b/i
  PROFIL_NL = /(?:tapprofi|belastingsprofiel)\s*[:\-]?\s*([A-Z]{1,2})\b/i

  # ── Bruit (dB) ─────────────────────────────────────────────────────────────
  BRUIT = /(\d{2})\s*dB/i

  # ── Marque / modèle ─────────────────────────────────────────────────────────
  # Souvent sur la première ligne en majuscules ou après "Marque :"
  MARQUE_FR    = /(?:marque|fabricant|brand)\s*[:\-]?\s*([A-Za-z0-9][A-Za-z0-9\s\-]{1,40})/i
  MODELE_FR    = /(?:mod[eè]le?|type|réf(?:érence)?)\s*[:\-]?\s*([A-Za-z0-9][A-Za-z0-9\s\-_\/\.]{1,50})/i
  # Référence produit brute style "EHVX08S23EA6V / ERGA06EAV3" (première ligne alphanumérique longue)
  REF_PRODUIT  = /\b([A-Z]{2,}[0-9A-Z\-\/]{6,})\b/

  # ── Consommation annuelle (kWh) ─────────────────────────────────────────────
  CONSO_KWH = /consommation\s+(?:ann(?:uelle|uel)|d.(?:énergie|energie))\s*[:\-=]?\s*(\d{1,5}(?:[.,]\d{1,2})?)\s*kWh/i

  # ─────────────────────────────────────────────────────────────────────────────
  # Point d'entrée
  # ─────────────────────────────────────────────────────────────────────────────
  def extraire_donnees_label
    ocr_result = call
    return { success: false, error: ocr_result[:error] || "Impossible de lire le document" } unless ocr_result[:success]

    texte = ocr_result[:text].to_s
    return { success: false, error: "Document vide ou illisible" } if texte.blank?

    donnees = extraire_champs(texte)
    confiance = calculer_confiance(donnees, ocr_result[:confidence])

    ocr_result.merge(
      label_classe:          donnees[:label_classe],
      cop:                   donnees[:cop],
      capacite:              donnees[:capacite],
      profil_soutirage:      donnees[:profil_soutirage],
      bruit_db:              donnees[:bruit_db],
      marque:                donnees[:marque],
      modele:                donnees[:modele],
      consommation_annuelle: donnees[:consommation_annuelle],
      confiance_ocr:         confiance,
      extraction_complete:   donnees[:label_classe].present?,
      texte_ocr_brut:        texte
    )
  end

  private

  # ─────────────────────────────────────────────────────────────────────────────
  # Extraction des champs
  # ─────────────────────────────────────────────────────────────────────────────
  def extraire_champs(texte)
    {
      label_classe:          extraire_label_classe(texte),
      cop:                   extraire_cop(texte),
      capacite:              extraire_capacite(texte),
      profil_soutirage:      extraire_profil(texte),
      bruit_db:              texte.match(BRUIT)&.captures&.first&.to_i,
      marque:                extraire_marque(texte),
      modele:                extraire_modele(texte) || extraire_ref_produit(texte),
      consommation_annuelle: extraire_conso(texte)
    }
  end

  # ── Label de classe ─────────────────────────────────────────────────────────
  def extraire_label_classe(texte)
    texte_norm = normaliser_texte_pour_label(texte)

    # Priorité : mention explicite "Classe énergétique A+"
    m = texte_norm.match(LABEL_CLASSE_EXPLICIT) ||
        texte_norm.match(LABEL_CLASSE_NL)       ||
        texte_norm.match(LABEL_CLASSE_ARROW)
    return normaliser_label(m.captures.compact.first) if m

    # Fallback : scan de toutes les lettres A–G éventuellement suivies de +
    candidats = texte_norm.scan(LABEL_CLASSE_ISOLEE).flatten.compact.uniq
    return nil if candidats.empty?

    normalises = candidats.map { |c| normaliser_label(c) }.compact
    return nil if normalises.empty?

    # Parmi les labels avec +, prendre le plus élevé
    avec_plus = normalises.select { |c| c.include?('+') }
    return avec_plus.max_by { |c| score_label(c) } if avec_plus.any?

    normalises.max_by { |c| score_label(c) }
  end

  # Normalise le texte brut pour reconstruire les labels multi-lignes
  # Problème fréquent avec PDF : "A++" s'extrait en "A +" sur une ligne et "++" sur la suivante
  def normaliser_texte_pour_label(texte)
    # 1. Coller les lignes ne contenant que des "+" avec le label A-G de la ligne précédente
    #    "A +\n  ++" → "A+++"
    t = texte.gsub(/([A-G])[ \t]*(\+{0,3})[ \t]*\n[ \t]*(\+{1,3})[ \t]*(?=\n|$)/) do
      "#{$1}#{$2}#{$3}"
    end
    # 2. Supprimer les espaces résiduels entre la lettre A-G et ses signes "+"
    #    "A ++" → "A++"
    t.gsub(/([A-G])[ \t]+(\+{1,3})(?=[ \t\n]|$)/, '\1\2')
  end

  # Normalise "a++", "A ++" -> "A++"
  def normaliser_label(str)
    return nil unless str.present?
    s = str.strip.upcase.gsub(/\s+/, '')
    s if s.match?(/\A[A-G][+]{0,3}\z/)
  end

  # Score pour comparer les labels (A+++ > A++ > A+ > A > B > … > G)
  def score_label(label)
    return 0 unless label
    lettre = label[0]
    plus   = label.count('+')
    base   = ('G'.ord - lettre.ord)   # A=6, B=5, … G=0
    base * 10 + plus
  end

  # ── COP ─────────────────────────────────────────────────────────────────────
  def extraire_cop(texte)
    raw = texte.match(COP_LABEL_FR)&.captures&.first  ||
          texte.match(COP_LABEL_NL)&.captures&.first  ||
          texte.match(SCOP_LABEL)&.captures&.first     ||
          texte.match(COP_FICHE)&.captures&.first
    return nil unless raw

    val = raw.gsub(',', '.').to_f
    val.between?(1.0, 10.0) ? val.round(2) : nil
  end

  # ── Capacité (L) ────────────────────────────────────────────────────────────
  def extraire_capacite(texte)
    raw = texte.match(CAPACITE_FR)&.captures&.first ||
          texte.match(CAPACITE_NL)&.captures&.first

    # Fallback : chercher le premier nombre « raisonnable » suivi de L
    unless raw
      raw = texte.scan(CAPACITE_ISO).flatten.first
    end

    return nil unless raw
    val = raw.to_i
    val.between?(30, 3000) ? val : nil
  end

  # ── Profil de soutirage ─────────────────────────────────────────────────────
  def extraire_profil(texte)
    texte.match(PROFIL_FR)&.captures&.first ||
      texte.match(PROFIL_NL)&.captures&.first
  end

  # ── Marque ──────────────────────────────────────────────────────────────────
  def extraire_marque(texte)
    texte.match(MARQUE_FR)&.captures&.first&.strip
  end

  # ── Modèle ──────────────────────────────────────────────────────────────────
  def extraire_modele(texte)
    texte.match(MODELE_FR)&.captures&.first&.strip
  end

  # ── Référence produit brute (ex: EHVX08S23EA6V / ERGA06EAV3) ───────────────
  def extraire_ref_produit(texte)
    texte.match(REF_PRODUIT)&.captures&.first&.strip
  end

  # ── Consommation annuelle ───────────────────────────────────────────────────
  def extraire_conso(texte)
    raw = texte.match(CONSO_KWH)&.captures&.first
    raw&.gsub(',', '.')&.to_f
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Confiance d'extraction (0–100)
  # ─────────────────────────────────────────────────────────────────────────────
  def calculer_confiance(donnees, ocr_confidence)
    base = (ocr_confidence || 50).to_f

    # Points par champ trouvé
    score = 0
    score += 40 if donnees[:label_classe].present?
    score += 25 if donnees[:cop].present?
    score += 15 if donnees[:capacite].present?
    score += 10 if donnees[:marque].present? || donnees[:modele].present?
    score += 10 if donnees[:profil_soutirage].present? || donnees[:consommation_annuelle].present?

    # Combiner la confiance OCR et les champs trouvés
    ((base * 0.4) + (score * 0.6)).round(1).clamp(0, 100)
  end
end
