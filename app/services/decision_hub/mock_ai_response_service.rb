module DecisionHub
  # Réponse mockée (basée sur des mots-clés) à une question posée dans le
  # Decision Hub — DecisionHubController#ai_consultation construit bien un
  # prompt contextuel via DecisionHub::AiPromptService, mais ne l'envoie pas
  # (encore) à Claude ; cette classe simule la réponse en attendant.
  class MockAiResponseService
    def self.call(simulation, question, section = nil)
      new(simulation, question, section).call
    end

    def initialize(simulation, question, section = nil)
      @simulation = simulation
      @question = question
      @section = section
    end

    def call
      hub_data = DecisionHub::DataService.new(@simulation).generate_dynamic_data

      case @question.downcase
      when /prochain|suivant|que faire|étape/
        next_action_response(hub_data)
      when /document|papier|dossier/
        documents_response(hub_data)
      when /délai|timing|quand|urgent/
        timing_response(hub_data)
      when /technique|norme|conformité/
        technical_response(hub_data)
      when /optimis|améliorer|maxim/
        optimization_response(hub_data)
      else
        general_response(hub_data)
      end
    end

    private

    def next_action_response(hub_data)
      resume = hub_data[:resume]
      documents = hub_data[:documents]
      technical = hub_data[:technical]

      if documents[:urgent].any?
        "🚨 **Action prioritaire**: Vous avez #{documents[:urgent].count} documents URGENTS à obtenir !\n\n" +
        "📋 **À faire MAINTENANT**:\n" +
        documents[:urgent].map { |doc| "• #{doc}" }.join("\n") +
        "\n\n💰 **Impact**: Ces documents bloquent vos #{resume[:total_amount]}€ de primes !"
      elsif technical[:critical_issues].any?
        "⚠️ **Action technique prioritaire**: #{technical[:critical_issues].count} non-conformités critiques détectées !\n\n" +
        "🔧 **À corriger**:\n" +
        technical[:critical_issues].first(3).map { |issue| "• #{issue}" }.join("\n") +
        "\n\n🎯 **Conseil**: Réglez ces points avant de déposer votre dossier."
      else
        "✅ **Excellent !** Votre dossier avance bien (#{documents[:completion_rate]}% documents, #{technical[:compliance_rate]}% conformité).\n\n" +
        "🚀 **Prochaine étape**: Finaliser les derniers détails et préparer le dépôt coordonné de vos primes."
      end
    end

    def documents_response(hub_data)
      documents = hub_data[:documents]
      resume = hub_data[:resume]

      missing_count = documents[:missing].count
      urgent_count = documents[:urgent].count

      response = "📋 **État documents** (#{documents[:completion_rate]}% complétés):\n\n"

      if documents[:completed].any?
        response += "✅ **Déjà collectés**: #{documents[:completed].join(', ')}\n\n"
      end

      if urgent_count > 0
        response += "🚨 **URGENTS** (#{urgent_count}):\n"
        response += documents[:urgent].map { |doc| "• #{doc}" }.join("\n")
        response += "\n\n"
      end

      if missing_count > urgent_count
        remaining = documents[:missing] - documents[:urgent]
        response += "📝 **Restants** (#{remaining.count}):\n"
        response += remaining.first(3).map { |doc| "• #{doc}" }.join("\n")
        response += "\n\n"
      end

      response += "💡 **Conseil**: Commencez par les urgents, ils sont bloquants pour vos #{resume[:total_amount]}€ !"
    end

    def timing_response(hub_data)
      planning = hub_data[:planning]
      resume = hub_data[:resume]

      if planning[:urgent_deadlines].any?
        next_deadline = planning[:urgent_deadlines].first
        days_remaining = (next_deadline[:date] - Date.current).to_i

        "⏰ **Attention délai !**\n\n" +
        "🚨 **Prochaine échéance**: #{next_deadline[:description]}\n" +
        "📅 **Date limite**: #{next_deadline[:date].strftime('%d/%m/%Y')} (dans #{days_remaining} jours)\n" +
        "💰 **Enjeu**: #{next_deadline[:benefit]}\n\n" +
        "🎯 **Action**: #{days_remaining < 30 ? 'URGENT - ' : ''}Préparez votre dossier maintenant !"
      else
        "✅ **Timing optimal** pour vos #{resume[:total_amount]}€ de primes !\n\n" +
        "⏱️ **Durée totale estimée**: #{planning[:total_duration]}\n" +
        "🎯 **Pas d'urgence immédiate**, vous pouvez prendre le temps de bien préparer.\n\n" +
        "💡 **Conseil**: Profitez-en pour optimiser votre dossier et vérifier tous les détails."
      end
    end

    def technical_response(hub_data)
      technical = hub_data[:technical]
      resume = hub_data[:resume]

      critical_count = technical[:critical_issues].count
      warnings_count = technical[:warnings].count

      if critical_count > 0
        "🔧 **Conformité technique** (#{technical[:compliance_rate]}%):\n\n" +
        "❌ **#{critical_count} points CRITIQUES** à corriger:\n" +
        technical[:critical_issues].map { |issue| "• #{issue}" }.join("\n") +
        "\n\n⚠️ **Impact**: Ces non-conformités peuvent faire refuser vos primes !\n" +
        "🎯 **Action**: Corrigez ces points avant le dépôt."
      elsif warnings_count > 0
        "⚠️ **Attention technique** (#{technical[:compliance_rate]}%):\n\n" +
        "🔶 **#{warnings_count} points à vérifier**:\n" +
        technical[:warnings].first(3).map { |warning| "• #{warning}" }.join("\n") +
        "\n\n💡 **Conseil**: Points non bloquants mais recommandés pour optimiser vos #{resume[:total_amount]}€."
      else
        "✅ **Excellente conformité technique !** (#{technical[:compliance_rate]}%)\n\n" +
        "🎯 Votre dossier respecte toutes les normes techniques.\n" +
        "🚀 Vous pouvez passer à la finalisation administrative."
      end
    end

    def optimization_response(hub_data)
      resume = hub_data[:resume]
      primes = resume[:primes]

      current_total = resume[:total_amount]
      high_priority_primes = primes.select { |p| p[:urgency] == "high" || p[:urgency] == "critical" }

      "🚀 **Optimisation de vos #{current_total}€** :\n\n" +
      "💰 **Primes prioritaires** (#{high_priority_primes.count}):\n" +
      high_priority_primes.map { |p| "• #{p[:name]}: #{p[:amount]}€" }.join("\n") +
      "\n\n🎯 **Stratégie recommandée**:\n" +
      "1. **Concentrez-vous sur les primes urgentes** (meilleur ROI)\n" +
      "2. **Déposez en simultané** pour éviter les conflits\n" +
      "3. **Vérifiez les bonus saisonniers** disponibles\n\n" +
      "📈 **Potentiel gain**: +10-15% avec timing optimisé !"
    end

    def general_response(hub_data)
      resume = hub_data[:resume]
      overall_completion = resume[:completion_status][:overall]

      "🤖 **Analyse de votre situation** :\n\n" +
      "📊 **Votre projet**: #{resume[:primes].count} primes • #{resume[:total_amount]}€ • #{resume[:region]}\n" +
      "📈 **Avancement global**: #{overall_completion}%\n\n" +
      "🎯 **Mon évaluation**:\n" +
      case overall_completion
      when 0..25
        "🟥 **Début de parcours** - Concentrez-vous sur les documents prioritaires"
      when 26..50
        "🟨 **Bon démarrage** - Continuez sur cette lancée !"
      when 51..75
        "🟦 **Bonne progression** - Plus que quelques détails à régler"
      else
        "🟩 **Excellent !** - Vous êtes prêt pour le dépôt"
      end +
      "\n\n💬 **Questions spécifiques ?** Demandez-moi des détails sur les documents, délais, ou aspects techniques !"
    end
  end
end
