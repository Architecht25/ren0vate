# Service pour générer les prompts IA contextuels basés sur toutes les données de simulation
class DecisionHub::AiPromptService
  def self.build_contextual_prompt(simulation, user_question, conversation_history = [])
    new(simulation).generate_prompt(user_question, conversation_history)
  end

  def initialize(simulation)
    @simulation = simulation
    @region = simulation.region&.downcase || "wallonie"

    # Charger toutes les données contextuelles
    @data_service = DecisionHub::DataService.new(simulation)
    @full_context = @data_service.generate_dynamic_data
  end

  def generate_prompt(user_question, conversation_history = [])
    build_system_prompt +
    build_context_section +
    build_conversation_history(conversation_history) +
    build_user_question(user_question) +
    build_response_guidelines
  end

  def self.build_context(simulation)
    new(simulation).generate_context_data
  end

  def generate_context_data
    build_context_section
  end

  private

  def build_system_prompt
    <<~PROMPT
      Tu es l'Expert IA de Ren0vate, spécialisé en primes énergétiques pour la #{@region.capitalize}.

      🎯 TON RÔLE:
      - Assistant expert qui maîtrise TOUS les aspects du dossier utilisateur
      - Conseiller stratégique pour optimiser le parcours primes
      - Guide technique pour respecter toutes les obligations
      - Coach personnel pour surmonter les obstacles

      🧠 TES CAPACITÉS:
      - Accès complet aux données de simulation en temps réel
      - Connaissance exhaustive des obligations techniques et administratives
      - Maîtrise des délais et planning optimisé
      - Vision stratégique pour maximiser les aides

    PROMPT
  end

  def build_context_section
    resume = @full_context[:resume]
    documents = @full_context[:documents]
    planning = @full_context[:planning]
    technical = @full_context[:technical]

    <<~PROMPT
      📊 CONTEXTE SIMULATION ACTIVE:
      #{build_resume_context(resume)}

      📋 ÉTAT DOCUMENTS (#{documents[:completion_rate]}% complétés):
      #{build_documents_context(documents)}

      ⏰ PLANNING CRITIQUE:
      #{build_planning_context(planning)}

      🔧 CONFORMITÉ TECHNIQUE (#{technical[:compliance_rate]}%):
      #{build_technical_context(technical)}

    PROMPT
  end

  def build_resume_context(resume)
    primes_info = resume[:primes].map do |prime|
      "  • #{prime[:name]}: #{prime[:amount]}€ (#{prime[:status]} - urgence: #{prime[:urgency]})"
    end.join("\n")

    <<~CONTEXT
      - Total primes: #{resume[:total_amount]}€
      - Région: #{resume[:region]}
      - Type propriété: #{resume[:property_type]}
      - Primes sélectionnées:
      #{primes_info}
      - Avancement global: #{resume[:completion_status][:overall]}%
    CONTEXT
  end

  def build_documents_context(documents)
    completed = documents[:completed].any? ? "#{documents[:completed].join(', ')}" : "Aucun"
    missing = documents[:missing].any? ? "#{documents[:missing].join(', ')}" : "Aucun"
    urgent = documents[:urgent].any? ? "#{documents[:urgent].join(', ')}" : "Aucun"

    <<~CONTEXT
      - ✅ Documents collectés: #{completed}
      - ❌ Documents manquants: #{missing}
      - 🚨 URGENTS à obtenir: #{urgent}
    CONTEXT
  end

  def build_planning_context(planning)
    urgent_info = planning[:urgent_deadlines].map do |deadline|
      "#{deadline[:description]} (#{deadline[:date].strftime('%d/%m/%Y')} - #{deadline[:benefit]})"
    end.join(', ')

    critical_path = planning[:critical_path].any? ? planning[:critical_path].join(', ') : "Aucune action bloquante"

    <<~CONTEXT
      - Durée totale estimée: #{planning[:total_duration]}
      - Échéances critiques: #{urgent_info.present? ? urgent_info : "Aucune urgence immédiate"}
      - Actions bloquantes: #{critical_path}
      - Contraintes saisonnières: #{planning[:seasonal_constraints].any? ? "Oui" : "Non"}
    CONTEXT
  end

  def build_technical_context(technical)
    critical = technical[:critical_issues].any? ? technical[:critical_issues].join(', ') : "Aucun"
    warnings = technical[:warnings].any? ? technical[:warnings].join(', ') : "Aucun"

    <<~CONTEXT
      - ❌ CRITIQUES non-conformes: #{critical}
      - ⚠️ Avertissements: #{warnings}
      - Recommandations techniques disponibles: #{technical[:recommendations].count}
    CONTEXT
  end

  def build_conversation_history(history)
    return "" if history.empty?

    history_text = history.last(3).map do |exchange| # Garde les 3 derniers échanges
      "👤 #{exchange[:user]}\n🤖 #{exchange[:assistant]}"
    end.join("\n\n")

    <<~PROMPT

      💬 HISTORIQUE CONVERSATION RÉCENTE:
      #{history_text}

    PROMPT
  end

  def build_user_question(question)
    <<~PROMPT

      ❓ QUESTION UTILISATEUR:
      #{question}

    PROMPT
  end

  def build_response_guidelines
    <<~PROMPT

      📋 DIRECTIVES RÉPONSE:

      🎯 STRUCTURE RÉPONSE:
      1. **Diagnostic précis** basé sur ses données exactes
      2. **Actions prioritaires** (max 3) avec ordre d'importance
      3. **Bénéfices concrets** (montants, délais, avantages)

      ✅ STYLE COMMUNICATION:
      - Utilise les émojis appropriés (🚨 critique, ⚠️ attention, ✅ ok, 💰 argent)
      - Mentionne les montants exacts de ses primes
      - Cite les délais précis de son planning
      - Donne des conseils actionnables MAINTENANT
      - Reste encourageant et solution-oriented

      🔍 UTILISE SES DONNÉES EXACTES:
      - Ses primes spécifiques et montants
      - Son état d'avancement réel
      - Ses obligations précises
      - Ses délais actuels

      ⛔ ÉVITE:
      - Réponses génériques
      - Informations non vérifiées
      - Promesses que tu ne peux tenir
      - Conseils contraires aux réglementations

      🚀 OBJECTIF: Aider concrètement l'utilisateur à avancer efficacement vers ses primes !
    PROMPT
  end

  # Méthodes pour prompts spécialisés selon le contexte
  def self.build_section_specific_prompt(simulation, section, user_question)
    base_prompt = new(simulation).generate_prompt(user_question)

    section_focus = case section
    when "documents"
      "\n🎯 FOCUS SPÉCIAL: L'utilisateur consulte la section DOCUMENTS. Concentre-toi sur les documents manquants, comment les obtenir rapidement, et les priorités administratives."
    when "planning"
      "\n🎯 FOCUS SPÉCIAL: L'utilisateur consulte la section PLANNING. Concentre-toi sur l'optimisation du timing, les délais critiques, et la séquence optimale des actions."
    when "technical"
      "\n🎯 FOCUS SPÉCIAL: L'utilisateur consulte la section TECHNIQUE. Concentre-toi sur les normes, spécifications techniques, et la conformité réglementaire."
    else
      "\n🎯 FOCUS SPÉCIAL: Vue d'ensemble stratégique et recommandations générales."
    end

    base_prompt + section_focus
  end

  def self.build_quick_response_prompt(simulation, quick_question_type)
    context = DecisionHub::DataService.new(simulation).generate_dynamic_data

    case quick_question_type
    when "next_action"
      "Basé sur cette situation: #{context[:resume][:primes].count} primes (#{context[:resume][:total_amount]}€), #{context[:documents][:completion_rate]}% documents, #{context[:technical][:compliance_rate]}% conformité technique. Quelle est LA priorité absolue maintenant ? Réponds en 2 phrases max avec action précise."
    when "blocking_issue"
      "Analyse rapide: y a-t-il un élément BLOQUANT dans ce dossier qui empêche d'avancer ? Si oui, lequel et comment le résoudre ? Réponse courte et solution."
    when "optimization"
      "Opportunité d'optimisation: comment augmenter le montant de #{context[:resume][:total_amount]}€ ou accélérer le processus ? 1 conseil concret max."
    end
  end
end
