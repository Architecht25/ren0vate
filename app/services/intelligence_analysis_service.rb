class IntelligenceAnalysisService
  include HTTParty

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-sonnet-4-6'
  MAX_TOKENS        = 2000

  # Contexte produit Ren0vate — mis en cache côté Anthropic (prompt caching)
  RENOV8_CONTEXT = <<~CTX.freeze
    Ren0vate est une plateforme SaaS belge de gestion du cycle de vie d'un bien immobilier.
    Elle couvre : achat → rénovation → vente (DIU) → location.

    Fonctionnalités actuelles :
    - Gestion de chantiers de rénovation (devis, factures, PV, avancement)
    - Simulation des primes énergétiques (Wallonie, Flandre — Bruxelles supprimé)
    - Dossier d'Intervention Ultérieure (DIU) pour la vente
    - Gestion locative (locataires, baux, loyers)
    - OCR documents (factures, devis, PEB, AER)
    - Chatbot IA contextuel
    - Vérification BCE des entrepreneurs
    - Collaboration architecte/entrepreneur sur les projets

    Stack : Ruby on Rails 8.1, PostgreSQL (prod), Stripe (abonnements SaaS), Heroku.
    Public cible : particuliers belges propriétaires + professionnels (architectes, entrepreneurs).
    Régions : Wallonie, Flandre, Bruxelles.
    Stade : 124 comptes existants, lancement commercial prévu octobre 2026.

    Enjeux stratégiques actuels :
    - Réglementation EPBD / DIU obligatoire à terme pour toute vente
    - PEB obligatoire Bruxelles : passoires F/G → label E minimum avant 2033
    - Fin progressive des primes Renolution Bruxelles
    - Marché locatif sous pression réglementaire (garanties, indexation)
  CTX

  def initialize
    @api_key = ENV['ANTHROPIC_API_KEY']
  end

  # Envoie les news scrapées à Claude et retourne l'analyse structurée
  def analyze(scraped_text)
    return fallback unless @api_key.present?

    messages = [
      {
        role: 'user',
        content: <<~MSG
          Voici les actualités de la semaine collectées depuis des sources belges officielles :

          #{scraped_text}

          ---

          Analyse ces informations dans le contexte de Ren0vate et réponds en français avec cette structure exacte :

          ## Résumé exécutif
          2-3 phrases sur ce qui s'est passé cette semaine dans notre secteur.

          ## Signaux importants pour Ren0vate
          Liste des éléments (réglementaires, concurrentiels, marché) qui impactent directement la plateforme.
          Pour chaque signal : **[PRIORITÉ: HAUTE/MOYENNE/FAIBLE]** — description + impact concret sur Ren0vate.

          ## 3 suggestions d'évolution produit
          Basées uniquement sur les actualités de cette semaine.
          Format : **Suggestion** — Justification courte (basée sur telle news) — Effort estimé (S/M/L).

          ## À surveiller la semaine prochaine
          1-2 sujets à garder en radar.
        MSG
      }
    ]

    call_claude(messages)
  end

  private

  def call_claude(messages)
    start = Time.current

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
        system:     [
          {
            type: 'text',
            text: RENOV8_CONTEXT,
            cache_control: { type: 'ephemeral' }
          }
        ],
        messages: messages
      }.to_json,
      timeout: 120
    )

    duration = (Time.current - start).round(2)

    if response.success?
      content = response.dig('content', 0, 'text')&.strip
      Rails.logger.info "IntelligenceAnalysisService — #{duration}s — #{content&.length} chars"
      content
    else
      Rails.logger.error "IntelligenceAnalysisService — Claude #{response.code}: #{response.body[0..300]}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn "IntelligenceAnalysisService — timeout après #{(Time.current - start).round(2)}s"
    nil
  rescue => e
    Rails.logger.error "IntelligenceAnalysisService — #{e.message}"
    nil
  end

  def fallback
    "⚠️ Analyse indisponible — ANTHROPIC_API_KEY manquante."
  end
end
