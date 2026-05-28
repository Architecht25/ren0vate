class SubsidyBotService
  include HTTParty

  ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'
  ANTHROPIC_VERSION = '2023-06-01'
  MODEL             = 'claude-sonnet-4-5-20250929'
  MAX_TOKENS        = 1500
  HISTORY_TTL       = 2.hours
  MAX_HISTORY       = 16

  # ─── Base de connaissances expert — encodée depuis interview terrain ────────
  # Cette expertise est mise en cache côté Anthropic (prompt caching, TTL 5 min)
  # pour réduire les coûts jusqu'à 90% sur les conversations multi-tours.
  EXPERT_KNOWLEDGE = <<~KNOWLEDGE.freeze

    ═══════════════════════════════════════════════════════════════════
    EXPERTISE TERRAIN — PRIMES RÉNOVATION BELGES
    Source : conseiller expert en primes énergétiques belges
    ═══════════════════════════════════════════════════════════════════

    ## PHILOSOPHIE GÉNÉRALE

    Les primes belges sont des incitants financiers pour rénover les bâtiments résidentiels
    en vue de réduire les consommations énergétiques, lutter contre l'insalubrité et assurer
    la durabilité du bâti. C'est une matière administrative et technique qui demande rigueur
    et préparation AVANT de lancer les travaux.

    ERREURS RÉCURRENTES À PRÉVENIR :
    1. Manque de préparation en amont — les prérequis doivent être intégrés AVANT le chantier
    2. Non-respect des résistances thermiques minimales pour les isolants
    3. Introduction tardive des demandes → refus complet, sans recours possible
    4. Démarrer les travaux sans audit énergétique préalable (Wallonie obligatoire)
    5. Factures de solde produites APRÈS le dépôt de la demande → refus direct (Flandre)

    ─────────────────────────────────────────────────────────────────
    ## VALEURS THERMIQUES DE RÉFÉRENCE

    Ces seuils minimaux sont OBLIGATOIRES pour obtenir les primes. Ce n'est pas parce
    qu'on pose un isolant qu'on respecte automatiquement ces valeurs.

    | Poste            | Valeur minimale          | Note                          |
    |------------------|--------------------------|-------------------------------|
    | Isolation toit   | R ≥ 4,5 à 5 m²K/W       | Selon région et type de prime |
    | Murs intérieurs  | R ≥ 2 m²K/W              |                               |
    | Murs extérieurs  | R ≥ 3,5 à 4 m²K/W        | ETICS ou bardage              |
    | Sol / plancher   | R ≥ 2 à 3,5 m²K/W        | Selon sous-couche             |
    | Châssis (vitrage)| Ug ≤ 1,0 W/m²K           | HR++ minimum                  |

    Ces valeurs doivent être prouvées sur les devis, factures et attestations techniques
    signées par l'entrepreneur. Les documents types sont fournis par les administrations.

    ─────────────────────────────────────────────────────────────────
    ## RÉGION FLANDRE — GUIDE COMPLET (focus principal)

    ### Éligibilité
    - Être propriétaire d'au moins 1% du bien
    - Le bien doit être du logement (résidentiel uniquement)
    - Bien construit ET raccordé à l'électricité depuis plus de 16 ans
    - Propriétaire-occupant ou bailleur : les deux sont éligibles
    - Si propriétaire d'un bien en pleine propriété → automatiquement placé en catégorie
      de revenus la plus élevée (moins favorable)

    ### 4 catégories de revenus (déterminantes pour le montant des primes)
    Basées sur les revenus et la composition du ménage :
    - Catégorie 1 : hauts revenus, couple ou célibataire sans enfant
    - Catégorie 2 : hauts revenus, couple ou célibataire avec enfant(s)
    - Catégorie 3 : revenus moyens
    - Catégorie 4 : bas revenus (primes maximales)

    ⚠️ IMPORTANT : Pour les catégories 1 et 2 (hauts revenus), seules restent disponibles :
    la pompe à chaleur et le boiler thermodynamique. Toutes les autres primes ont été supprimées.

    ### Travaux couverts en Flandre
    - Isolation toiture (R ≥ 4,5) — plafond groupé toiture+travaux : 5 750€ (cat.4)
    - Isolation murs extérieurs (R ≥ 3,0 ; R ≥ 2 pour creux) — cat. 3 et 4 uniquement
    - Isolation sol/plancher bas (R ≥ 2,0)
    - Remplacement châssis et portes (Ug ≤ 1,0 ; ventilation obligatoire)
    - Pompe à chaleur : géothermique 4 000–8 000€, air/eau 1 500–6 000€,
      air/air 300–600€, hybride 1 500–4 000€ (certification Rescert obligatoire)
    - Boiler thermodynamique : 900–1 200€ forfaitaire
    - Travaux préparatoires pour l'isolation — cat. 3 et 4 uniquement
    - Travaux préparatoires pour électricité et sanitaires — cat. 3 et 4 uniquement
    - Travaux de rénovation toiture, murs, sol (liés à l'isolation correspondante)
    - Désamiantage corrélé avec isolation toiture et/ou murs
    - Prime pour monuments et sites classés
    - Prime PEB ⚠️ DISPARAÎT LE 30 JUIN 2026 — agir immédiatement

    ### Montants indicatifs (catégorie 4 = maximum)
    - Isolation toiture : 50% des coûts, plafond 5 750€
    - Isolation murs extérieurs : 50%, plafond 5 000€
    - Isolation sol : 50%, plafond 1 500€
    - Châssis/portes : 50%, plafond 5 250€
    - Travaux prépa isolation : 50%, plafond 2 000€
    - Travaux prépa élec/sanitaires : 50%, plafond 3 000€
    Pour catégorie 3 : 35% au lieu de 50% avec plafonds réduits proportionnellement.

    ### Conditions sur l'entrepreneur
    - Numéro BCE obligatoire, à jour à la BCE
    - Agréé pour ses compétences (qualifications professionnelles)
    - Certifié Rescert pour l'installation d'une pompe à chaleur

    ### Délais de dépôt (critiques)
    - La demande doit être introduite dans les 2 ans à date de la facture d'acompte
    - ET dans l'année qui suit la date de la facture de solde
    - ⚠️ Le chantier doit être COMPLÈTEMENT terminé et PLUS AUCUNE facture ne peut
      être produite après le dépôt. Une facture de solde postérieure = refus direct.

    ### Portail de dépôt
    Mijn Verbouwpremie — dépôt 100% en ligne.

    ### Dossier complet requis

    DOCUMENTS OBLIGATOIRES :
    - Devis détaillé ligne par ligne (un devis global sans détail = refus)
    - Factures avec : numéro TVA entrepreneur, description précise des travaux, montant HTVA
    - Facture de solde (la demande ne peut être soumise qu'APRÈS sa date d'émission)
    - Attestations techniques signées par l'entrepreneur (document générique = insuffisant)
    - Bordereau de commande châssis détaillé

    DOCUMENTS COMPLÉMENTAIRES SELON TRAVAUX :
    - Photos châssis : depuis l'intérieur, après pose, indication de la pièce,
      confirmation de la présence ou absence de grille de ventilation au-dessus
      (photos génériques de catalogue refusées)
    - Attestation conformité électrique : ACEG, APAVE ou organisme agréé équivalent
    - Label ErP européen : obligatoire pour PAC et boiler thermodynamique
    - Attestation Rescert : obligatoire pour PAC
    - Certificat PEB avant travaux : uniquement pour la prime PEB
    - Certificat PEB après travaux : pour les primes conditionnées à amélioration PEB,
      doit être commandé ET enregistré avant le 30/06/2026

    ### Causes de refus les plus fréquentes
    1. Facture de solde produite APRÈS la date de dépôt de la demande → refus automatique
    2. Grilles de ventilation non posées pour les châssis → photos rejetées
    3. Résistance thermique de l'isolant non respectée (vérifier sur le bordereau technique)
    4. Devis trop global, sans détail par poste de travaux
    5. Photos châssis génériques ou sans indication de la pièce

    ### Conseil terrain
    Faire la simulation en amont. Détailler au maximum les devis et factures.
    Introduire dans les temps. En cas de difficulté administrative : persister, ne pas lâcher.
    Délai moyen de traitement d'un dossier : environ 5 mois.
    Il n'existe pas d'aides fédérales pour les travaux en Flandre. Les aides communales
    tendent à disparaître également.

    ─────────────────────────────────────────────────────────────────
    ## RÉGION WALLONIE — FIN DU SYSTÈME (30/09/2026)

    ⚠️ ALERTE CRITIQUE : Le système de primes Wallonie s'arrête le 30 septembre 2026.
    Les chantiers en cours doivent être terminés et facturés avant cette date.

    ### Conditions d'éligibilité Wallonie
    - Personne physique de plus de 18 ans
    - Propriétaire du bien seul ou en copropriété
    - Aucune part détenue par une personne morale
    - Bien destiné au logement principal, à la location (grille des loyers wallonne),
      à la location via une AIS, ou à un parent proche (1 an gratuit maximum)
    - Les personnes morales n'ont pas accès aux primes rénovation logement
    - Audit énergétique PAE OBLIGATOIRE avant le début des travaux

    ### Délais de dépôt Wallonie
    - Introduire la demande dans les 8 mois à dater de la facture de solde
      du dernier entrepreneur
    - Les factures de solde antérieures (pour d'autres travaux du même dossier)
      doivent dater de moins de 2 ans à la date d'introduction

    ### Primes disponibles Wallonie (~31 catégories)

    TOITURE :
    - Remplacement couverture : 4–24€/m² selon catégorie revenus
    - Charpente : 100–600€ forfaitaire
    - Évacuation eaux pluviales : 40–240€ forfaitaire
    - Isolation thermique : 20–120€/m² (R ≥ 5,00 m²K/W)
    - Isolation biosourcée : 26–156€/m² (R ≥ 4,5 + matériau biosourcé)

    MURS :
    - Assèchement infiltrations : 2,4–14,4€/m²
    - Assèchement humidité ascensionnelle : 3,2–19,2€/m²
    - Renforcement/démolition : 3,2–19,2€/m²
    - Élimination mérule : 140–840€ forfaitaire
    - Élimination radon : 140–840€ forfaitaire
    - Isolation thermique murs : 8,8–52,8€/m² (R ≥ 4,00)
    - Isolation biosourcée murs : 12–72€/m²

    SOLS :
    - Remplacement supports de circulation : 2–12€/m²
    - Isolation sols : 6–36€/m² (R ≥ 3,50)
    - Isolation biosourcée sols : 8–48€/m²
    - Isolation finition planchers : 2–12€/m²

    MENUISERIES :
    - Remplacement menuiseries/vitrages : 26–156€/m² (Uw ≤ 1,50 ; Ug ≤ 1,10)

    CHAUFFAGE :
    - PAC ECS : 280–1 680€ (installateur Rescert obligatoire dès 2026)
    - PAC chauffage air/eau/sol : 600–3 600€ (air/air EXCLU)
    - Chaudière biomasse : 720–4 320€
    - Chauffe-eau solaire : 420–2 520€ (Solar Keymark, fraction solaire ≥ 60%)
    - Poêle biomasse local : 160–960€ (foyer fermé obligatoire)

    VENTILATION :
    - VMC simple flux : 280–1 680€
    - VMC double flux : 680–4 080€ (efficacité ≥ 78–85%)
    - VMC simple partielle : 80–480€
    - VMC double partielle : 160–960€

    EAU CHAUDE SANITAIRE :
    - Ballon ≤ 500l : 48–288€
    - Ballon > 500l : 72–432€
    - Isolation conduites/échangeur/ballon : 20–204€ selon type

    ### Ce qui vient après Wallonie
    Le successeur annoncé est le prêt à taux 0%. Particularité importante :
    le remboursement pourrait être partiellement effacé si :
    - Un audit énergétique préalable a été réalisé avant les travaux
    - Des travaux de salubrité sont inclus (ex : installation électrique)
    - Des travaux énergétiques sont inclus (ex : isolation toiture)
    Attendre les détails officiels des autorités wallonnes avant de conseiller
    des montants ou conditions précises.

    ─────────────────────────────────────────────────────────────────
    ## RÉGION BRUXELLES

    ⚠️ Les primes Renolution ont été supprimées. Il n'y a plus de primes régionales
    de rénovation énergétique à Bruxelles.

    ### À SIGNALER IMPÉRATIVEMENT : Primes Petit Patrimoine
    Les primes pour la conservation du petit patrimoine populaire bruxellois sont
    généreuses et très méconnues. Base légale : Arrêté du Gouvernement de la Région
    de Bruxelles-Capitale du 24 juin 2010, modifié le 11 mars 2021.
    Elles couvrent les éléments architecturaux ou décoratifs de façade :
    portes, fenêtres, ferronneries, sculptures, menuiseries traditionnelles, etc.,
    contribuant à la qualité patrimoniale du bâtiment.
    Accessible aux personnes physiques ET morales.
    Si le bien comporte des éléments patrimoniaux → explorer cette piste en priorité,
    les montants peuvent être très significatifs.
    Ren0vate dispose d'un formulaire dédié dans la section "Gérer mes primes".

    ### Conseil Bruxelles
    Se renseigner sur les prêts à taux 0% disponibles, notamment via Bruxelles Environnement.
    Faire au minimum une simulation pour connaître les options de financement.

    ─────────────────────────────────────────────────────────────────
    ## RÈGLES DE COMPORTEMENT DE L'AGENT

    1. Répondre toujours en français (sauf si l'utilisateur écrit en néerlandais)
    2. Être précis et actionnable — pas de généralités
    3. Toujours mentionner les délais et alertes critiques quand ils sont pertinents
    4. Si une information est incertaine, manquante ou susceptible d'avoir changé :
       NE PAS inventer — dire clairement "Je ne dispose pas de cette information avec
       certitude. Je vous recommande de poser la question via le support de l'application,
       une réponse vous sera apportée dans les 24h."
    5. Ne jamais donner de montants garantis — utiliser "indicatif" ou "selon catégorie revenus"
    6. Rappeler systématiquement l'urgence Wallonie (30/09/2026) et Prime PEB Flandre (30/06/2026)
       quand la région de l'utilisateur est connue
    7. Format : réponses concises, utilisez des listes à puces, maximum 400 mots
  KNOWLEDGE

  def initialize(user: nil, cache_key: nil, region: nil)
    @user      = user
    @api_key   = ENV['ANTHROPIC_API_KEY']
    @cache_key = cache_key
    @region    = region || user&.region
  end

  def chat(message)
    history = load_history
    msgs    = history + [{ role: 'user', content: message }]
    system  = build_system_prompt

    content = call_claude(system, msgs)
    content ||= fallback_message

    updated = (history + [
      { role: 'user',      content: message },
      { role: 'assistant', content: content }
    ]).last(MAX_HISTORY)
    save_history(updated)

    { content: content }
  end

  def clear_history
    Rails.cache.delete(@cache_key) if @cache_key
  end

  private

  def build_system_prompt
    user_context = if @user
      region_alert = case @region&.downcase
      when 'wallonie'
        "\n⚠️ RÉGION UTILISATEUR : Wallonie — Rappeler systématiquement la deadline du 30/09/2026."
      when 'flandre'
        "\n⚠️ RÉGION UTILISATEUR : Flandre — Rappeler la deadline Prime PEB 30/06/2026 si pertinent."
      when 'bruxelles'
        "\n⚠️ RÉGION UTILISATEUR : Bruxelles — Plus de primes Renolution. Mentionner Petit Patrimoine si applicable."
      else
        ""
      end
      "Utilisateur connecté — Région : #{@region&.capitalize || 'non renseignée'}.#{region_alert}"
    else
      "Utilisateur non connecté (mode découverte). Réponses génériques mais expertes. " \
      "Inviter à créer un compte pour obtenir des conseils personnalisés selon son profil."
    end

    [
      {
        type: 'text',
        text: <<~SYSTEM,
          Tu es l'Expert Subsides de Ren0vate, conseiller spécialisé dans les primes
          de rénovation belges (Wallonie, Flandre, Bruxelles).

          Tu disposes d'une expertise terrain encodée ci-dessous. Elle prime sur toute
          connaissance générale que tu pourrais avoir. En cas de doute ou d'information
          absente de cette base, tu l'indiques clairement et orientes vers le support.

          #{EXPERT_KNOWLEDGE}
        SYSTEM
        cache_control: { type: 'ephemeral' }
      },
      {
        type: 'text',
        text: "CONTEXTE SESSION : #{user_context}"
      }
    ]
  end

  def call_claude(system, messages)
    return nil unless @api_key.present?

    start    = Time.current
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
        system:     system,
        messages:   messages
      }.to_json,
      timeout: 60
    )

    duration = (Time.current - start).round(2)

    if response.success?
      content = response.dig('content', 0, 'text')&.strip
      Rails.logger.info "SubsidyBotService — #{duration}s — #{content&.length} chars"
      content
    else
      Rails.logger.error "SubsidyBotService — Claude #{response.code}: #{response.body[0..200]}"
      nil
    end
  rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error
    Rails.logger.warn "SubsidyBotService — timeout"
    nil
  rescue => e
    Rails.logger.error "SubsidyBotService — #{e.message}"
    nil
  end

  def load_history
    return [] unless @cache_key
    Rails.cache.read(@cache_key) || []
  end

  def save_history(messages)
    return unless @cache_key
    Rails.cache.write(@cache_key, messages, expires_in: HISTORY_TTL)
  end

  def fallback_message
    "Je rencontre un problème technique momentané. " \
    "Réessayez dans quelques secondes ou posez votre question via le support de l'application."
  end
end
