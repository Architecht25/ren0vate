class ContextualBotService
  include HTTParty

  # Cache des réponses communes (durée 1 heure)
  CACHE_DURATION = 1.hour

  # Réponses instantanées pré-calculées pour les questions les plus courantes
  INSTANT_RESPONSES = {
    'bonjour' => "👋 **Bonjour !** Je suis votre assistant Ren0vate.\n\nJe peux vous aider avec :\n• Les primes énergétiques des 3 régions\n• L'optimisation de vos demandes\n• Les démarches administratives\n\n💡 Comment puis-je vous aider aujourd'hui ?",
    'aide' => "🆘 **Aide Ren0vate**\n\nVoici ce que je peux faire :\n• 🏠 **Mode Guide** : Conseils pratiques par étape\n• 🧠 **Mode Expert** : Réponses détaillées avec IA\n• 📊 **Suggestions** : Recommandations contextuelles\n\n✨ Basculez entre les modes selon vos besoins !",
    'comment ça marche' => "⚙️ **Fonctionnement de Ren0vate**\n\n1. 📋 **Profil** : Renseignez vos informations\n2. 🏠 **Bien** : Décrivez votre propriété\n3. ⚡ **Travaux** : Sélectionnez vos projets\n4. 💰 **Simulation** : Découvrez vos primes\n5. 📄 **Documents** : Préparez votre dossier\n\n🎯 Utilisez le **Hub de Décision** pour une stratégie complète !",
    'merci' => "😊 **De rien !** C'est un plaisir de vous accompagner dans vos projets de rénovation énergétique.\n\n💪 Ensemble, optimisons vos primes et rendons votre logement plus confortable et économe !\n\n🔄 N'hésitez pas si vous avez d'autres questions.",
    'primes wallonie' => "🏛️ **Primes Wallonie - Habitation Plus**\n\n💰 **Montants** :\n• Jusqu'à 70% des coûts selon revenus\n• Plafonds élevés pour isolation et chauffage\n• Bonus pour logement de +20 ans\n\n📋 **Conditions** :\n• Entrepreneurs agréés obligatoires\n• Devis avant travaux\n• Audit énergétique recommandé\n\n✅ Utilisez notre simulateur pour un calcul précis !",
    'primes bruxelles' => "🏢 **Primes Bruxelles - Renolution**\n\n💰 **Avantages** :\n• Primes régionales + communales cumulables\n• Bonus rénovation globale important\n• Accompagnement gratuit disponible\n\n📋 **Spécificités** :\n• Logement de +10 ans minimum\n• Entrepreneurs agréés requis\n• Audit énergétique subventionné\n\n🎯 Optimisez avec nos recommandations !",
    'primes flandre' => "🇳🇱 **Primes Flandre - Mijn Verbouw Premie**\n\n💰 **Système** :\n• Montants selon catégorie de revenus\n• Primes techniques + bonus énergie\n• Cumul possible avec primes communales\n\n📋 **Particularités** :\n• Demande après travaux uniquement\n• Entrepreneurs agréés VLAIO\n• E-peil amélioration requise\n\n🔍 Vérifiez votre éligibilité dans la simulation !",
    'isolation' => "🏠 **Isolation - Priorité N°1**\n\n⚡ **Ordre recommandé** :\n1. **Toiture** : jusqu'à 30% d'économies\n2. **Murs** : 20-25% d'économies\n3. **Sol** : 10-15% d'économies\n4. **Fenêtres** : amélioration confort\n\n💰 **Primes élevées** :\n• R-values minimales à respecter\n• Matériaux certifiés requis\n• Entrepreneurs agréés obligatoires\n\n🎯 Commencez par un audit énergétique !",
    'chauffage' => "🔥 **Systèmes de Chauffage Durables**\n\n⚡ **Options performantes** :\n• **Pompe à chaleur** : COP élevé, primes importantes\n• **Chaudière condensation** : efficient, abordable\n• **Solaire thermique** : eau chaude gratuite\n• **Pellets** : renouvelable, confortable\n\n💰 **Primes attractives** :\n• Jusqu'à 50% du coût selon région\n• Bonus remplacement ancienne chaudière\n• Cumul avec primes isolation\n\n📊 Simulez vos économies avec notre outil !",
    'audit' => "📊 **Audit Énergétique - Votre Feuille de Route**\n\n🎯 **Avantages** :\n• Diagnostic complet du logement\n• Recommandations hiérarchisées\n• Calcul ROI des investissements\n• Obligatoire pour certaines primes\n\n💰 **Coût** :\n• 200-500€ selon région\n• Subventionné à 75-100%\n• Amortissement rapide\n\n✅ **Démarche** :\n1. Choisir auditeur agréé\n2. Visite technique (2-3h)\n3. Rapport détaillé sous 15j\n4. Plan d'action personnalisé",
    'entrepreneur' => "👷 **Choisir un Entrepreneur Agréé**\n\n✅ **Vérifications obligatoires** :\n• Agrément régional valide\n• Assurance RC et décennale\n• Références et avis clients\n• Devis détaillé et conforme\n\n🔍 **Où vérifier** :\n• **Wallonie** : Portail de l'Énergie\n• **Bruxelles** : Base de données Renolution\n• **Flandre** : VLAIO entrepreneurs\n\n⚠️ **Attention** :\n• Pas d'acompte > 20%\n• Délai de rétractation 14j\n• Garanties écrites obligatoires",
    'documents' => "📄 **Documents Essentiels**\n\n📋 **Avant travaux** :\n• Devis détaillé entrepreneur agréé\n• Preuves revenus (avertissement fiscal)\n• Photos état existant\n• Permis si nécessaire\n\n📋 **Après travaux** :\n• Factures détaillées\n• Certificats matériaux\n• Photos travaux finis\n• PV réception travaux\n\n💡 **Conseil** : Préparez tout en amont pour éviter les retards de paiement !"
  }.freeze

  def initialize(user = nil)
    @user = user
    @api_key = ENV['OPENAI_API_KEY']
    @base_url = 'https://api.openai.com/v1/chat/completions'
  end

  def get_expert_response(message, locale = :fr)
    unless @api_key.present?
      Rails.logger.info "🔑 Clé OpenAI manquante - Fallback activé"
      return generate_expert_fallback(message, 'general')
    end

    begin
      Rails.logger.info "🚀 OpenAI Request - Message: #{message[0..40]}..."
      start_time = Time.current

      prompt = build_expert_prompt(message, locale)

      # Configuration optimisée pour réponses rapides ET de qualité
      response = HTTParty.post(@base_url,
        headers: {
          'Authorization' => "Bearer #{@api_key}",
          'Content-Type' => 'application/json'
        },
        body: {
          model: 'gpt-4o-mini', # Modèle plus rapide et moins cher
          messages: [
            {
              role: 'system',
              content: system_prompt(locale)
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          max_tokens: 400, # Optimisé pour réponses concises
          temperature: 0.1, # Plus déterministe = plus rapide
          top_p: 0.8,      # Réduit pour performance
          frequency_penalty: 0.0 # Supprimé pour rapidité
        }.to_json,
        timeout: 10 # Timeout augmenté à 10 secondes
      )

      duration = (Time.current - start_time).round(2)
      Rails.logger.info "⏱️ OpenAI Response Time: #{duration}s"

      if response.success?
        content = response.dig('choices', 0, 'message', 'content')
        if content.present?
          Rails.logger.info "✅ OpenAI SUCCESS - #{content.length} chars en #{duration}s"
          return content.strip
        else
          Rails.logger.error "❌ OpenAI Empty Response"
        end
      else
        Rails.logger.error "❌ OpenAI API Error #{response.code}: #{response.body[0..200]}"
      end

    rescue Net::ReadTimeout, Net::OpenTimeout, Timeout::Error => e
      duration = (Time.current - start_time).round(2)
      Rails.logger.warn "⏰ OpenAI TIMEOUT après #{duration}s - Utilisation fallback"
    rescue => e
      duration = (Time.current - start_time).round(2)
      Rails.logger.error "🔥 OpenAI ERROR après #{duration}s: #{e.message}"
    end

    # Fallback rapide en cas d'erreur
    generate_expert_fallback(message, 'general')
  end

  def guide_response(message, current_page)
    # 1. Vérifier les réponses instantanées d'abord
    normalized_message = message.downcase.strip
    if instant_response = check_instant_response(normalized_message)
      return instant_response
    end

    # 2. Vérifier le cache
    cache_key = "bot_guide_#{current_page}_#{Digest::MD5.hexdigest(normalized_message)}"
    cached_response = Rails.cache.read(cache_key)
    return cached_response if cached_response

    # 3. Générer la réponse contextuelle
    response = generate_contextual_guide_response(current_page, message)

    # 4. Mettre en cache la réponse
    Rails.cache.write(cache_key, response, expires_in: CACHE_DURATION)

    response
  end

  def generate_contextual_guide_response(current_page, message)
    # Réponse guide contextuelle basée sur la page
    case current_page
    when 'profil'
      "🏠 **Guide Profil**\n\nPour optimiser vos primes, veillez à :\n• Renseigner précisément vos revenus\n• Indiquer le bon nombre d'occupants\n• Vérifier votre catégorie de revenus\n\n💡 Astuce : Les revenus de référence sont ceux d'il y a 2 ans."

    when 'bien'
      "🏠 **Guide Description du Bien**\n\nPoints importants :\n• Surface habitable (hors garage, cave, grenier non aménagé)\n• Type de chauffage principal\n• Année de construction ou dernière rénovation\n\n📏 Mesurez avec précision pour un calcul optimal !"

    when 'chantier'
      "⚡ **Guide Travaux**\n\nPour maximiser vos primes :\n• Commencez par l'isolation (toit, murs, sol)\n• Choisissez un entrepreneur agréé\n• Demandez plusieurs devis\n• Respectez les normes techniques\n\n👷 Vérifiez toujours les agréments !"

    when 'simulation'
      "📊 **Guide Simulation**\n\nVos résultats montrent :\n• Montants indicatifs (non garantis)\n• Primes cumulables selon les règles\n• Conditions techniques à respecter\n\n💰 Optimisez en combinant plusieurs travaux !"

    when 'documents'
      "📄 **Guide Documents**\n\nDocuments essentiels :\n• Devis détaillés d'entrepreneurs agréés\n• Preuves de revenus (avertissement fiscal)\n• Photos avant travaux\n• Factures après réalisation\n\n✅ Préparez tout en amont !"

    when 'decision_hub'
      "🎯 **Hub de Décision**\n\nStratégie recommandée :\n• Analysez vos priorités (confort, économies, écologie)\n• Planifiez par étapes logiques\n• Budgétisez avec les primes\n\n🧠 Utilisez l'IA Expert pour des questions spécifiques !"

    else
      "🚀 **Guide Ren0vate**\n\nJe vous accompagne sur cette page :\n• Navigation intuitive\n• Conseils contextuels\n• Aide à la saisie\n\n💡 Cliquez sur les suggestions pour en savoir plus !"
    end
  end

  def expert_response(message, current_page)
    # 1. Vérifier les réponses instantanées d'abord
    normalized_message = message.downcase.strip
    Rails.logger.info "🔍 Expert - Message: '#{normalized_message[0..30]}...'"

    # Définir cache_key pour toute la méthode
    cache_key = "bot_expert_#{Digest::MD5.hexdigest(normalized_message)}"

    if instant_response = check_instant_response(normalized_message)
      Rails.logger.info "⚡ Expert - Réponse instantanée trouvée"
      return instant_response
    end

    # 2. Vérifier le cache pour les réponses expert
    cached_response = Rails.cache.read(cache_key)
    if cached_response
      Rails.logger.info "💾 Expert - Réponse en cache trouvée"
      return cached_response
    end

    # 3. Priorité à OpenAI avec fallback intelligent
    response_content = if @api_key.present?
      Rails.logger.info "🤖 Tentative OpenAI pour: #{message[0..50]}..."
      ai_response = get_expert_response(message)

      # Si OpenAI réussit, on utilise sa réponse
      if ai_response.present? && !ai_response.to_s.include?("temporairement indisponible")
        Rails.logger.info "✅ Réponse OpenAI utilisée"
        ai_response.is_a?(Hash) ? ai_response[:content] : ai_response
      else
        Rails.logger.info "⚡ Fallback après échec OpenAI"
        "🤖 **Réponse temporaire** - *Service IA en optimisation*\n\n" +
        generate_expert_fallback(message, current_page)
      end
    else
      Rails.logger.info "🔑 Pas de clé OpenAI - Fallback direct"
      generate_expert_fallback(message, current_page)
    end

    # 4. Mettre en cache la réponse (si pas d'erreur)
    unless response_content.to_s.include?("temporairement indisponible")
      Rails.cache.write(cache_key, response_content, expires_in: CACHE_DURATION)
    end

    response_content
  end

  def get_suggestions(current_page, mode)
    # Cache des suggestions pour éviter les calculs répétés
    cache_key = "bot_suggestions_#{current_page}_#{mode}"
    cached_suggestions = Rails.cache.read(cache_key)
    return cached_suggestions if cached_suggestions

    suggestions = if mode == 'expert'
      expert_suggestions(current_page)
    else
      guide_suggestions(current_page)
    end

    # Cache pour 30 minutes (les suggestions changent moins souvent)
    Rails.cache.write(cache_key, suggestions, expires_in: 30.minutes)

    suggestions
  end

  private

  def check_instant_response(normalized_message)
    # Recherche par mots-clés dans les réponses instantanées
    INSTANT_RESPONSES.each do |keyword, response|
      if normalized_message.include?(keyword) ||
         keyword.split.any? { |word| normalized_message.include?(word) }
        return response
      end
    end
    nil
  end

  def generate_expert_fallback(message, current_page)
    # Génération rapide de réponses expertes basées sur des mots-clés
    normalized = message.downcase

    case
    when normalized.include?('renolution') || normalized.include?('bruxelles')
      "🏢 **Situation Renolution 2025**\n\n**Budget disponible** :\n• Enveloppe régionale renouvelée chaque année\n• Primes disponibles selon ordre d'arrivée\n• Vérification en temps réel sur renolution.brussels\n\n**Conseils** :\n• Déposez votre demande rapidement\n• Complétez tous les documents requis\n• Envisagez les primes communales en parallèle\n\n✅ **Statut actuel** : Consultez le site officiel pour la disponibilité"

    when normalized.include?('wallonie') || normalized.include?('habitation')
      "🏛️ **Primes Wallonie - Statut Actuel**\n\n**Disponibilité** :\n• Budget Habitation Plus : disponible toute l'année\n• Pas de problème de rupture de stock\n• Traitement selon revenus et priorités\n\n**Optimisations 2025** :\n• Nouveaux plafonds majorés\n• Bonus logement ancien renforcé\n• Cumul facilité avec audit énergétique\n\n🚀 **Action** : Lancez votre demande sans délai"

    when normalized.include?('flandre') || normalized.include?('vlaanderen')
      "🇳🇱 **Primes Flandre - Mijn Verbouwpremie**\n\n**Système robuste** :\n• Budget pérenne, renouvelé annuellement\n• Demandes traitées après travaux\n• Moins de pression temporelle\n\n**Avantages 2025** :\n• E-peil obligatoire = prime majorée\n• Cumul avec primes communales\n• Accompagnement VLAIO gratuit\n\n📊 **Conseil** : Planifiez selon votre E-peil cible"

    when normalized.include?('isolation') || normalized.include?('isoler')
      "🏠 **Stratégie Isolation Optimale**\n\n**Ordre de priorité** :\n1. **Toiture** : ROI le plus rapide (2-3 ans)\n2. **Murs** : Confort thermique maximal\n3. **Sol** : Élimination des ponts thermiques\n4. **Fenêtres** : Finition de l'enveloppe\n\n**Primes disponibles** :\n• Jusqu'à 70% de prise en charge\n• Bonus matériaux biosourcés\n• Cumul audit + travaux possible\n\n⚡ **Impact** : -30 à 50% sur facture chauffage"

    when normalized.include?('pompe') || normalized.include?('chauffage')
      "🔥 **Pompes à Chaleur & Chauffage 2025**\n\n**Technologies subventionnées** :\n• **PAC air/eau** : COP > 4, primes élevées\n• **PAC géothermique** : Performance maximale\n• **Chaudière condensation** : Solution abordable\n• **Solaire thermique** : Eau chaude gratuite\n\n💰 **Financement** :\n• Primes jusqu'à 50% du coût\n• Éco-prêts à taux zéro\n• Déductions fiscales possibles\n\n🎯 **Recommandation** : Audit énergétique préalable obligatoire"

    when normalized.include?('entrepreneur') || normalized.include?('agréé')
      "👷 **Entrepreneurs Agréés - Guide 2025**\n\n**Vérifications essentielles** :\n• **Wallonie** : Portail Énergie SPW\n• **Bruxelles** : Base Renolution.brussels  \n• **Flandre** : VLAIO entrepreneurs\n\n**Points de contrôle** :\n• Agrément valide et à jour\n• Assurance RC + décennale\n• Références clients vérifiables\n• Devis détaillé conforme\n\n⚠️ **Attention** : Pas d'acompte > 20% du montant total"

    when normalized.include?('audit') || normalized.include?('peb')
      "📊 **Audit Énergétique - Stratégie 2025**\n\n**Avantages majeurs** :\n• Subventionné à 75-100% selon région\n• Obligatoire pour certaines primes importantes\n• Plan d'action personnalisé et chiffré\n• Hiérarchisation des investissements\n\n**Processus** :\n1. Choix auditeur agréé (annuaire officiel)\n2. Visite technique approfondie (2-3h)\n3. Rapport sous 15 jours ouvrables\n4. Accompagnement mise en œuvre\n\n🎯 **ROI** : Économies 30-50% identifiées"

    when normalized.include?('document') || normalized.include?('dossier')
      "📄 **Dossier Prime - Checklist 2025**\n\n**AVANT travaux** :\n• ✅ Devis détaillé entrepreneur agréé\n• ✅ Avertissement extrait de rôle (revenus)\n• ✅ Photos état existant (datées)\n• ✅ Demande de permis si requis\n\n**APRÈS travaux** :\n• ✅ Factures acquittées détaillées\n• ✅ Certificats de performance matériaux\n• ✅ Photos travaux terminés\n• ✅ PV de réception des travaux\n\n💡 **Astuce** : Préparez tout en amont pour éviter les retards de paiement"

    else
      # Réponse générique mais informative
      "🧠 **Assistant Expert Ren0vate**\n\nPour une réponse plus précise, précisez :\n• **Votre région** (Wallonie, Bruxelles, Flandre)\n• **Type de travaux** (isolation, chauffage, fenêtres...)\n• **Votre situation** (revenus, logement, timing)\n\n🔍 **Domaines d'expertise** :\n• Optimisation des primes énergétiques\n• Stratégies de rénovation rentables  \n• Accompagnement administratif\n• Choix techniques et entrepreneurs\n\n💬 Reformulez votre question pour une aide ciblée !"
    end
  end

  def system_prompt(locale)
    if locale == :fr
      <<~PROMPT
        Tu es un expert en primes et subsides énergétiques en Belgique, spécialement formé sur Ren0vate.

        CONTEXTE PLATEFORME : Tu travailles sur Ren0vate, simulateur de primes énergétiques pour les 3 régions belges :
        - **Wallonie** : Primes Habitation Plus, audit énergétique, entrepreneurs agréés SPW
        - **Bruxelles** : Primes Renolution, primes communales, accompagnement Homegrade
        - **Flandre** : Mijn Verbouwpremie, E-peil, entrepreneurs VLAIO

        EXPERTISE AVANCÉE :
        - Réglementations 2025 actualisées
        - Optimisation financière des dossiers
        - Stratégies de rénovation performantes
        - Processus administratifs détaillés
        - Choix techniques et matériaux

        STYLE DE RÉPONSE :
        - Structuré avec émojis thématiques
        - Maximum 500 mots, dense en informations
        - Listes à puces pour lisibilité
        - Conseils actionnables immédiats
        - Différences régionales précisées
        - Chiffres et montants concrets

        TERMINOLOGIE BELGE :
        - "Entrepreneur agréé" (pas RGE français)
        - "Avertissement-extrait de rôle" (revenus)
        - "Primes énergétiques" (pas aides françaises)
        - Montants en euros, normes belges

        Sois précis, pratique et orienté résultats pour aider l'utilisateur à optimiser ses primes.
      PROMPT
    else
      system_prompt(:fr)
    end
  end

  def build_expert_prompt(message, locale)
    current_date = Date.current.strftime("%B %Y")

    <<~PROMPT
      QUESTION UTILISATEUR : #{message}

      CONTEXTE ACTUEL (#{current_date}) :
      - Budgets primes 2025 disponibles
      - Nouvelles réglementations en vigueur
      - Entrepreneurs agréés à jour
      - Processus digitalisés optimisés

      RÉPONSE ATTENDUE :
      1. **Diagnostic** : Identifie la problématique précise
      2. **Solutions concrètes** : Recommandations actionnables
      3. **Optimisation financière** : Maximisation des primes
      4. **Étapes pratiques** : Plan d'action détaillé
      5. **Ressources** : Contacts et liens utiles si pertinent

      Privilégie les conseils concrets et les informations 2025 actualisées.
    PROMPT
  end

  def format_expert_response(content)
    return fallback_response("") unless content.present?

    {
      content: content.strip,
      mode: 'expert',
      timestamp: Time.current.strftime("%H:%M"),
      source: 'openai'
    }
  end

  def fallback_response(message)
    {
      content: "🔄 **Service IA temporairement optimisé**\n\n" +
              "💡 En attendant, voici l'essentiel :\n" +
              "• **Wallonie** : Primes Habitation Plus disponibles\n" +
              "• **Bruxelles** : Renolution + communes\n" +
              "• **Flandre** : Mijnverbouwpremie actif\n\n" +
              "🚀 **Utilisez le simulateur** pour des conseils personnalisés !",
      mode: 'expert',
      timestamp: Time.current.strftime("%H:%M"),
      source: 'fallback'
    }
  end

  # Suggestions pré-calculées pour performances optimales
  GUIDE_SUGGESTIONS = {
    'profil' => [
      '💡 Comment calculer mes revenus de référence ?',
      '🏠 Quelle catégorie de revenus ai-je ?',
      '📊 Dois-je compter tous mes revenus ?',
      '👨‍👩‍👧 Comment compter les occupants ?'
    ],
    'bien' => [
      '🏠 Comment mesurer la surface habitable ?',
      '📏 Quelle est la différence avec la surface totale ?',
      '🔥 Mon type de chauffage influence-t-il les primes ?',
      '🏗️ Année de construction ou de rénovation ?'
    ],
    'chantier' => [
      '⚡ Par quels travaux commencer ?',
      '👷 Comment vérifier qu\'un entrepreneur est agréé ?',
      '📅 Combien de temps pour réaliser les travaux ?',
      '💰 Puis-je échelonner mes travaux ?'
    ],
    'simulation' => [
      '💰 Comment augmenter le montant de mes primes ?',
      '📊 Ces montants sont-ils garantis ?',
      '🔄 Puis-je modifier ma simulation ?',
      '📄 Quels documents préparer maintenant ?'
    ],
    'documents' => [
      '📄 Quels documents sont obligatoires ?',
      '📋 Comment bien organiser mes papiers ?',
      '✅ Ai-je tous les documents nécessaires ?',
      '📸 Dois-je prendre des photos ?'
    ],
    'decision_hub' => [
      '🎯 Quelle stratégie de rénovation adopter ?',
      '💡 Comment prioriser mes travaux ?',
      '📊 Comment optimiser mes aides financières ?',
      '🏛️ Quelles sont les démarches administratives ?'
    ],
    'pages' => [
      '💡 Comment cette page peut-elle m\'aider ?',
      '🔍 Expliquez-moi les fonctionnalités',
      '📚 Donnez-moi des conseils pratiques'
    ]
  }.freeze

  EXPERT_SUGGESTIONS = [
    '🧠 Quelle est la meilleure stratégie de rénovation ?',
    '💰 Comment maximiser mes primes énergétiques ?',
    '⚡ Quels travaux sont les plus rentables ?',
    '🏛️ Quelles sont les dernières réglementations ?'
  ].freeze

  def guide_suggestions(page)
    GUIDE_SUGGESTIONS[page] || GUIDE_SUGGESTIONS['pages']
  end

  def expert_suggestions(page)
    EXPERT_SUGGESTIONS
  end
end
