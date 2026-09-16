module Bots
  # Partie infra commune aux bots contextuels (client / pro) : appel Claude,
  # historique de conversation en cache, tranches de montants pour les prompts.
  # La construction du system prompt et du contexte reste propre à chaque bot
  # (données visibles très différentes selon le public).
  module ClaudeChatClient
    MAX_HISTORY = 20 # messages gardés en mémoire (10 échanges)
    HISTORY_TTL = 2.hours

    def call_claude(model, system, messages)
      return nil unless @api_key.present?

      start = Time.current
      message = client.messages.create(
        model:      model,
        max_tokens: 1200,
        system_:    system,
        messages:   messages,
        request_options: { timeout: 60 }
      )

      duration = (Time.current - start).round(2)

      text_block = message.content.find { |b| b.type == :text }
      content = text_block&.text&.strip
      Rails.logger.info "✅ #{log_prefix} #{model} — #{duration}s — #{content&.length} chars"
      content
    rescue Anthropic::Errors::APITimeoutError
      Rails.logger.warn "⏰ #{log_prefix} timeout après #{(Time.current - start).round(2)}s"
      nil
    rescue Anthropic::Errors::APIError => e
      Rails.logger.error "❌ #{log_prefix} Claude API error: #{e.message}"
      nil
    rescue => e
      Rails.logger.error "🔥 #{log_prefix} error: #{e.message}"
      nil
    end

    def client
      @client ||= Anthropic::Client.new(api_key: @api_key)
    end

    def load_history
      return [] unless @cache_key
      Rails.cache.read(@cache_key) || []
    end

    def save_history(messages)
      return unless @cache_key
      Rails.cache.write(@cache_key, messages, expires_in: HISTORY_TTL)
    end

    # Tranches pour les montants (chantiers/devis/primes) — calées sur les
    # ordres de grandeur des barèmes belges. Évite de transmettre des montants
    # exacts à l'API Anthropic (minimisation RGPD).
    def amount_bracket(amount)
      return 'N/A' unless amount
      val = amount.to_f
      case val
      when 0...1_000 then "< 1 000 €"
      when 1_000...5_000 then "1 000–5 000 €"
      when 5_000...10_000 then "5 000–10 000 €"
      when 10_000...20_000 then "10 000–20 000 €"
      when 20_000...35_000 then "20 000–35 000 €"
      when 35_000...50_000 then "35 000–50 000 €"
      when 50_000...75_000 then "50 000–75 000 €"
      when 75_000...100_000 then "75 000–100 000 €"
      when 100_000...150_000 then "100 000–150 000 €"
      when 150_000...250_000 then "150 000–250 000 €"
      else "> 250 000 €"
      end
    end

    private

    def log_prefix
      self.class.name.demodulize
    end
  end
end
