class RibOcrService < OcrService
  # ─────────────────────────────────────────────────────────────────────────────
  # RIB — Relevé d'Identité Bancaire (banques belges)
  # Formats : PDF texte, PDF scanné, JPEG, PNG
  # ─────────────────────────────────────────────────────────────────────────────

  # ── IBAN belge ───────────────────────────────────────────────────────────────
  # Format brut : BE68539007547034 ou avec espaces : BE68 5390 0754 7034
  IBAN_PATTERN = /\bBE\d{2}[\s]?\d{4}[\s]?\d{4}[\s]?\d{4}\b/i

  # ── BIC / SWIFT ──────────────────────────────────────────────────────────────
  BIC_PATTERN = /\b([A-Z]{4}[A-Z]{2}[A-Z0-9]{2}(?:[A-Z0-9]{3})?)\b/

  # ── BIC connus des grandes banques belges (fallback depuis le nom de banque)
  BIC_PAR_BANQUE = {
    /belfius/i        => 'GKCCBEBB',
    /bpost/i          => 'BPOTBEB1',
    /bnp[\s\-]?parib/i => 'GEBABEBB',
    /ing\b/i          => 'BBRUBEBB',
    /kbc\b/i         => 'KREDBEBB',
    /argenta/i        => 'ARSPBE22',
    /axa/i            => 'AXABBE22',
    /fintro/i         => 'NICA BEBB',
    /crelan/i         => 'NICABEBB',
    /vdk/i            => 'VDKBEB1X',
    /triodos/i        => 'TRIOBEBB',
    /nagelmackers/i   => 'BNAGBEBB',
    /deutsche/i       => 'DEUTBEBE',
    /record/i         => 'RBRBBEBB',
  }.freeze

  # ── Nom du titulaire ─────────────────────────────────────────────────────────
  NOM_TITULAIRE_FR = /(?:titulaire|au nom de|bénéficiaire|compte de|nom)\s*[:\-]?\s*([A-ZÀ-Ü][A-Za-zÀ-ü\s\-']{3,50})/i
  NOM_TITULAIRE_NL = /(?:rekeninghouder|naam|op naam van|ten name van)\s*[:\-]?\s*([A-ZÀ-Ü][A-Za-zÀ-ü\s\-']{3,50})/i

  # ── Nom de la banque ─────────────────────────────────────────────────────────
  BANQUES_CONNUES = /belfius|bpost|bnp\s*paribas?|ing\b|kbc\b|argenta|axa|fintro|crelan|vdk|triodos|nagelmackers|deutsche\s*bank|record\s*bank/i

  def initialize(file, language: 'fra+nld')
    super(file, language: language)
  end

  # ── Point d'entrée principal ──────────────────────────────────────────────────
  def extraire_donnees_rib
    ocr_result = call
    return ocr_result unless ocr_result[:success]

    texte = ocr_result[:text].to_s
    donnees = extraire_champs(texte)
    confiance = calculer_confiance_rib(donnees, ocr_result[:confidence])

    ocr_result.merge(
      donnees_rib:          donnees,
      iban:                 donnees[:iban],
      bic:                  donnees[:bic],
      nom_titulaire:        donnees[:nom_titulaire],
      nom_banque:           donnees[:nom_banque],
      confiance_extraction: confiance,
      extraction_complete:  extraction_complete?(donnees),
      texte_brut:           texte
    )
  end

  private

  def extraire_champs(texte)
    iban       = extraire_iban(texte)
    nom_banque = extraire_nom_banque(texte)
    bic        = extraire_bic(texte, nom_banque)

    {
      iban:          iban,
      bic:           bic,
      nom_titulaire: extraire_nom_titulaire(texte),
      nom_banque:    nom_banque,
    }
  end

  # ── IBAN ─────────────────────────────────────────────────────────────────────
  def extraire_iban(texte)
    m = texte.match(IBAN_PATTERN)
    return nil unless m

    # Normaliser : supprimer espaces, mettre en majuscules
    iban_brut = m[0].gsub(/\s/, '').upcase
    valider_iban_belge(iban_brut) ? iban_brut : nil
  end

  # Validation IBAN belge : BE + 2 chiffres clé + 12 chiffres BBAN
  # Vérifie aussi le modulo 97 (norme ISO 13616)
  def valider_iban_belge(iban)
    return false unless iban.match?(/\ABE\d{14}\z/)

    # Modulo 97 : déplacer les 4 premiers caractères à la fin, convertir lettres en chiffres
    rearranged = iban[4..] + iban[0..3]
    numeric = rearranged.chars.map { |c| c =~ /[A-Z]/ ? (c.ord - 55).to_s : c }.join
    numeric.to_i % 97 == 1
  end

  # ── BIC ──────────────────────────────────────────────────────────────────────
  def extraire_bic(texte, nom_banque)
    # 1. Chercher dans le texte
    texte.scan(BIC_PATTERN).flatten.each do |candidat|
      # Exclure les faux positifs (sigles courants non-BIC)
      next if candidat.length < 8
      next if %w[IBAN SEPA BBAN].include?(candidat)

      return candidat if candidat.length.between?(8, 11)
    end

    # 2. Fallback : déduire depuis le nom de la banque
    return nil if nom_banque.blank?

    BIC_PAR_BANQUE.each do |pattern, bic|
      return bic if nom_banque.match?(pattern)
    end

    nil
  end

  # ── Nom du titulaire ─────────────────────────────────────────────────────────
  def extraire_nom_titulaire(texte)
    m = texte.match(NOM_TITULAIRE_FR) || texte.match(NOM_TITULAIRE_NL)
    m&.captures&.first&.strip&.squeeze(' ')
  end

  # ── Nom de la banque ─────────────────────────────────────────────────────────
  def extraire_nom_banque(texte)
    m = texte.match(BANQUES_CONNUES)
    m&.[](0)&.strip&.split&.map(&:capitalize)&.join(' ')
  end

  # ── Score de confiance RIB ───────────────────────────────────────────────────
  def calculer_confiance_rib(donnees, confiance_ocr_base)
    score = (confiance_ocr_base || 50).to_f

    score += 40 if donnees[:iban].present?      # IBAN est le champ critique
    score += 15 if donnees[:bic].present?
    score += 10 if donnees[:nom_titulaire].present?
    score += 5  if donnees[:nom_banque].present?
    score -= 30 if donnees[:iban].nil?           # sans IBAN le RIB est inutile

    score.clamp(0, 100).round(1)
  end

  def extraction_complete?(donnees)
    donnees[:iban].present?
  end
end
