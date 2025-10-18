class ContextualBotController < ApplicationController
  before_action :set_locale

  def chat
    @message = params[:message]
    @current_page = params[:current_page] || 'home'
    @mode = params[:mode] || 'guide' # 'guide' ou 'expert'

    response = generate_response(@message, @current_page, @mode)

    render json: {
      response: response,
      suggestions: get_contextual_suggestions(@current_page, @mode),
      mode: @mode
    }
  end

  private

  def generate_response(message, current_page, mode)
    if mode == 'guide'
      generate_guide_response(message, current_page)
    else
      generate_expert_response(message)
    end
  end

  def generate_guide_response(message, page)
    context = get_page_context(page)

    # Logique de réponse contextuelle basée sur la page
    case page
    when 'profil'
      handle_profil_questions(message, context)
    when 'bien'
      handle_bien_questions(message, context)
    when 'chantier'
      handle_chantier_questions(message, context)
    when 'simulation'
      handle_simulation_questions(message, context)
    when 'documents'
      handle_documents_questions(message, context)
    else
      handle_general_guide_questions(message)
    end
  end

  def generate_expert_response(message)
    # Appel à l'API OpenAI pour les questions expertes générales
    ContextualBotService.new.get_expert_response(message, I18n.locale)
  end

  def get_page_context(page)
    {
      profil: {
        title: "Configuration de votre profil",
        current_step: "Informations personnelles et revenus",
        key_fields: ["revenus", "composition_familiale", "region"]
      },
      bien: {
        title: "Description de votre bien",
        current_step: "Caractéristiques techniques",
        key_fields: ["type_bien", "surface", "annee_construction", "etat_isolation"]
      },
      chantier: {
        title: "Planification de vos travaux",
        current_step: "Définition des travaux énergétiques",
        key_fields: ["type_travaux", "budget_estime", "entrepreneur"]
      },
      simulation: {
        title: "Estimation de vos primes",
        current_step: "Résultats et optimisation",
        key_fields: ["montant_total", "primes_eligibles", "conditions"]
      },
      documents: {
        title: "Préparation des documents",
        current_step: "Liste des pièces justificatives",
        key_fields: ["factures", "attestations", "certificats"]
      }
    }[page.to_sym] || {}
  end

  def get_contextual_suggestions(page, mode)
    if mode == 'guide'
      get_guide_suggestions(page)
    else
      get_expert_suggestions
    end
  end

  def get_guide_suggestions(page)
    suggestions = {
      'profil' => [
        "💡 Comment calculer mes revenus nets ?",
        "🏠 Quelle catégorie de revenus choisir ?",
        "📊 Pourquoi ces informations sont importantes ?",
        "🔄 Comment modifier mes informations plus tard ?"
      ],
      'bien' => [
        "📏 Comment mesurer la surface de mon bien ?",
        "🏗️ Comment connaître l'année de construction ?",
        "🔍 Comment évaluer l'état de mon isolation ?",
        "📋 Quelles informations techniques collecter ?"
      ],
      'chantier' => [
        "⚡ Quels types de travaux énergétiques existent ?",
        "💰 Comment estimer le coût de mes travaux ?",
        "👷 Comment choisir un entrepreneur agréé ?",
        "📅 Comment planifier mes travaux ?"
      ],
      'simulation' => [
        "💡 Comment interpréter mes résultats ?",
        "📈 Comment augmenter mes primes ?",
        "⏰ Quels délais respecter ?",
        "🎯 Quelle est ma priorité d'action ?"
      ],
      'documents' => [
        "📄 Quels documents préparer en premier ?",
        "🔍 Où trouver mes certificats ?",
        "📋 Comment organiser mon dossier ?",
        "✅ Comment vérifier la conformité ?"
      ]
    }

    suggestions[page] || [
      "🚀 Comment utiliser cette plateforme ?",
      "📊 Quelle est la prochaine étape ?",
      "💡 Des conseils pour optimiser mes primes ?",
      "🧠 Passer en mode expert général"
    ]
  end

  def get_expert_suggestions
    [
      "🏛️ Réglementations par région",
      "💰 Types de primes disponibles",
      "📋 Processus administratifs",
      "🎯 Conseils d'optimisation",
      "🔄 Retour au guide contextuel"
    ]
  end

  # Handlers spécifiques par page
  def handle_profil_questions(message, context)
    # Questions fréquentes profil
    if message.downcase.include?('revenu')
      return build_response(
        "💰 **Calcul des revenus pour vos primes**\n\n" +
        "Vos revenus déterminent le montant de vos primes. Voici comment les calculer :\n\n" +
        "• **Revenus nets** : Salaire après déductions fiscales\n" +
        "• **Revenus bruts** : Avant déductions (parfois demandé)\n" +
        "• **Revenus du ménage** : Somme de tous les revenus familiaux\n\n" +
        "💡 **Astuce** : Plus vos revenus sont modestes, plus vos primes sont élevées !",
        'guide'
      )
    end

    if message.downcase.include?('catégorie') || message.downcase.include?('categorie')
      return build_response(
        "📊 **Catégories de revenus en Belgique**\n\n" +
        "Les catégories varient selon votre région :\n\n" +
        "**Wallonie** :\n• R1 : Revenus très modestes\n• R2 : Revenus modestes\n• R3 : Revenus moyens\n• R4 : Revenus élevés\n\n" +
        "**Bruxelles & Flandre** : Système similaire avec barèmes spécifiques\n\n" +
        "💡 Consultez les seuils exacts dans votre simulation !",
        'guide'
      )
    end

    # Réponse générique
    build_response(
      "🏠 **Aide pour votre profil**\n\n" +
      "Cette section collecte vos informations personnelles pour :\n" +
      "• Déterminer vos droits aux primes\n" +
      "• Calculer les montants exacts\n" +
      "• Personnaliser vos recommandations\n\n" +
      "Besoin d'aide sur un champ spécifique ? Posez-moi votre question !",
      'guide'
    )
  end

  def handle_bien_questions(message, context)
    if message.downcase.include?('surface') || message.downcase.include?('m²')
      return build_response(
        "📏 **Comment mesurer votre bien**\n\n" +
        "Pour une estimation précise :\n\n" +
        "• **Surface habitable** : Pièces chauffées uniquement\n" +
        "• **Surface des murs** : Murs extérieurs à isoler\n" +
        "• **Surface de toiture** : Zone sous toiture\n\n" +
        "💡 **Astuce** : Consultez vos plans ou acte de propriété !",
        'guide'
      )
    end

    build_response(
      "🏗️ **Description de votre bien**\n\n" +
      "Ces informations permettent de :\n" +
      "• Identifier les travaux éligibles\n" +
      "• Calculer les surfaces concernées\n" +
      "• Estimer les coûts et primes\n\n" +
      "Posez-moi vos questions sur les champs à remplir !",
      'guide'
    )
  end

  def handle_chantier_questions(message, context)
    if message.downcase.include?('entrepreneur') || message.downcase.include?('agréé')
      return build_response(
        "👷 **Choisir un entrepreneur agréé**\n\n" +
        "Obligatoire pour certaines primes :\n\n" +
        "• **Liste officielle** : Consultez le registre régional\n" +
        "• **Qualifications** : Vérifiez les certifications\n" +
        "• **Devis détaillé** : Exigez les spécifications techniques\n\n" +
        "💡 Un entrepreneur non-agréé = Pas de prime !",
        'guide'
      )
    end

    build_response(
      "⚡ **Planification de vos travaux**\n\n" +
      "Cette section vous aide à :\n" +
      "• Définir vos priorités énergétiques\n" +
      "• Estimer les coûts prévisionnels\n" +
      "• Identifier les primes disponibles\n\n" +
      "Questions sur un type de travaux ? Je suis là !",
      'guide'
    )
  end

  def handle_simulation_questions(message, context)
    build_response(
      "📊 **Comprendre votre simulation**\n\n" +
      "Vos résultats incluent :\n" +
      "• **Montant total** des primes possibles\n" +
      "• **Détail par type** de travaux\n" +
      "• **Conditions d'éligibilité** à respecter\n\n" +
      "💡 Utilisez l'IA expert pour optimiser votre stratégie !",
      'guide'
    )
  end

  def handle_documents_questions(message, context)
    build_response(
      "📄 **Préparation documentaire**\n\n" +
      "Documents essentiels :\n" +
      "• **Factures** : Tous les travaux réalisés\n" +
      "• **Attestations** : Entrepreneur et conformité\n" +
      "• **Certificats** : PEB, électricité, gaz\n\n" +
      "💡 Préparez tout avant de faire votre demande !",
      'guide'
    )
  end

  def handle_general_guide_questions(message)
    build_response(
      "🚀 **Bienvenue sur Ren0vate !**\n\n" +
      "Je suis votre assistant contextuel :\n" +
      "• **Mode Guide** : Aide à l'utilisation (actuel)\n" +
      "• **Mode Expert** : Questions générales sur les primes\n\n" +
      "Naviguez dans l'app, je m'adapte à chaque page !",
      'guide'
    )
  end

  def build_response(content, mode, suggestions = nil)
    {
      content: content,
      mode: mode,
      timestamp: Time.current.strftime("%H:%M"),
      suggestions: suggestions
    }
  end
end
