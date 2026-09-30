module Bots
  # TravauxDetectionClaudeService
  #
  # Détecte, à partir du texte libre d'un projet (nom + description), les types
  # de travaux concernés parmi la liste fermée connue de
  # Projects::PermisPredicatorService::REGLES_TRAVAUX. Remplace le simple
  # matching par mots-clés sur ce texte libre — le reste du moteur de règles
  # (délais, documents requis, alertes régionales) reste inchangé.
  #
  # Retourne nil (jamais d'exception) si la clé API est absente, si Claude ne
  # répond pas, ou si la réponse est invalide/vide après filtrage — l'appelant
  # doit alors retomber sur le matching par mots-clés.
  class TravauxDetectionClaudeService
    MODEL      = 'claude-haiku-4-5-20251001'
    MAX_TOKENS = 300

    def initialize(texte)
      @texte = texte.to_s.strip
    end

    def detect
      return nil if @texte.blank?

      api_key = ENV['ANTHROPIC_API_KEY']
      unless api_key.present?
        Rails.logger.warn 'TravauxDetectionClaudeService: ANTHROPIC_API_KEY absent → fallback mots-clés'
        return nil
      end

      raw_response = call_claude(api_key)
      return nil unless raw_response

      types = parse_claude_response(raw_response)
      return nil if types.blank?

      valides = types & Projects::PermisPredicatorService::REGLES_TRAVAUX.keys.map(&:to_s)
      valides.presence&.map(&:to_sym)
    rescue StandardError => e
      Rails.logger.error "TravauxDetectionClaudeService error: #{e.message}"
      nil
    end

    private

    def call_claude(api_key)
      message = Anthropic::Client.new(api_key: api_key).messages.create(
        model:      MODEL,
        max_tokens: MAX_TOKENS,
        system_:    system_prompt,
        messages:   [{
          role:    'user',
          content: "Description du projet :\n\n#{@texte}\n\nIdentifie les types de travaux en JSON."
        }],
        request_options: { timeout: 20 }
      )

      text_block = message.content.find { |b| b.type == :text }
      text_block&.text&.strip
    rescue Anthropic::Errors::APITimeoutError
      Rails.logger.warn 'TravauxDetectionClaudeService: timeout Claude'
      nil
    rescue Anthropic::Errors::APIError => e
      Rails.logger.error "TravauxDetectionClaudeService Claude error: #{e.message}"
      nil
    end

    def system_prompt
      travaux_liste = Projects::PermisPredicatorService::REGLES_TRAVAUX.map do |key, rule|
        "- #{key} : #{rule[:note]}"
      end.join("\n")

      [{
        type: 'text',
        text: <<~PROMPT,
          Tu es un expert en urbanisme belge. Tu lis la description libre d'un projet
          de rénovation résidentielle (en français ou néerlandais) et tu identifies
          UNIQUEMENT les types de travaux concernés parmi cette liste fermée :

          #{travaux_liste}

          RÈGLES :
          - Ne retourne QUE des clés présentes dans la liste ci-dessus, jamais une
            valeur inventée.
          - Une description peut correspondre à plusieurs types de travaux.
          - Si aucun type de la liste ne correspond clairement, retourne un tableau vide.
          - Ne déduis pas de travaux non mentionnés ou non clairement sous-entendus.

          Réponds UNIQUEMENT avec un objet JSON valide (aucun markdown, aucune
          explication) :
          { "types": ["cle_1", "cle_2"] }
        PROMPT
        cache_control: { type: 'ephemeral' }
      }]
    end

    def parse_claude_response(raw)
      json_str = raw[/\{.*\}/m]
      return nil unless json_str

      data = JSON.parse(json_str)
      types = data['types']
      return nil unless types.is_a?(Array)

      types.map(&:to_s)
    rescue JSON::ParserError => e
      Rails.logger.warn "TravauxDetectionClaudeService JSON parse: #{e.message}"
      nil
    end
  end
end
