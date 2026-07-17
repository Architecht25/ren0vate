# MarketingDraftJob
# Génère automatiquement les 4 livrables marketing (article blog + 3 posts sociaux)
# à partir d'un IntelligenceReport via Claude, puis crée/met à jour le MarketingWeek.
#
# Déclenché automatiquement depuis IntelligenceReportJob après chaque analyse complète.
# Peut aussi être lancé manuellement :
#   MarketingDraftJob.perform_later(report_id)
#   MarketingDraftJob.perform_now(report_id)
class MarketingDraftJob < ApplicationJob
  include HTTParty

  queue_as :default

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  CLAUDE_MODEL      = 'claude-sonnet-4-6'

  # Prompt système — identique à ~/agents-hub/.../prompts/system_marketing.md
  MARKETING_SYSTEM_PROMPT = <<~PROMPT.freeze
    ## IDENTITÉ DE LA MARQUE

    Ren0vate est une plateforme SaaS belge de gestion de chantiers de rénovation.
    Tagline : "Rénover coûte plus cher, prend plus de temps, et les aides diminuent. Ren0vate est la réponse."
    Positionnement : "Le Slack de la rénovation" — remplace le chaos, pas l'expertise des pros.
    Marché : Belgique (Wallonie, Flandre, Bruxelles). Langue principale : français. Secondaire : néerlandais.

    ---

    ## TON ET CONTRAINTES RÉDACTIONNELLES

    - Ton belge — ni trop formel, ni startup américaine
    - Jamais de jargon tech ou anglicismes inutiles
    - Terminologie obligatoire : "entrepreneur agréé", "avertissement-extrait de rôle", "primes énergétiques", "chantier de rénovation"
    - Toujours chiffrer : montants de primes, heures récupérées, ROI abonnement — les chiffres sont les meilleurs arguments
    - Un seul CTA par contenu — pas de multi-CTA
    - Phrases courtes, structure lisible (listes, chiffres en gras)
    - Urgences à intégrer selon contexte :
      - Wallonie : fin des primes cash le 30/09/2026, remplacées dès le 01/10/2026 par une
        réduction du solde d'un prêt bonifié (Rénopack/Rénoprêt) — rappeler systématiquement
      - Flandre : depuis le 01/03/2026, catégories de revenus 1 et 2 limitées aux primes
        pompe à chaleur/boiler — la prime PEB/EPC-label a disparu, ne plus la mentionner
      - Général : matériaux +40% depuis 2020, chaque mois de flottement = +0,4% de coût

    ---

    ## MESSAGES COMMERCIAUX CLÉS

    ### Message central
    "Un projet de rénovation coûte 40% de plus qu'en 2020, les aides diminuent, et chaque mois de retard coûte de l'argent. Ren0vate est la réponse."

    ### Par segment

    **Propriétaires (B2C — 39€/mois)**
    "39€/mois pour récupérer 40 heures. Calculez votre ROI en 30 secondes."

    **Investisseurs multi-biens (B2C — 89€/mois)**
    "Gérez 10 biens comme si vous en aviez 1. Avec le même niveau de contrôle."

    **Professionnels — architectes & entrepreneurs (B2B — 99€/mois)**
    "Vos clients organisés. Votre chantier traçable. Votre temps recentré sur le travail à valeur ajoutée."

    **Argument primes (tous segments)**
    "Ne pas utiliser Ren0vate, c'est laisser de l'argent sur la table. Notre IA détecte en moyenne 25% d'aides supplémentaires vs vos propres recherches."

    ---

    ## 5 PILIERS ÉDITORIAUX

    ### Pilier 1 — Urgence financière (Matériaux + Taux)
    Angle : Le coût de l'inaction en rénovation. Argument : Matériaux +40% depuis 2020.

    ### Pilier 2 — Primes (Ne pas laisser expirer ses droits)
    Angle : Les primes existent encore mais se complexifient.
    Urgences : Wallonie → primes cash jusqu'au 30/09/2026, puis réduction de prêt bonifié
    (plafond 75 000€, PEB E/F/D requis). Flandre → catégories 1-2 limitées à PAC/boiler depuis 01/03/2026.

    ### Pilier 3 — Automatisation (Récupérer son temps)
    Angle : 49 à 97h perdues par projet de rénovation sans outil. Ren0vate récupère 40h/projet.

    ### Pilier 4 — Expert IA (Différenciation vs ChatGPT)
    Angle : Un IA généraliste vs un expert contextualisé à votre bien.

    ### Pilier 5 — B2B Pros (Clients mieux préparés)
    Angle : Un architecte perd 5 à 10h/semaine à cause de clients désorganisés.
  PROMPT

  def perform(report_id)
    report = IntelligenceReport.find_by(id: report_id)
    unless report&.completed?
      Rails.logger.warn "MarketingDraftJob — rapport #{report_id} introuvable ou non complété, skip."
      return
    end

    if MarketingWeek.exists?(week_of: report.week_of)
      Rails.logger.info "MarketingDraftJob — MarketingWeek #{report.week_of} déjà présent, skip."
      return
    end

    api_key = ENV['ANTHROPIC_API_KEY']
    unless api_key.present?
      Rails.logger.error "MarketingDraftJob — ANTHROPIC_API_KEY manquante, abort."
      return
    end

    Rails.logger.info "MarketingDraftJob — démarrage #{report.week_of}"

    veille = { 'week_of' => report.week_of, 'analysis' => report.analysis }

    article_raw    = call_claude(api_key, article_prompt(veille))
    linkedin_raw   = call_claude(api_key, linkedin_prompt(veille))
    instagram_raw  = call_claude(api_key, instagram_prompt(veille))
    facebook_raw   = call_claude(api_key, facebook_prompt(veille))

    article_data = parse_article(article_raw)
    article      = build_article(article_data) if article_data

    week = MarketingWeek.new(
      week_of:        report.week_of,
      status:         'draft',
      linkedin_post:  linkedin_raw,
      instagram_post: instagram_raw,
      facebook_post:  facebook_raw,
      generated_at:   Time.current,
      article:        article
    )

    if week.save
      Rails.logger.info "MarketingDraftJob — #{report.week_of} sauvegardé (id=#{week.id})"
    else
      Rails.logger.error "MarketingDraftJob — échec sauvegarde : #{week.errors.full_messages.join(', ')}"
    end

  rescue => e
    Rails.logger.error "MarketingDraftJob — erreur : #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    # Non bloquant — on ne re-raise pas pour ne pas polluer la queue
  end

  private

  def call_claude(api_key, user_prompt)
    response = HTTParty.post(
      ANTHROPIC_API_URL,
      headers: {
        'x-api-key'         => api_key,
        'anthropic-version' => ANTHROPIC_VERSION,
        'content-type'      => 'application/json'
      },
      body: {
        model:      CLAUDE_MODEL,
        max_tokens: 2048,
        system:     MARKETING_SYSTEM_PROMPT,
        messages:   [{ role: 'user', content: user_prompt }]
      }.to_json,
      timeout: 120
    )

    unless response.success?
      Rails.logger.error "MarketingDraftJob — Claude HTTP #{response.code}"
      return nil
    end

    data = response.parsed_response
    data.dig('content', 0, 'text')&.strip
  rescue => e
    Rails.logger.error "MarketingDraftJob — call_claude erreur : #{e.message}"
    nil
  end

  def parse_article(raw)
    return nil if raw.nil? || raw.strip.empty?

    lines   = raw.lines
    title   = lines.find { |l| l.start_with?('TITRE:') }&.sub('TITRE:', '')&.strip
    excerpt = lines.find { |l| l.start_with?('EXTRAIT:') }&.sub('EXTRAIT:', '')&.strip
    cat     = lines.find { |l| l.start_with?('CATEGORIE:') }&.sub('CATEGORIE:', '')&.strip&.downcase
    sep_idx = lines.index { |l| l.strip == '---' }
    content = sep_idx ? lines[(sep_idx + 1)..].join.strip : raw

    return nil if title.blank? || excerpt.blank? || content.blank?

    { title: title, excerpt: excerpt, category: cat, content: content }
  end

  def build_article(data)
    cat = Article::CATEGORIES.key?(data[:category]) ? data[:category] : 'conseils'
    Article.new(
      title:    data[:title],
      excerpt:  data[:excerpt],
      category: cat,
      content:  data[:content]
    )
  end

  # ── Prompts (identiques à marketing_agent.rb) ───────────────────────────────

  def article_prompt(veille)
    <<~PROMPT
      Voici le rapport de veille de la semaine (#{veille['week_of']}) :

      #{veille['analysis']}

      ---

      En exploitant UN signal fort de cette veille comme accroche d'actualité, rédige un article de blog SEO complet pour Ren0vate.

      Commence par les 4 lignes de métadonnées EXACTEMENT dans ce format (sans aucun texte avant) :
      TITRE: [titre SEO accrocheur, max 70 caractères]
      EXTRAIT: [2 phrases pour le chapeau, max 200 caractères]
      CATEGORIE: [une seule valeur parmi : primes / conseils / actualites / permis / pros]
      ---

      Puis l'article complet en Markdown (1 000–1 200 mots) :
      - Commence par # suivi du titre (identique à TITRE:)
      - Structure : chapeau 2 phrases + 3–4 sections H2 + conclusion
      - Un seul CTA en fin d'article : "Essayez Ren0vate gratuitement → ren0vate.be"
      - Ton belge, chiffré, concret — aucun jargon startup
      - Intégrer naturellement les mots-clés SEO selon le sujet
    PROMPT
  end

  def linkedin_prompt(veille)
    <<~PROMPT
      Voici le rapport de veille de la semaine (#{veille['week_of']}) :

      #{veille['analysis']}

      ---

      En exploitant UN signal de cette veille, rédige un post LinkedIn pour Ren0vate ciblant les professionnels (architectes, entrepreneurs, gestionnaires de patrimoine).

      Contraintes :
      - Longueur : 200–300 mots
      - Structure LinkedIn : 2–3 lignes d'accroche (hook fort) → développement → CTA
      - Émojis : 1 max par paragraphe
      - Angle B2B : les pros perdent du temps et de l'argent → Ren0vate résout ça avec un chiffre concret
      - Finir par une question qui invite les commentaires
      - 2–3 hashtags pertinents, pas génériques
      - Un seul CTA : lien ren0vate.be ou invitation à répondre en commentaire

      Réponse : le post prêt à publier, sans introduction ni commentaire.
    PROMPT
  end

  def instagram_prompt(veille)
    <<~PROMPT
      Voici le rapport de veille de la semaine (#{veille['week_of']}) :

      #{veille['analysis']}

      ---

      En exploitant UN signal de cette veille, rédige un post Instagram pour Ren0vate (B2C, propriétaires belges 35–60 ans).

      Contraintes post :
      - Longueur : 80–120 mots
      - 1ère phrase : accroche forte (chiffre ou fait surprenant)
      - Ton : direct, accessible, encourageant
      - Urgences si pertinentes : Wallonie (fin primes cash 30/09/2026, prêt bonifié ensuite)
      - 3–5 hashtags pertinents en fin de post
      - Un seul CTA : "lien en bio" ou "ren0vate.be"

      Ajoute ensuite, séparé par une ligne "---", un brief visuel :
      BRIEF VISUEL : [description précise du visuel idéal — ce qu'on montre, ambiance, couleurs, style]

      Réponse : le post + brief visuel, sans introduction ni commentaire.
    PROMPT
  end

  def facebook_prompt(veille)
    <<~PROMPT
      Voici le rapport de veille de la semaine (#{veille['week_of']}) :

      #{veille['analysis']}

      ---

      En exploitant UN signal de cette veille, rédige un post Facebook pour Ren0vate (B2C, propriétaires et investisseurs belges).

      Contraintes :
      - Longueur : 100–150 mots
      - 1ère phrase : accroche forte avec chiffre ou urgence concrète
      - Ton : informatif, rassurant, chiffré — pas de hashtags
      - Urgences si pertinentes : Wallonie (fin primes cash 30/09/2026, prêt bonifié ensuite)
      - Inclure l'URL ren0vate.be naturellement dans le texte
      - Un seul CTA explicite en dernière ligne

      Ajoute ensuite, séparé par une ligne "---", un brief visuel :
      BRIEF VISUEL : [description précise du visuel idéal — ce qu'on montre, ambiance, couleurs, style]

      Réponse : le post + brief visuel, sans introduction ni commentaire.
    PROMPT
  end
end
