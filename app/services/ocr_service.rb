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

    # Vérification par magic bytes (Marcel) — protège contre le spoofing du content-type
    magic_result = validate_magic_bytes
    return magic_result unless magic_result[:success]

    { success: true }
  end

  def validate_magic_bytes
    io = if file.respond_to?(:tempfile)
      file.tempfile          # UploadedFile (form upload) — lecture locale, sans réseau
    elsif file.respond_to?(:download)
      StringIO.new(file.download.byteslice(0, 4096) || "")  # Active Storage blob
    end

    return { success: true } unless io

    detected = Marcel::MimeType.for(io, name: file.respond_to?(:original_filename) ? file.original_filename.to_s : "")

    unless ALLOWED_CONTENT_TYPES.include?(detected)
      Rails.logger.warn "[Security] OcrService: content-type déclaré=#{file.content_type}, magic bytes détectés=#{detected}"
      return error_result("Contenu du fichier invalide (type réel détecté : #{detected})")
    end

    { success: true }
  rescue => e
    Rails.logger.warn "[Security] OcrService: vérification magic bytes échouée: #{e.message}"
    { success: true } # Fail open
  end

  def process_ocr
    start_time = Time.current

    # Pour les PDFs : pdftotext > PDF::Reader > Tesseract (Tesseract en dernier car il
    # n'est fiable que page 1 via ImageMagick et produit du garbage sur les PDFs vectoriels)
    result = if file.content_type == 'application/pdf' && pdf_text_extractable?
      process_pdf_text_extraction
    elsif tesseract_available?
      process_with_tesseract
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
    file.content_type == 'application/pdf' && (pdftotext_available? || defined?(PDF::Reader))
  end

  def pdftotext_available?
    @pdftotext_available ||= system('which pdftotext > /dev/null 2>&1')
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
    # pdftotext (poppler) gère mieux les encodages de polices personnalisées (ex: EPC flamand VEKA)
    if pdftotext_available?
      result = extract_with_pdftotext
      return result if result[:success] && text_looks_valid?(result[:text])
      Rails.logger.info "pdftotext: texte invalide (mauvais encodage de police), tentative PDF::Reader"
    end

    if defined?(PDF::Reader)
      begin
        file.rewind
        reader = PDF::Reader.new(StringIO.new(file.read))
        text = reader.pages.map(&:text).join("\n").strip
        if text_looks_valid?(text)
          return { success: true, text: text, confidence: 90, method: 'pdf_reader' }
        end
        Rails.logger.info "PDF::Reader: texte invalide, tentative OCR sur pages"
      rescue PDF::Reader::MalformedPDFError => e
        Rails.logger.warn "PDF malformé: #{e.message}"
      end
    end

    # Dernier recours : OCR page par page via pdftoppm + RTesseract
    # Nécessaire pour les PDFs VEKA (Flandre) dont l'encodage de police est incompatible
    if pdftotext_available? && defined?(RTesseract)
      Rails.logger.info "PDF: tentative OCR page-par-page (TESSDATA_PREFIX=#{ENV['TESSDATA_PREFIX']})"
      result = extract_pdf_pages_with_ocr
      Rails.logger.info "PDF page OCR result: method=#{result[:method]} text_length=#{result[:text]&.length} valid=#{text_looks_valid?(result[:text].to_s)}"
      return result if result[:success] && result[:text].present?
    end

    fallback_processing
  end

  def extract_with_pdftotext
    temp_file = create_temp_file
    begin
      require 'shellwords'
      output = `pdftotext -layout -enc UTF-8 #{Shellwords.escape(temp_file.path)} - 2>/dev/null`
      {
        success: true,
        text: output.to_s.strip,
        confidence: output.present? ? 85 : 0,
        method: 'pdftotext'
      }
    ensure
      temp_file&.unlink
    end
  end

  # Converti les premières pages du PDF en images (pdftoppm) puis OCR avec Tesseract.
  # Utilisé pour les PDFs avec encodage de police personnalisé (ex: EPCs VEKA flamands).
  def extract_pdf_pages_with_ocr
    return fallback_processing unless defined?(RTesseract)
    require 'shellwords'
    require 'tmpdir'
    Dir.mktmpdir do |tmpdir|
      temp_pdf = create_temp_file
      begin
        output_prefix = File.join(tmpdir, 'p')
        # 200 dpi, 3 premières pages (données clés = page 1)
        system("pdftoppm -r 200 -png -l 3 #{Shellwords.escape(temp_pdf.path)} #{Shellwords.escape(output_prefix)} 2>/dev/null")
        pages = Dir.glob("#{output_prefix}-*.png").sort
        return fallback_processing if pages.empty?

        text = pages.map do |img|
          RTesseract.new(img, lang: 'nld+fra+eng').to_s.strip
        rescue => e
          Rails.logger.warn "RTesseract page error: #{e.message}"
          ''
        end.join("\n")

        { success: true, text: text, confidence: 70, method: 'pdf_page_ocr' }
      ensure
        temp_pdf&.unlink
      end
    end
  rescue => e
    Rails.logger.error "PDF page OCR error: #{e.message}"
    fallback_processing
  end

  # Vérifie que le texte extrait contient suffisamment de lettres réelles.
  # Les PDFs avec encodage de police personnalisé (ex: VEKA Flandre) produisent du texte
  # composé uniquement de symboles ASCII (!"#$%&...) qui sont «imprimables» mais pas des lettres.
  def text_looks_valid?(text)
    return false if text.blank?
    non_space = text.gsub(/\s/, '')
    return false if non_space.empty?
    # Au moins 40% de lettres alphabétiques (a-z, accents) dans les caractères non-espaces
    alpha = non_space.scan(/[a-zA-ZÀ-ÿ]/).length
    alpha.to_f / non_space.length > 0.4
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
    file.rewind
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

  # ── Parse montant format belge : 15.100,00 → 15100.0 ────────────────────────
  # Disponible dans tous les sous-services (FactureOcr, DevisOcr, BordereauChassis)
  def parse_montant_belge(str)
    return nil if str.blank?
    # Supprimer tous les espaces (séparateurs visuels type "38 . 160 , 00")
    s = str.strip.gsub(/\s+/, '')

    # Format belge canonique : point = milliers, virgule = décimale (ex: 15.100,00)
    if s.match?(/^\d{1,3}(?:\.\d{3})+,\d{2}$/)
      return s.gsub('.', '').gsub(',', '.').to_f
    end

    # Format international : virgule = milliers, point = décimale (ex: 15,100.00)
    if s.match?(/^\d{1,3}(?:,\d{3})+\.\d{2}$/)
      return s.gsub(',', '').to_f
    end

    # Espace comme séparateur milliers (ex: 15 100,00 ou 15 100.00) — déjà nettoyé
    # Après gsub des espaces : "15100,00"
    if s.match?(/^\d+,\d{2}$/)
      return s.gsub(',', '.').to_f
    end

    if s.match?(/^\d+\.\d{2}$/)
      return s.to_f
    end

    # Fallback: virgule décimale simple
    s.gsub(/[^\d,.]/, '').gsub(',', '.').to_f.then { |v| v > 0 ? v : nil }
  end
end
