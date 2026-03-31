class AerOcrService < OcrService
  # ─────────────────────────────────────────────────────────────────────────────
  # AER belge — Avertissement-Extrait de Rôle (SPF Finances / FOD Financiën)
  # Prend en charge : PDF texte, PDF scanné, images JPEG / PNG
  # Langues OCR    : fra+nld (bilingue — documents flamands en néerlandais)
  # ─────────────────────────────────────────────────────────────────────────────

  # Formats de fichier AER acceptés (extension de l'OcrService de base)
  AER_ALLOWED_TYPES = (ALLOWED_CONTENT_TYPES + ['application/pdf']).uniq.freeze

  # ── Exercice d'imposition ────────────────────────────────────────────────────
  ANNEE_EXERCICE_FR = /exercice\s+d['']imposition\s*[:\-]?\s*(\d{4})/i
  ANNEE_EXERCICE_NL = /aanslagjaar\s*[:\-]?\s*(\d{4})/i

  # ── Année des revenus (= exercice – 1, mais parfois mentionnée explicitement)
  ANNEE_REVENUS_FR  = /ann[ée]e\s+(?:des\s+)?revenus?\s*[:\-]?\s*(\d{4})/i
  ANNEE_REVENUS_NL  = /inkomstenjaar\s*[:\-]?\s*(\d{4})/i

  # ── Revenu imposable globalement ─────────────────────────────────────────────
  REVENU_GLOBAL_FR = [
    /revenu\s+imposable\s+globalement?\s*[:\-]?\s*([\d\s.,]+)/i,
    /(?:total|revenu)\s+net\s+imposable\s*[:\-]?\s*([\d\s.,]+)/i,
    /revenus?\s+nets?\s+imposables?\s*[:\-]?\s*([\d\s.,]+)/i,
    /base\s+imposable\s*[:\-]?\s*([\d\s.,]+)/i,
  ].freeze

  REVENU_GLOBAL_NL = [
    /gezamenlijk\s+belastbaar\s+inkomen\s*[:\-]?\s*([\d\s.,]+)/i,
    /netto\s+belastbaar\s+inkomen\s*[:\-]?\s*([\d\s.,]+)/i,
    /belastbare\s+basis\s*[:\-]?\s*([\d\s.,]+)/i,
  ].freeze

  # ── Détection colonne conjoint ───────────────────────────────────────────────
  CONJOINT_FR = /votre\s+(?:conjoint[e]?|partenaire)|cohabitant\s+l[eé]gal/i
  CONJOINT_NL = /uw\s+(?:echtgeno[ot]e?|partner|samenwonende)/i

  # ── Nom / prénom ─────────────────────────────────────────────────────────────
  NOM_FR  = /(?:monsieur|madame|m\.|mme\.?)\s+([A-Z][A-Z\-\s']{1,40})/i
  NOM_NL  = /(?:de heer|mevrouw|dhr\.|mevr\.)\s+([A-Z][A-Z\-\s']{1,40})/i
  # Fallback : première ligne tout en majuscules (fréquent sur les AER SPF)
  NOM_CAPS = /\A\s*([A-Z]{2,}(?:\s+[A-Z\-']{1,30}){1,3})\s*$/

  # ── Date d'enrôlement ────────────────────────────────────────────────────────
  DATE_ENROLEMENT_FR = /(?:dat[e]?\s+d['']enr[ôo]lement|enr[ôo]l[eé]\s+le)\s*[:\-]?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i
  DATE_ENROLEMENT_NL = /(?:datum\s+(?:van\s+)?inkohiering|ingekohierd\s+op)\s*[:\-]?\s*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{4})/i
  DATE_GENERIC       = /(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.](?:20)?\d{2})/

  # ── Code 1030 = enfants fiscalement à charge ─────────────────────────────────
  CODE_1030 = /\b1030\b.*?(\d+)/

  def initialize(file, language: 'fra+nld')
    super(file, language: language)
  end

  # ── Point d'entrée principal ──────────────────────────────────────────────────
  def extraire_donnees_aer
    ocr_result = call
    return ocr_result unless ocr_result[:success]

    texte = ocr_result[:text].to_s
    donnees = extraire_champs(texte)
    confiance = calculer_confiance_aer(donnees, ocr_result[:confidence])

    annee_revenus      = donnees[:annee_revenus]
    annee_exercice     = donnees[:annee_exercice_imposition]
    revenu_global      = donnees[:revenu_imposable_global]
    revenu_demandeur   = donnees[:revenu_demandeur]
    revenu_conjoint    = donnees[:revenu_conjoint]

    perime = perimé?(annee_revenus)

    ocr_result.merge(
      donnees_aer:                    donnees,
      revenu_imposable_global:        revenu_global,
      revenu_demandeur:               revenu_demandeur,
      revenu_conjoint:                revenu_conjoint,
      annee_revenus:                  annee_revenus,
      annee_exercice_imposition:      annee_exercice,
      nom_contribuable:               donnees[:nom_contribuable],
      prenom_contribuable:            donnees[:prenom_contribuable],
      type_declaration:               donnees[:type_declaration],
      nombre_enfants_charge:          donnees[:nombre_enfants_charge],
      date_enrolement:                donnees[:date_enrolement],
      confiance_extraction:           confiance,
      extraction_complete:            extraction_complete?(donnees),
      revenus_potentiellement_perimes: perime,
      texte_brut:                     texte
    )
  end

  private

  # ─────────────────────────────────────────────────────────────────────────────
  # Extraction des champs
  # ─────────────────────────────────────────────────────────────────────────────

  def extraire_champs(texte)
    lignes = texte.split("\n").map(&:strip).reject(&:blank?)

    annee_exercice = extraire_annee_exercice(texte)
    annee_revenus  = extraire_annee_revenus(texte, annee_exercice)
    couple         = declaration_couple?(texte)

    revenu_demandeur, revenu_conjoint = extraire_revenus_colonnes(texte, couple)
    revenu_global = revenu_demandeur.to_i + revenu_conjoint.to_i if couple && revenu_demandeur && revenu_conjoint
    revenu_global ||= extraire_revenu_global(texte) || revenu_demandeur

    nom, prenom = extraire_identite(lignes)

    {
      annee_revenus:              annee_revenus,
      annee_exercice_imposition:  annee_exercice,
      revenu_imposable_global:    parse_montant(revenu_global&.to_s),
      revenu_demandeur:           parse_montant(revenu_demandeur&.to_s),
      revenu_conjoint:            couple ? parse_montant(revenu_conjoint&.to_s) : nil,
      type_declaration:           couple ? 'couple' : 'isole',
      nombre_enfants_charge:      extraire_enfants(texte),
      nom_contribuable:           nom,
      prenom_contribuable:        prenom,
      adresse_contribuable:       extraire_adresse(lignes),
      date_enrolement:            extraire_date_enrolement(texte),
    }
  end

  # ── Exercice d'imposition ────────────────────────────────────────────────────
  def extraire_annee_exercice(texte)
    match = texte.match(ANNEE_EXERCICE_FR) || texte.match(ANNEE_EXERCICE_NL)
    match&.captures&.first
  end

  # ── Année des revenus ────────────────────────────────────────────────────────
  def extraire_annee_revenus(texte, annee_exercice)
    match = texte.match(ANNEE_REVENUS_FR) || texte.match(ANNEE_REVENUS_NL)
    return match.captures.first if match

    # Fallback : exercice d'imposition − 1
    annee_exercice ? (annee_exercice.to_i - 1).to_s : nil
  end

  # ── Déclaration couple ? ─────────────────────────────────────────────────────
  def declaration_couple?(texte)
    texte.match?(CONJOINT_FR) || texte.match?(CONJOINT_NL)
  end

  # ── Revenus colonnes demandeur / conjoint ─────────────────────────────────────
  # Sur un AER commun, les montants apparaissent sur la même ligne, séparés
  # par un ou plusieurs espaces, TABULATIONS ou pipes.
  def extraire_revenus_colonnes(texte, couple)
    patterns_globaux = REVENU_GLOBAL_FR + REVENU_GLOBAL_NL

    patterns_globaux.each do |pattern|
      # Chercher une ligne contenant 1 ou 2 montants après le libellé
      texte.scan(/#{pattern.source}(?:\s+(?:[\d\s.,]+))?/im) do |m|
        if couple
          # On tente d'attraper 2 montants alignés sur la même ligne
          ligne_match = $~&.pre_match&.split("\n")&.last.to_s + $~.to_s
          montants = ligne_match.scan(/[\d]{1,3}(?:[\s.,]\d{3})*(?:[.,]\d{2})?/)
                                 .map { |v| parse_montant(v) }
                                 .compact
                                 .select { |v| v > 500 }
          return montants[0], montants[1] if montants.size >= 2
          return montants[0], nil if montants.size == 1
        else
          montant = parse_montant(m.first.to_s)
          return montant, nil if montant && montant > 500
        end
      end
    end

    [nil, nil]
  end

  # ── Revenu global (fallback si pas de colonnes) ───────────────────────────────
  def extraire_revenu_global(texte)
    (REVENU_GLOBAL_FR + REVENU_GLOBAL_NL).each do |pattern|
      m = texte.match(pattern)
      return m.captures.first if m
    end
    nil
  end

  # ── Enfants à charge (code 1030) ─────────────────────────────────────────────
  def extraire_enfants(texte)
    m = texte.match(CODE_1030)
    m&.captures&.first&.to_i
  end

  # ── Identité ─────────────────────────────────────────────────────────────────
  def extraire_identite(lignes)
    # Chercher libellé civilité suivi du nom
    lignes.each do |ligne|
      m = ligne.match(NOM_FR) || ligne.match(NOM_NL)
      next unless m

      parties = m.captures.first.strip.split(/\s+/, 2)
      return parties[0]&.capitalize, parties[1]&.split&.map(&:capitalize)&.join(' ')
    end

    # Fallback CAPS — souvent les 2-3 premières lignes de l'AER
    lignes.first(5).each do |ligne|
      m = ligne.match(NOM_CAPS)
      next unless m

      parties = m.captures.first.strip.split(/\s+/, 2)
      return parties[0]&.capitalize, parties[1]&.split&.map(&:capitalize)&.join(' ')
    end

    [nil, nil]
  end

  # ── Adresse (heuristique : ligne avec code postal belge) ─────────────────────
  def extraire_adresse(lignes)
    lignes.find { |l| l.match?(/\b\d{4}\b/) && l.match?(/[A-Za-z]{3,}/) }
  end

  # ── Date d'enrôlement ────────────────────────────────────────────────────────
  def extraire_date_enrolement(texte)
    m = texte.match(DATE_ENROLEMENT_FR) || texte.match(DATE_ENROLEMENT_NL)
    date_str = m&.captures&.first
    date_str ||= texte.match(DATE_GENERIC)&.captures&.first
    parse_date(date_str)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Helpers
  # ─────────────────────────────────────────────────────────────────────────────

  # Nettoie et convertit un montant textuel en Float (centimes conservés).
  # Gère les séparateurs BE : "41.691,27" / "41 691,27" / "41691" / "4169127"
  #
  # Quirk SPF Finances : certains PDF stockent les montants en centimes entiers
  # dans le flux texte (ex: "4169127" au lieu de "41.691,27").
  # Heuristique : si la valeur entière dépasse SEUIL_MAX_REVENU_EURO, on suppose
  # un encodage en centimes et on divise par 100.
  SEUIL_MAX_REVENU_EURO = 500_000  # au-delà d'un demi-million, suspect = centimes

  def parse_montant(str)
    return nil if str.blank?

    nettoyé = str.gsub(/[\s\u00a0]/, '')   # espaces normaux et insécables
    if nettoyé.match?(/,\d{1,2}\z/)
      # Format belge avec décimales : "41.691,27" → "41691.27"
      nettoyé = nettoyé.gsub('.', '').gsub(',', '.')
    else
      # Entier pur (avec ou sans séparateurs de milliers)
      nettoyé = nettoyé.gsub(/[.,]/, '')
    end

    val = nettoyé.to_f
    return nil unless val > 100

    # Heuristique centimes : PDF SPF Finances encode parfois en centimes entiers
    # Ex: 4169127 → 41 691,27 €
    if val > SEUIL_MAX_REVENU_EURO && val == val.to_i
      val_euros = (val / 100.0).round(2)
      val = val_euros if val_euros.between?(500, SEUIL_MAX_REVENU_EURO)
    end

    (val > 100 && val < 10_000_000) ? val.round(2) : nil
  end

  def parse_date(str)
    return nil if str.blank?

    # Formats : jj/mm/aaaa  jj-mm-aaaa  jj.mm.aaaa
    Date.strptime(str, '%d/%m/%Y')
  rescue ArgumentError
    begin
      Date.strptime(str, '%d-%m-%Y')
    rescue ArgumentError
      begin
        Date.strptime(str, '%d.%m.%Y')
      rescue ArgumentError
        nil
      end
    end
  end

  # ── Détection de péremption ──────────────────────────────────────────────────
  # Calendrier fiscal belge :
  #   Revenus N  →  déclaration IPP soumise ~juin N+1
  #               →  AER envoyé par SPF Finances ~Q1/Q2 de N+2
  # Donc avant mai de l'année courante, l'AER le plus récent disponible
  # couvre les revenus de current_year - 3 (ex: en mars 2026 → revenus 2023).
  # À partir de mai/juin, l'AER pour current_year - 2 est attendu.
  # On ne signale "périmé" que si l'AER est plus ancien que le plus récent attendu.
  def perimé?(annee_revenus)
    return false if annee_revenus.blank?

    today = Date.today
    # Avant mai : la nouvelle AER n'est pas encore disponible → seuil = current_year - 3
    # À partir de mai : la nouvelle AER devrait être disponible → seuil = current_year - 2
    seuil = today.month < 5 ? today.year - 3 : today.year - 2

    annee_revenus.to_i < seuil
  end

  # ── Score de confiance AER ───────────────────────────────────────────────────
  def calculer_confiance_aer(donnees, confiance_ocr_base)
    score = (confiance_ocr_base || 50).to_f
    champs_cles = %i[annee_revenus revenu_imposable_global revenu_demandeur]

    champs_cles.each do |champ|
      score += 10 if donnees[champ].present?
    end

    score += 5 if donnees[:nom_contribuable].present?
    score += 5 if donnees[:date_enrolement].present?
    score -= 15 if donnees[:revenu_imposable_global].nil? && donnees[:revenu_demandeur].nil?

    score.clamp(0, 100).round(1)
  end

  # ── Extraction complète ? (tous les champs obligatoires présents) ──────────
  def extraction_complete?(donnees)
    %i[annee_revenus revenu_imposable_global].all? { |k| donnees[k].present? }
  end
end
