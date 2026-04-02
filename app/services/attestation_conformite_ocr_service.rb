class AttestationConformiteOcrService < OcrService
  # ─────────────────────────────────────────────────────────────────────────────
  # Attestation de conformité électrique RGIE/AREI — Belgique
  # Documents bilingues fr/nl émis par les organismes de contrôle agréés EDTC/SECT
  # Exemples : ELECTROTEST, Vinçotte-ACEG, APAVE, BTV, Kema, Bureau Veritas
  # ─────────────────────────────────────────────────────────────────────────────

  # Signal de détection : le document est bien une attestation RGIE/AREI
  SIGNAL_RGIE = /AREI|RGIE|gelijkvormigheidsonderzoek|controle\s+de\s+conformit[eé]|
                  verslag\s+van\s+onderzoek|rapport\s+de\s+contr[oô]le|
                  erkend\s+controleorganisme|organisme\s+de\s+contr[oô]le\s+agr[eé][eé]/ix

  # ── Organismes belges agréés EDTC connus ──────────────────────────────────
  ORGANISMES_CONNUS = %w[
    ELECTROTEST Vinçotte Vincotte ACEG APAVE BTV KEMA Volta
    AIB-Vinçotte AIBVinçotte Socotec Electrabel Technifutur Agoria
    Electro-Test
  ].freeze

  # ── Signatures internes (codes de templates propres à chaque organisme) ────
  # Utile quand le nom n'est pas extractible (logo graphique).
  SIGNATURES_ORGANISME = {
    /RAPP\.ELS/i  => 'ELECTROTEST',
    /F-ELS\d+/i  => 'ELECTROTEST',
    /RAPP\.VIN/i => 'Vinçotte',
    /RAPP\.APV/i => 'APAVE',
    /RAPP\.BTV/i => 'BTV',
  }.freeze

  # ── Numéro de rapport ─────────────────────────────────────────────────────
  # Le groupe capturé doit commencer par un chiffre pour éviter de capturer
  # des mots comme "Date" ou "Datum" dans les tableaux bilingues.
  NUMERO_FR = /n[°º]\s+de\s+rapport\s*:?\s*(\d[\d\/\-\.A-Z]*)/i
  NUMERO_NL = /verslagnummer\s*:?\s*(\d[\d\/\-\.A-Z]*)/i

  # ── Date de visite/contrôle ───────────────────────────────────────────────
  DATE_VISITE_FR = /date\s+de\s+visite\s*:?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i
  DATE_VISITE_NL = /datum\s+van\s+bezoek\s*:?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i

  # ── Résultat de contrôle ──────────────────────────────────────────────────
  # Conforme
  CONFORME_FR  = /l.installation\s+[eé]lectrique\s+est\s+conforme/i
  CONFORME_NL  = /elektrische\s+installatie\s+voldoet\s+aan\s+de\s+voorschriften/i
  # Conforme avec remarques
  REMARQUES_FR = /conforme\s+(?:sous\s+r[eé]serve|avec\s+(?:remarques?|observations?))/i
  REMARQUES_NL = /conform\s+(?:met\s+(?:opmerkingen?|voorbehoud))/i
  # Non conforme
  NON_CONFORME_FR = /non[.\s\-]conforme|d[eé]favorable|refus[eé]|\brefus\b/i
  NON_CONFORME_NL = /niet[.\s\-]conform|afgekeurd|ongunstig|\bniet\s+in\s+orde\b/i

  # ── Prochaine date de contrôle ────────────────────────────────────────────
  PROCHAIN_FR = /prochain\s+contr[oô]le.*?avant\s+le\s*:?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/im
  PROCHAIN_NL = /volgende\s+controle.*?v[oó][oó]r\s*:?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/im

  # ── Installateur ──────────────────────────────────────────────────────────
  INSTALLATEUR_FR = /installateur\s*:?\s*\n?\s*([A-Z][A-Za-zÀ-ÿ\s\-\.&']+?)(?:\s+(?:BTW|TVA|BE\s*0)|[\r\n])/i
  INSTALLATEUR_NL = /installateur\s*:?\s*\n?\s*([A-Z][A-Za-zÀ-ÿ\s\-\.&']+?)(?:\s+(?:BTW|TVA|BE\s*0)|[\r\n])/i

  # ── Type de contrôle ──────────────────────────────────────────────────────
  TYPE_FR = /controle\s+de\s+conformit[eé]\s+(?:avant\s+mise\s+en\s+usage\s+)?([^(\n]{5,60})/i
  TYPE_NL = /gelijkvormigheidsonderzoek\s+(?:voor\s+de\s+ingebruikname\s+)?([^(\n]{5,60})/i

  # ─────────────────────────────────────────────────────────────────────────────
  # MÉTHODE PRINCIPALE
  # ─────────────────────────────────────────────────────────────────────────────
  def extraire_donnees_attestation
    ocr_result = call
    return { success: false, error: ocr_result[:error] || "Impossible d'extraire le texte du document" } unless ocr_result[:success]

    texte = ocr_result[:text].to_s
    return { success: false, error: "Document vide ou illisible" } if texte.blank?

    unless texte.match?(SIGNAL_RGIE)
      return { success: false, error: "Ce document ne semble pas être une attestation de conformité RGIE/AREI." }
    end

    donnees = {
      numero_rapport:         extraire_numero(texte),
      organisme_controleur:   extraire_organisme(texte),
      date_controle:          extraire_date_controle(texte),
      resultat:               extraire_resultat(texte),
      date_prochain_controle: extraire_date_prochain(texte),
      installateur:           extraire_installateur(texte),
      type_controle:          extraire_type_controle(texte),
      texte_ocr_brut:         texte
    }

    donnees[:confiance_ocr]       = calculer_confiance(donnees)
    donnees[:extraction_complete] = %i[organisme_controleur date_controle resultat].all? { |k| donnees[k].present? }

    { success: true }.merge(donnees)
  end

  private

  def extraire_numero(texte)
    (texte.match(NUMERO_FR) || texte.match(NUMERO_NL))&.captures&.first&.strip
  end

  def extraire_organisme(texte)
    # 0. Signatures internes (codes de templates) — logo souvent graphique
    SIGNATURES_ORGANISME.each do |pattern, nom|
      return nom if texte.match?(pattern)
    end

    # 1. Recherche directe parmi les organismes connus
    ORGANISMES_CONNUS.each do |org|
      return org if texte.match?(/\b#{Regexp.escape(org)}\b/i)
    end

    # 2. Extraction depuis le contexte "Erkend Controleorganisme XXXX"
    m = texte.match(/erkend\s+controleorganisme\s+(\w+)/i)
    return m.captures.first.strip if m

    # 3. Extraction depuis "Organisme de Contrôle Agréé XXXX"
    m = texte.match(/organisme\s+de\s+contr[oô]le\s+agr[eé][eé]\s+(\w+)/i)
    return m.captures.first.strip if m

    nil
  end

  def extraire_date_controle(texte)
    str = (texte.match(DATE_VISITE_FR) || texte.match(DATE_VISITE_NL))&.captures&.first
    parse_date_belge(str)
  end

  def extraire_resultat(texte)
    return 'non_conforme'             if texte.match?(NON_CONFORME_FR) || texte.match?(NON_CONFORME_NL)
    return 'conforme_avec_remarques'  if texte.match?(REMARQUES_FR)    || texte.match?(REMARQUES_NL)
    return 'conforme'                 if texte.match?(CONFORME_FR)     || texte.match?(CONFORME_NL)
    nil
  end

  def extraire_date_prochain(texte)
    str = (texte.match(PROCHAIN_FR) || texte.match(PROCHAIN_NL))&.captures&.first
    parse_date_belge(str)
  end

  def extraire_installateur(texte)
    (texte.match(INSTALLATEUR_FR) || texte.match(INSTALLATEUR_NL))&.captures&.first&.strip
  end

  def extraire_type_controle(texte)
    m = texte.match(TYPE_FR) || texte.match(TYPE_NL)
    m&.captures&.first&.strip&.truncate(80)
  end

  def parse_date_belge(str)
    return nil unless str.present?
    parts = str.split(/[\/\-\.]/)
    return nil unless parts.length == 3
    Date.new(parts[2].to_i, parts[1].to_i, parts[0].to_i)
  rescue ArgumentError
    nil
  end

  def calculer_confiance(donnees)
    score = 0
    score += 35 if donnees[:organisme_controleur].present?
    score += 35 if donnees[:date_controle].present?
    score += 20 if donnees[:resultat].present?
    score += 10 if donnees[:numero_rapport].present?
    score
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # HELPERS D'AFFICHAGE (utilisables depuis les vues)
  # ─────────────────────────────────────────────────────────────────────────────
  RESULTAT_LABELS = {
    'conforme'                => { label: 'Conforme',              couleur: 'success', icone: 'bi-shield-check' },
    'conforme_avec_remarques' => { label: 'Conforme avec réserves', couleur: 'warning', icone: 'bi-shield-exclamation' },
    'non_conforme'            => { label: 'Non conforme',          couleur: 'danger',  icone: 'bi-shield-x' }
  }.freeze

  def self.label_resultat(resultat)
    RESULTAT_LABELS.fetch(resultat.to_s, { label: resultat.to_s.humanize, couleur: 'secondary', icone: 'bi-shield' })
  end
end
