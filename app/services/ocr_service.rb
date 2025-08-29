class OcrService
  include ActiveModel::Model

  ALLOWED_CONTENT_TYPES = [
    'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
    'application/pdf'
  ].freeze

  MAX_FILE_SIZE = 10.megabytes

  attr_accessor :file, :language

  def initialize(file, language: 'fra+eng')
    @file = file
    @language = language
  end

  def call
    return error_result('Aucun fichier fourni') unless file

    # Validation du fichier
    validation_result = validate_file
    return validation_result unless validation_result[:success]

    # Traitement OCR
    process_ocr
  rescue StandardError => e
    Rails.logger.error "OcrService error: #{e.message}"
    error_result("Erreur lors du traitement OCR: #{e.message}")
  end

  private

  def validate_file
    unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
      return error_result('Format de fichier non supporté')
    end

    if file.size > MAX_FILE_SIZE
      return error_result('Fichier trop volumineux (max 10MB)')
    end

    { success: true }
  end

  def process_ocr
    start_time = Time.current

    # Stratégie selon la disponibilité des services
    result = if tesseract_available?
      process_with_tesseract
    elsif pdf_text_extractable?
      process_pdf_text_extraction
    else
      fallback_processing
    end

    result.merge(
      processing_time: (Time.current - start_time).round(2),
      language: detect_language(result[:text])
    )
  end

  def tesseract_available?
    defined?(RTesseract) && system('which tesseract > /dev/null 2>&1')
  end

  def pdf_text_extractable?
    file.content_type == 'application/pdf' && defined?(PDF::Reader)
  end

  def process_with_tesseract
    temp_file = create_temp_file

    begin
      # Configuration Tesseract
      image = RTesseract.new(temp_file.path, lang: language)

      # Améliorer la qualité pour les images floues
      if file.content_type.start_with?('image/')
        image.config_file('quiet')
        image.psm(6) # Assume uniform block of text
        image.oem(3) # Default, based on what is available
      end

      text = image.to_s.strip
      confidence = calculate_confidence(text)

      {
        success: true,
        text: text,
        confidence: confidence,
        method: 'tesseract'
      }
    ensure
      temp_file&.unlink
    end
  end

  def process_pdf_text_extraction
    begin
      reader = PDF::Reader.new(StringIO.new(file.read))
      text = reader.pages.map(&:text).join("\n").strip

      {
        success: true,
        text: text,
        confidence: text.present? ? 90 : 0,
        method: 'pdf_reader'
      }
    rescue PDF::Reader::MalformedPDFError => e
      Rails.logger.warn "PDF malformé, tentative OCR: #{e.message}"
      fallback_processing
    end
  end

  def fallback_processing
    {
      success: true,
      text: "⚠️ OCR non disponible\n\nPour activer l'OCR complet:\n• Installez Tesseract: sudo apt-get install tesseract-ocr tesseract-ocr-fra\n• Ou configurez une API OCR (Google Vision, AWS Textract)",
      confidence: 0,
      method: 'fallback'
    }
  end

  def create_temp_file
    extension = case file.content_type
    when 'application/pdf' then '.pdf'
    when /image\/jpeg/ then '.jpg'
    when /image\/png/ then '.png'
    when /image\/gif/ then '.gif'
    when /image\/webp/ then '.webp'
    else '.tmp'
    end

    temp_file = Tempfile.new(['ocr_scan', extension])
    temp_file.binmode
    temp_file.write(file.read)
    temp_file.close
    temp_file
  end

  def calculate_confidence(text)
    return 0 if text.blank?

    # Analyse de base de la qualité du texte
    words = text.split
    return 0 if words.empty?

    base_confidence = [words.length * 3, 60].min

    # Bonus pour les patterns reconnaissables
    bonus = 0
    bonus += 15 if text.match?(/\d{2}[\/\-\.]\d{2}[\/\-\.]\d{4}/) # Dates
    bonus += 12 if text.match?(/\d+[,.]?\d*\s*€/) # Montants en euros
    bonus += 10 if text.match?(/\b[A-Z]{2,}\b/) # Acronymes
    bonus += 8 if text.match?(/\b\d{4,}\b/) # Codes/numéros
    bonus += 5 if text.match?(/\b(facture|invoice|devis|quote)\b/i) # Mots-clés documents

    # Pénalités pour le texte de mauvaise qualité
    penalty = 0
    penalty += 10 if text.count('?') > text.length * 0.1 # Trop de caractères inconnus
    penalty += 15 if text.split.count { |w| w.length < 2 } > words.length * 0.3 # Trop de mots trop courts

    confidence = [(base_confidence + bonus - penalty).round, 100].min
    [confidence, 0].max
  end

  def detect_language(text)
    return @language.split('+').first if text.blank?

    # Mots indicateurs par langue
    french_indicators = %w[le la les de du des et ou mais donc car avec sans pour par sur]
    dutch_indicators = %w[de het een van der den en of maar dus want met zonder voor door op]
    english_indicators = %w[the and or but for with without by from on]

    text_lower = text.downcase

    french_score = french_indicators.count { |word| text_lower.include?(" #{word} ") }
    dutch_score = dutch_indicators.count { |word| text_lower.include?(" #{word} ") }
    english_score = english_indicators.count { |word| text_lower.include?(" #{word} ") }

    case [french_score, dutch_score, english_score].max
    when french_score then 'fr'
    when dutch_score then 'nl'
    when english_score then 'en'
    else 'fr' # défaut
    end
  end

  def error_result(message)
    {
      success: false,
      error: message,
      text: '',
      confidence: 0,
      processing_time: 0,
      method: 'error'
    }
  end
end
