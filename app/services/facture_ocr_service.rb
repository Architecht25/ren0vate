class FactureOcrService < OcrService
  # Patterns regex pour extraction de données de factures
  MONTANT_PATTERNS = [
    # "Net à Payer : 38.160,00" ou "38 . 160 , 00" (avec espaces autour des séparateurs)
    /(?:net\s+[àa]\s+payer|total\s+ttc|total\s+tvac|montant\s+ttc)\s*[:\-]?\s*([\d][0-9\s\.\,]+[0-9])\s*(?:€|EUR)?/i,
    /(?:total|montant|somme|due?|à payer|total général|total ttc)\s*:?\s*([0-9]{1,3}(?:\s*[.\s]\s*[0-9]{3})*\s*(?:[,\s]\s*[0-9]{1,2})?)\s*[€]/i,
    /(?:total|montant|somme|due?|à payer|total général|total ttc)\s*:?\s*([0-9]{1,3}(?:[,\s][0-9]{3})*(?:\.[0-9]{1,2})?)\s*[€]/i,
    /([0-9]{1,3}(?:[.\s][0-9]{3})*(?:,[0-9]{1,2})?)\s*[€]\s*(?:ttc|total|due?|tvac)/i,
    /(\d{1,3}(?:\s*[.,\s]\s*\d{3})*(?:\s*[.,]\s*\d{2})?)\s*(?:€|EUR|euros?)/i
  ].freeze

  MOIS_FR = {
    'janvier' => 1, 'février' => 2, 'fevrier' => 2, 'mars' => 3, 'avril' => 4,
    'mai' => 5, 'juin' => 6, 'juillet' => 7, 'août' => 8, 'aout' => 8,
    'septembre' => 9, 'octobre' => 10, 'novembre' => 11, 'décembre' => 12, 'decembre' => 12
  }.freeze

  DATE_PATTERNS = [
    /(?:date|facturé le|émise? le|du)\s*:?\s*([0-3]?[0-9][\/\-\.][0-1]?[0-9][\/\-\.](?:20)?[0-9]{2})/i,
    /([0-3]?[0-9][\/\-\.][0-1]?[0-9][\/\-\.](?:20)?[0-9]{2})/,
    /(?:date de facturation|date d'émission)\s*:?\s*([0-3]?[0-9][\/\-\.][0-1]?[0-9][\/\-\.](?:20)?[0-9]{2})/i,
    # Date en toutes lettres : "le 3 avril 2025" ou "Bruxelles, le 3 avril 2025"
    /(?:le\s+)?(\d{1,2})\s+(janvier|f[ée]vrier|mars|avril|mai|juin|juillet|ao[ûu]t|septembre|octobre|novembre|d[ée]cembre)\s+(20\d{2})/i
  ].freeze

  NUMERO_FACTURE_PATTERNS = [
    # "FACTURE N° : 106" — numéro seul, sans texte long après
    /FACTURE\s+N[°o]?\s*[:\-]?\s*([A-Z0-9\-\/]{1,20})\b/i,
    # "N° : 106" ou "Num : FA2024-001"
    /\bN[°o]\s*[:\-]\s*([A-Z0-9\-\/]{1,20})\b/i,
    /(?:facture|fact|numéro|num)\s+n[°o]?\s*[:\-]?\s*([A-Z0-9\-\/]{1,20})\b/i,
    /(?:invoice|bill)\s*(?:number|no|#)\s*[:\-]?\s*([A-Z0-9\-\/]{1,20})\b/i,
  ].freeze

  TVA_PATTERNS = [
    /(?:t\.?v\.?a\.?|tva)\s*:?\s*([0-9]{1,2}(?:[.,][0-9]{1,2})?)\s*%?/i,
    /(?:vat|btw)\s*:?\s*([0-9]{1,2}(?:[.,][0-9]{1,2})?)\s*%?/i,
    /([0-9]{1,2}(?:[.,][0-9]{1,2})?)\s*%\s*(?:t\.?v\.?a\.?|tva)/i
  ].freeze

  ENTREPRISE_PATTERNS = [
    /(?:^|\n)([A-Z][A-Za-z\s&\-\.]{3,50})\s*(?:s\.?[pa]\.?r\.?l\.?|s\.?a\.?|ltd|limited|inc)/i,
    /(?:société|entreprise|company)\s*:?\s*([A-Za-z\s&\-\.]{3,50})/i,
    /^([A-Z][A-Za-z\s&\-\.]{10,50})$/m
  ].freeze

  BCE_PATTERNS = [
    /(?:bce|entreprise|company)\s*(?:n°|number|num)?\s*:?\s*([0-9]{4}[.\s]?[0-9]{3}[.\s]?[0-9]{3})/i,
    /([0-9]{4}[.\s]?[0-9]{3}[.\s]?[0-9]{3})/,
    /(?:n°\s*bce|bce\s*n°)\s*:?\s*([0-9\.]{12,15})/i
  ].freeze

  TYPE_FACTURE_KEYWORDS = {
    'devis' => ['devis', 'estimation', 'quote', 'offre', 'proposition'],
    'facture' => ['facture', 'invoice', 'bill', 'note'],
    'acompte' => ['acompte', 'avance', 'advance', 'deposit', 'provision'],
    'solde' => ['solde', 'final', 'finale', 'balance', 'remainder', 'complément']
  }.freeze

  def initialize(file, language: 'fra+eng')
    super(file, language: language)
  end

  def extraire_donnees_facture
    # Effectuer d'abord l'OCR standard
    ocr_result = call
    return ocr_result unless ocr_result[:success]

    texte = ocr_result[:text]

    # Extraire les données spécifiques aux factures
    donnees_extraites = {
      montant: extraire_montant(texte),
      date_facture: extraire_date(texte),
      numero_facture: extraire_numero_facture(texte),
      nom_entreprise: extraire_nom_entreprise(texte),
      numero_bce: extraire_numero_bce(texte),
      taux_tva: extraire_taux_tva(texte),
      type_facture: detecter_type_facture(texte),
      montant_ht: extraire_montant_ht(texte),
      montant_tva: extraire_montant_tva(texte)
    }

    # Calculer le niveau de confiance global
    confiance_extraction = calculer_confiance_extraction(donnees_extraites, ocr_result[:confidence])

    # Retourner le résultat enrichi
    ocr_result.merge({
      donnees_facture: donnees_extraites,
      confiance_extraction: confiance_extraction,
      extraction_complete: extraction_complete?(donnees_extraites),
      texte_brut: texte
    })
  end

  private

  def extraire_montant(texte)
    MONTANT_PATTERNS.each do |pattern|
      match = texte.match(pattern)
      if match
        montant = parse_montant_belge(match[1])
        return montant if montant && montant > 0 && montant < 10_000_000
      end
    end
    nil
  end

  def extraire_date(texte)
    DATE_PATTERNS.each do |pattern|
      match = texte.match(pattern)
      if match
        begin
          date = nil
          if match.captures.length == 3
            # Pattern date en toutes lettres : jour, mois, année
            jour = match[1].to_i
            mois = MOIS_FR[match[2].downcase]
            annee = match[3].to_i
            date = Date.new(annee, mois, jour) if mois
          else
            date_str = match[1]
            date = Date.strptime(date_str, '%d/%m/%Y') rescue nil
            date ||= Date.strptime(date_str, '%d-%m-%Y') rescue nil
            date ||= Date.strptime(date_str, '%d.%m.%Y') rescue nil
            date ||= Date.strptime(date_str, '%d/%m/%y') rescue nil
          end
          return date if date && date > Date.new(2020) && date <= Date.current + 1.year
        rescue
          next
        end
      end
    end
    nil
  end

  def extraire_numero_facture(texte)
    NUMERO_FACTURE_PATTERNS.each do |pattern|
      match = texte.match(pattern)
      if match
        numero = match[1].strip
        return numero if numero.length >= 3 && numero.length <= 20
      end
    end
    nil
  end

  def extraire_nom_entreprise(texte)
    lignes = texte.split("\n").map(&:strip).reject(&:empty?)

    # Chercher dans les premières lignes (généralement l'en-tête)
    lignes[0..5].each do |ligne|
      ENTREPRISE_PATTERNS.each do |pattern|
        match = ligne.match(pattern)
        if match
          nom = match[1].strip
          return nom if nom.length >= 3 && nom.length <= 100
        end
      end
    end

    # Fallback: première ligne non vide qui ressemble à un nom d'entreprise
    lignes[0..3].each do |ligne|
      if ligne.length > 5 && ligne.match?(/[A-Z]/) && !ligne.match?(/\d{4,}/)
        return ligne.strip
      end
    end

    nil
  end

  def extraire_numero_bce(texte)
    BCE_PATTERNS.each do |pattern|
      match = texte.match(pattern)
      if match
        bce = match[1].gsub(/[\.\s]/, '')
        return bce if bce.match?(/^\d{10}$/)
      end
    end
    nil
  end

  def extraire_taux_tva(texte)
    TVA_PATTERNS.each do |pattern|
      match = texte.match(pattern)
      if match
        taux = match[1].gsub(',', '.').to_f
        return taux if taux >= 0 && taux <= 30 # TVA valide entre 0 et 30%
      end
    end
    nil
  end

  def detecter_type_facture(texte)
    texte_lower = texte.downcase

    # Scoring pondéré : on donne du poids selon le contexte
    # Les types spécifiques (acompte, solde) ont la priorité sur les mots génériques
    scores = Hash.new(0)

    # Acompte : poids élevé car terme très spécifique
    scores['acompte'] += 10 if texte_lower.match?(/\bacompte\b/)
    scores['acompte'] += 5  if texte_lower.match?(/\b(avance|deposit|provision)\b/)

    # Solde : poids élevé
    scores['solde'] += 10 if texte_lower.match?(/\bsolde\b/)
    scores['solde'] += 8  if texte_lower.match?(/\b(final|finale|reliquat|compl[eè]ment)\b/)

    # État d'avancement
    scores['etat_avancement'] += 10 if texte_lower.match?(/[eé]tat\s+d'?avancement/)
    scores['etat_avancement'] += 8  if texte_lower.match?(/\bsituation\s+de\s+travaux\b/)

    # Facture générique — le titre "FACTURE" en haut du doc vaut beaucoup
    scores['facture'] += 15 if texte_lower.match?(/^\s*facture\s*$/)
    scores['facture'] += 8  if texte_lower.match?(/\b(invoice|bill)\b/)

    # Devis — pénalité si c'est juste une référence ("Réf : DEVIS …")
    # On ajoute du poids seulement si le mot apparaît hors d'un contexte de référence
    devis_refs = texte_lower.scan(/r[eé]f\s*:?\s*devis|r[eé]f[eé]rence\s*:?\s*devis|sv\s+devis/).length
    devis_total = texte_lower.scan(/\bdevis\b/).length
    scores['devis'] += [(devis_total - devis_refs) * 8, 0].max
    scores['devis'] += 5 if texte_lower.match?(/\b(estimation|offre|proposition)\b/)

    # Le type avec le score le plus élevé gagne
    best = scores.max_by { |_, v| v }
    return best[0] if best && best[1] > 0

    'facture' # par défaut
  end

  def extraire_montant_ht(texte)
    patterns_ht = [
      # Format belge : SOUS TOTAL 15.100,00 €
      /(?:sous[\s\-]?total|total\s+ht|montant\s+ht|htva)\s*[:\-]?\s*([0-9]{1,3}(?:[.\s][0-9]{3})*(?:,[0-9]{1,2})?)\s*[€]/i,
      /(?:sous[\s\-]?total|total\s+ht|montant\s+ht|htva)\s*[:\-]?\s*([0-9]{1,3}(?:[,\s][0-9]{3})*(?:\.[0-9]{1,2})?)\s*[€]/i,
      /([0-9]{1,3}(?:[.\s][0-9]{3})*(?:,[0-9]{1,2})?)\s*[€]\s*(?:ht|htva)/i,
      /([0-9]{1,3}(?:\s?[0-9]{3})*(?:[.,][0-9]{1,2})?)\s*[€]\s*ht/i
    ]

    patterns_ht.each do |pattern|
      match = texte.match(pattern)
      if match
        montant = parse_montant_belge(match[1])
        return montant if montant && montant > 0
      end
    end
    nil
  end

  def extraire_montant_tva(texte)
    patterns_tva = [
      /(?:tva|t\.v\.a\.|btw)\s*(?:[0-9]{1,2}\s*%)?\s*[:\-]?\s*([0-9]{1,3}(?:[.\s][0-9]{3})*(?:,[0-9]{1,2})?)\s*[€]/i,
      /([0-9]{1,3}(?:[.\s][0-9]{3})*(?:,[0-9]{1,2})?)\s*[€]\s*(?:tva|t\.v\.a\.)/i,
      /([0-9]{1,3}(?:\s?[0-9]{3})*(?:[.,][0-9]{1,2})?)\s*[€]\s*(?:tva|t\.v\.a\.)/i
    ]

    patterns_tva.each do |pattern|
      match = texte.match(pattern)
      if match
        montant = parse_montant_belge(match[1])
        return montant if montant && montant > 0
      end
    end
    nil
  end

  # ── Parse montant format belge : 15.100,00 ou 15,100.00 ou 15100,00 ──────────
  def parse_montant_belge(str)
    return nil if str.blank?
    s = str.strip

    # Format belge canonique : point = milliers, virgule = décimale (ex: 15.100,00)
    if s.match?(/^\d{1,3}(?:\.\d{3})+,\d{2}$/)
      return s.gsub('.', '').gsub(',', '.').to_f
    end

    # Format international : virgule = milliers, point = décimale (ex: 15,100.00)
    if s.match?(/^\d{1,3}(?:,\d{3})+\.\d{2}$/)
      return s.gsub(',', '').to_f
    end

    # Espace comme séparateur milliers (ex: 15 100,00 ou 15 100.00)
    if s.match?(/^\d{1,3}(?:\s\d{3})+[,.]\d{2}$/)
      s = s.gsub(/\s/, '')
      return s.gsub(',', '.').to_f
    end

    # Format simple sans séparateur milliers (ex: 1700,00 ou 1700.00)
    s.gsub(',', '.').to_f.tap { |v| return nil if v == 0.0 }
  end

  def calculer_confiance_extraction(donnees, confiance_ocr)
    # Calculer la confiance basée sur les données extraites
    points = 0
    total = 0

    # Montant (crucial)
    total += 40
    points += 40 if donnees[:montant].present?

    # Date (crucial)
    total += 30
    points += 30 if donnees[:date_facture].present?

    # Numéro de facture (important)
    total += 15
    points += 15 if donnees[:numero_facture].present?

    # Nom entreprise (important)
    total += 10
    points += 10 if donnees[:nom_entreprise].present?

    # Type de facture détecté
    total += 5
    points += 5 if donnees[:type_facture].present?

    confiance_donnees = (points.to_f / total * 100).round(1)

    # Combiner avec la confiance OCR
    if confiance_ocr
      (confiance_donnees * 0.6 + confiance_ocr * 0.4).round(1)
    else
      confiance_donnees
    end
  end

  def extraction_complete?(donnees)
    # Une extraction est considérée comme complète si on a au minimum:
    # - Le montant
    # - La date ou le numéro de facture
    # - Le type de document
    donnees[:montant].present? &&
    (donnees[:date_facture].present? || donnees[:numero_facture].present?) &&
    donnees[:type_facture].present?
  end
end
