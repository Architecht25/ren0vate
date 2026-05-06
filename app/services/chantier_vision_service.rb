class ChantierVisionService
  include HTTParty
  require 'base64'

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-sonnet-4-5-20250929'
  MAX_PHOTOS        = 6   # limite pour garder le coût raisonnable
  MAX_TOKENS        = 1500

  # Hôtes autorisés pour le fetch d'images (prévention SSRF)
  TRUSTED_IMAGE_HOSTS = %w[
    res.cloudinary.com
    res-1.cloudinary.com
    res-2.cloudinary.com
    res-3.cloudinary.com
    res-4.cloudinary.com
  ].freeze

  PHOTO_TYPES = {
    'photo_avant'   => 'avant travaux',
    'photo_pendant' => 'en cours de travaux',
    'photo_apres'   => 'après travaux',
    'photo_chassis' => 'châssis/fenêtres'
  }.freeze

  def initialize(project)
    @project = project
    @api_key = ENV['ANTHROPIC_API_KEY']
  end

  # Retourne { success:, avancement:, observations:, alertes:, prochaines_etapes:, analysed_count: }
  def call
    return error_result('Clé API manquante') unless @api_key.present?

    photos = fetch_photos
    return error_result('Aucune photo de chantier disponible') if photos.empty?

    image_blocks = build_image_blocks(photos)
    return error_result('Aucune URL photo accessible') if image_blocks.empty?

    response = call_claude(image_blocks, photos)
    return error_result('Pas de réponse de Claude') unless response

    parsed = parse_response(response)
    parsed.merge(success: true, analysed_count: image_blocks.size)
  rescue => e
    Rails.logger.error "ChantierVisionService error: #{e.message}"
    error_result("Erreur d'analyse : #{e.message}")
  end

  private

  def fetch_photos
    @project.documents
            .where(type_document: PHOTO_TYPES.keys)
            .order(created_at: :desc)
            .first(MAX_PHOTOS)
  end

  def build_image_blocks(photos)
    blocks = []
    photos.each do |doc|
      url = public_url(doc)
      next unless image_content_type?(doc)

      if url.present? && url.start_with?('https://')
        # URL HTTPS publique (Cloudinary en production)
        blocks << {
          type: 'image',
          source: { type: 'url', url: url }
        }
      else
        # Fallback base64 (dev local ou URL HTTP)
        b64 = encode_image_base64(doc)
        next unless b64
        blocks << {
          type: 'image',
          source: { type: 'base64', media_type: 'image/jpeg', data: b64 }
        }
      end
    end
    blocks
  end

  def encode_image_base64(doc)
    if doc.file.attached?
      Base64.strict_encode64(doc.file.download)
    elsif doc.file_url.present?
      return nil unless trusted_image_url?(doc.file_url)

      response = HTTParty.get(doc.file_url, timeout: 15)
      return nil unless response.success?
      Base64.strict_encode64(response.body)
    end
  rescue => e
    Rails.logger.warn "ChantierVisionService base64 encode failed: #{e.message}"
    nil
  end

  def trusted_image_url?(url)
    uri = URI.parse(url)
    uri.scheme == 'https' &&
      TRUSTED_IMAGE_HOSTS.any? { |host| uri.host == host || uri.host&.end_with?(".cloudinary.com") }
  rescue URI::InvalidURIError
    false
  end

  def call_claude(image_blocks, photos)
    # Construit la liste des types de photos présents pour le contexte
    photo_context = photos.map { |d| PHOTO_TYPES[d.type_document] }.uniq.join(', ')

    messages = [
      {
        role: 'user',
        content: image_blocks + [
          {
            type: 'text',
            text: build_prompt(photo_context)
          }
        ]
      }
    ]

    response = HTTParty.post(
      ANTHROPIC_API_URL,
      headers: {
        'x-api-key'         => @api_key,
        'anthropic-version' => ANTHROPIC_VERSION,
        'anthropic-beta'    => 'prompt-caching-2024-07-31',
        'content-type'      => 'application/json'
      },
      body: {
        model:      MODEL,
        max_tokens: MAX_TOKENS,
        system:     system_prompt,
        messages:   messages
      }.to_json,
      timeout: 60
    )

    if response.success?
      response.dig('content', 0, 'text')&.strip
    else
      Rails.logger.error "ChantierVisionService Claude #{response.code}: #{response.body[0..200]}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn 'ChantierVisionService: timeout Claude'
    nil
  end

  def system_prompt
    [{
      type: 'text',
      text: <<~PROMPT,
        Tu es un expert en suivi de chantier de rénovation résidentielle en Belgique.
        Tu analyses des photos de chantier et fournis un rapport structuré clair et actionnable.
        Réponds TOUJOURS en JSON valide avec exactement ces clés :
        {
          "avancement": <entier 0-100>,
          "phase": "<phase actuelle ex: Démolition, Gros œuvre, Second œuvre, Finitions, Terminé>",
          "observations": ["<observation 1>", "<observation 2>"],
          "alertes": ["<alerte si anomalie visible, vide sinon>"],
          "prochaines_etapes": ["<étape 1>", "<étape 2>"]
        }
      PROMPT
      cache_control: { type: 'ephemeral' }
    }]
  end

  def build_prompt(photo_context)
    context = []
    context << "Projet : #{@project.nom}" if @project.nom.present?
    context << "Type travaux : #{@project.travaux_type}" if @project.respond_to?(:travaux_type) && @project.travaux_type.present?
    context << "Statut déclaré : #{@project.statut}" if @project.statut.present?
    context << "Photos fournies : #{photo_context}"

    <<~PROMPT
      #{context.join("\n")}

      Analyse ces #{photo_context.split(',').size > 1 ? 'photos' : 'photo'} de chantier et retourne le JSON demandé.
      Base-toi uniquement sur ce que tu vois réellement. Si une information n'est pas visible, ne l'invente pas.
    PROMPT
  end

  def parse_response(raw)
    json_str = raw[/\{.*\}/m]
    data = JSON.parse(json_str)

    {
      avancement:      [0, [data['avancement'].to_i, 100].min].max,
      phase:           data['phase']&.strip || 'Indéterminée',
      observations:    Array(data['observations']).first(5),
      alertes:         Array(data['alertes']).reject(&:blank?),
      prochaines_etapes: Array(data['prochaines_etapes']).first(3)
    }
  rescue JSON::ParserError
    Rails.logger.warn "ChantierVisionService: JSON parse failed — raw: #{raw[0..300]}"
    {
      avancement:       0,
      phase:            'Analyse partielle',
      observations:     [raw[0..500]],
      alertes:          [],
      prochaines_etapes: []
    }
  end

  def public_url(doc)
    doc.file_url.presence || doc.cloudinary_url
  end

  def image_content_type?(doc)
    return true unless doc.file.attached?
    doc.file.content_type.to_s.start_with?('image/')
  end

  def error_result(message)
    { success: false, error: message }
  end
end
