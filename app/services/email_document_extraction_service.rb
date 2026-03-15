require 'open3'

class EmailDocumentExtractionService
  def initialize(attached_file)
    @attached_file = attached_file
  end

  def extract_pdf_data
    return {} unless @attached_file.attached?

    begin
      # Télécharger temporairement le fichier
      temp_file = download_temp_file

      # Extraire le texte du PDF
      extracted_text = extract_text_from_pdf(temp_file.path)

      # Analyser le texte pour extraire les informations structurées
      analyzed_data = analyze_extracted_text(extracted_text)

      analyzed_data.merge(extracted_text: extracted_text[0..1000]) # Limiter la taille

    rescue => e
      Rails.logger.error "❌ Erreur extraction PDF: #{e.message}"
      {}
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end

  def extract_image_data
    return {} unless @attached_file.attached?

    begin
      # Télécharger temporairement le fichier
      temp_file = download_temp_file

      # Extraire le texte de l'image via OCR
      extracted_text = extract_text_from_image(temp_file.path)

      # Analyser le texte pour extraire les informations structurées
      analyzed_data = analyze_extracted_text(extracted_text)

      analyzed_data.merge(extracted_text: extracted_text[0..1000]) # Limiter la taille

    rescue => e
      Rails.logger.error "❌ Erreur extraction image: #{e.message}"
      {}
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end

  private

  def download_temp_file
    temp_file = Tempfile.new(['document', File.extname(@attached_file.filename.to_s)])
    temp_file.binmode
    temp_file.write(@attached_file.download)
    temp_file.rewind
    temp_file
  end

  def extract_text_from_pdf(file_path)
    # Utiliser la gem 'pdf-reader' pour extraire le texte
    begin
      require 'pdf-reader'
      reader = PDF::Reader.new(file_path)
      text = ""
      reader.pages.each do |page|
        text += page.text
      end
      text
    rescue LoadError
      Rails.logger.warn "⚠️  Gem pdf-reader non installée, utilisation de fallback"
      extract_text_with_poppler(file_path)
    rescue => e
      Rails.logger.error "❌ Erreur PDF Reader: #{e.message}"
      ""
    end
  end

  def extract_text_with_poppler(file_path)
    # Fallback avec pdftotext (poppler-utils) - arguments séparés pour éviter l'injection
    begin
      result, status = Open3.capture2('pdftotext', file_path, '-')
      status.success? ? result : ""
    rescue => e
      Rails.logger.error "❌ Erreur pdftotext: #{e.message}"
      ""
    end
  end

  def extract_text_from_image(file_path)
    # Utiliser Tesseract pour l'OCR - arguments séparés pour éviter l'injection
    begin
      result, status = Open3.capture2('tesseract', file_path, 'stdout', '-l', 'fra')
      status.success? ? result : ""
    rescue => e
      Rails.logger.error "❌ Erreur Tesseract: #{e.message}"
      ""
    end
  end

  def analyze_extracted_text(text)
    return {} if text.blank?

    analyzed_data = {}

    # Extraire le numéro de dossier
    analyzed_data[:numero_dossier] = extract_dossier_number(text)

    # Extraire le montant accordé
    analyzed_data[:montant_accorde] = extract_amount(text)

    # Détecter le statut administratif
    analyzed_data[:status_administratif] = detect_status(text)

    # Extraire la date de décision
    analyzed_data[:date_decision] = extract_decision_date(text)

    # Extraire les conditions spéciales
    analyzed_data[:conditions] = extract_conditions(text)

    analyzed_data.compact
  end

  def extract_dossier_number(text)
    # Patterns courants pour les numéros de dossier
    patterns = [
      /(?:dossier|n[°o]|référence)[:\s]*([a-z0-9\/\-\.]+)/i,
      /([0-9]{4}\/[0-9]+)/,
      /([a-z]{2,3}[0-9]{4,})/i
    ]

    patterns.each do |pattern|
      match = text.match(pattern)
      return match.captures.first.strip if match
    end

    nil
  end

  def extract_amount(text)
    # Rechercher des montants en euros avec différents formats
    patterns = [
      /(\d+(?:[.,]\d{2})?)\s*€/,
      /€\s*(\d+(?:[.,]\d{2})?)/,
      /montant[:\s]*(\d+(?:[.,]\d{2})?)/i,
      /prime[:\s]*(\d+(?:[.,]\d{2})?)/i
    ]

    patterns.each do |pattern|
      match = text.match(pattern)
      if match
        amount = match.captures.first.tr(',', '.').to_f
        return amount if amount > 0
      end
    end

    nil
  end

  def detect_status(text)
    text_lower = text.downcase

    # Priorité aux décisions définitives
    return 'accorde' if text_lower.match?(/accord[ée]|accept[ée]|approuv[ée]|favorable/)
    return 'refuse' if text_lower.match?(/refus[ée]|rejet[ée]|défavorable|non.*accord[ée]/)

    # Puis aux statuts intermédiaires
    return 'incomplet' if text_lower.match?(/incomplet|manqu[ea]nt|document.*manqu|pièce.*manqu/)
    return 'en_cours' if text_lower.match?(/en.*cours|traitement|instruction|examen/)

    nil
  end

  def extract_decision_date(text)
    # Rechercher des dates de décision
    date_patterns = [
      /décision.*?(\d{1,2}\/\d{1,2}\/\d{4})/i,
      /date.*?(\d{1,2}\/\d{1,2}\/\d{4})/i,
      /(\d{1,2}\/\d{1,2}\/\d{4})/
    ]

    date_patterns.each do |pattern|
      match = text.match(pattern)
      if match
        begin
          return Date.strptime(match.captures.first, '%d/%m/%Y')
        rescue Date::Error
          next
        end
      end
    end

    nil
  end

  def extract_conditions(text)
    # Extraire les conditions ou remarques importantes
    conditions = []

    # Rechercher des sections de conditions
    if match = text.match(/conditions?[:\s]*(.*?)(?:\n\n|\z)/mi)
      conditions << match.captures.first.strip
    end

    if match = text.match(/remarques?[:\s]*(.*?)(?:\n\n|\z)/mi)
      conditions << match.captures.first.strip
    end

    conditions.reject(&:blank?).join("; ") if conditions.any?
  end
end
