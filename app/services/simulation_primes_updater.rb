# Service pour mettre à jour les données de primes d'une simulation
class SimulationPrimesUpdater
  def initialize(simulation)
    @simulation = simulation
    @logger = Rails.logger
  end

  # Met à jour les saisies utilisateur et recalcule les montants
  def update_user_inputs(user_inputs)
    # Convertir en Hash si c'est des ActionController::Parameters
    user_inputs = user_inputs.to_h if user_inputs.respond_to?(:to_h)

    @logger.info "🔄 Mise à jour simulation #{@simulation.id} avec #{user_inputs.length} saisies"

    begin
      # Parser les paramètres existants
      current_params = parse_current_parameters

      # Mettre à jour les saisies utilisateur
      updated_params = update_prime_inputs(current_params, user_inputs)

      # Recalculer tous les montants
      recalculate_amounts(updated_params)

      # Sauvegarder en base
      save_to_database(updated_params)

      # Retourner les résultats pour l'interface
      build_response(updated_params)

    rescue => e
      @logger.error "❌ Erreur mise à jour simulation #{@simulation.id}: #{e.message}"
      { success: false, error: e.message }
    end
  end

  private

  def parse_current_parameters
    return default_parameters if @simulation.parameters.blank?

    JSON.parse(@simulation.parameters)
  rescue JSON::ParserError => e
    @logger.warn "⚠️ JSON invalide pour simulation #{@simulation.id}, utilisation paramètres par défaut"
    default_parameters
  end

  def default_parameters
    {
      "prime_cards" => {},
      "total_general" => 0,
      "category_used" => "R2",
      "calculation_timestamp" => Time.current.iso8601
    }
  end

  def update_prime_inputs(current_params, user_inputs)
    prime_cards = current_params["prime_cards"] || {}

    user_inputs.each do |prime_slug, user_value|
      # Trouver la prime dans la structure
      prime_found = false

      prime_cards.each do |category_key, category_data|
        next unless category_data["primes"]

        category_data["primes"].each do |prime|
          if prime["slug"] == prime_slug
            # Mettre à jour la valeur utilisateur
            prime["user_input_value"] = user_value
            prime_found = true
            @logger.debug "📝 Mise à jour #{prime_slug}: #{user_value}"
            break
          end
        end
        break if prime_found
      end

      unless prime_found
        @logger.warn "⚠️ Prime non trouvée: #{prime_slug}"
      end
    end

    current_params["prime_cards"] = prime_cards
    current_params["last_update"] = Time.current.iso8601
    current_params
  end

  def recalculate_amounts(params)
    return unless params["prime_cards"]

    category_used = params["category_used"] || "R2"
    total_general = 0

    @logger.info "💰 Recalcul avec catégorie: #{category_used}"

    params["prime_cards"].each do |category_key, category_data|
      next unless category_data["primes"]

      category_total = 0

      category_data["primes"].each do |prime|
        amount = calculate_prime_amount(prime, category_used)
        prime["calculated_amount"] = amount
        category_total += amount
      end

      category_data["total"] = category_total
      total_general += category_total

      @logger.debug "📊 #{category_key}: #{category_total}€"
    end

    params["total_general"] = total_general
    params["calculation_timestamp"] = Time.current.iso8601

    @logger.info "✅ Total général calculé: #{total_general}€"
  end

  def calculate_prime_amount(prime, category_used)
    user_input = prime["user_input_value"]
    category_data = prime["category_data"]

    return 0 if user_input.nil? || user_input == 0 || user_input == "0" || user_input == ""
    return 0 unless category_data

    case category_data["type"]
    when "montant_fixe"
      # Prime forfaitaire
      user_input.to_i > 0 ? category_data["montant"].to_f : 0

    when "montant_m2"
      # Prime au m²
      surface = user_input.to_f
      montant_m2 = category_data["montant_m2"].to_f
      surface * montant_m2

    when "montant_par_unite"
      # Prime par unité
      unites = user_input.to_f
      montant_unitaire = category_data["montant_unitaire"].to_f
      unites * montant_unitaire

    when "montant_m2_et_limite"
      # Type Flandre: Prime au m² avec surface max et plafond pourcentage
      surface = user_input.to_f
      montant_m2 = category_data["montant_m2"].to_f
      surface_max = category_data["surface_max"].to_f

      # Limiter la surface au maximum autorisé
      surface_prise_en_compte = [surface, surface_max].min
      montant_base = surface_prise_en_compte * montant_m2

      # Appliquer le plafond pourcentage si défini
      if category_data["plafond_pourcentage"]
        plafond_pct = category_data["plafond_pourcentage"].to_f / 100.0
        # Ici il faudrait le coût total des travaux, pour l'instant on retourne le montant de base
        montant_base
      else
        montant_base
      end

    when "pourcentage_et_plafond"
      # Type Flandre: Pourcentage du coût avec plafond maximum
      cout_travaux = user_input.to_f
      pourcentage = category_data["pourcentage"].to_f / 100.0
      plafond = category_data["plafond"].to_f

      montant_base = cout_travaux * pourcentage
      [montant_base, plafond].min

    when "forfait_et_plafond_facture"
      # Type Flandre: Forfait fixe OU pourcentage de la facture, selon le type choisi
      if category_data["forfaits"].present?
        # Cas pompe à chaleur : forfait selon le type + montant facture
        # L'user_input contient le montant de la facture
        # Il faudrait récupérer le type sélectionné séparément
        # Pour l'instant, on suppose un forfait moyen
        forfait_moyen = category_data["forfaits"].values.sum.to_f / category_data["forfaits"].size
        forfait_moyen
      elsif category_data["forfait"].present?
        # Cas chauffe-eau : forfait fixe avec plafond pourcentage
        forfait = category_data["forfait"].to_f
        if category_data["plafond_pourcentage"].present?
          cout_travaux = user_input.to_f
          plafond_pct = category_data["plafond_pourcentage"].to_f / 100.0
          plafond_facture = cout_travaux * plafond_pct
          [forfait, plafond_facture].min
        else
          forfait
        end
      else
        0
      end

    else
      @logger.warn "⚠️ Type de calcul inconnu: #{category_data['type']}"
      0
    end
  end

  def save_to_database(updated_params)
    @simulation.update!(
      parameters: updated_params.to_json,
      total_simule: updated_params["total_general"],
      updated_at: Time.current
    )

    @logger.info "💾 Simulation #{@simulation.id} sauvegardée: #{updated_params['total_general']}€"
  end

  def build_response(updated_params)
    {
      success: true,
      total_amount: updated_params["total_general"],
      category_used: updated_params["category_used"],
      updated_cards: build_cards_response(updated_params["prime_cards"]),
      timestamp: updated_params["calculation_timestamp"]
    }
  end

  def build_cards_response(prime_cards)
    response = {}

    prime_cards.each do |category_key, category_data|
      next unless category_data["primes"]

      primes_data = category_data["primes"].map do |prime|
        {
          slug: prime["slug"],
          titre: prime["titre"],
          calculated_amount: prime["calculated_amount"],
          user_input_value: prime["user_input_value"]
        }
      end

      response[category_key] = {
        total: category_data["total"],
        primes: primes_data
      }
    end

    response
  end
end
