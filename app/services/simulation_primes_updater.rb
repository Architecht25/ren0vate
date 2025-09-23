# Service pour mettre à jour les données de primes d'une simulation
class SimulationPrimesUpdater
  def initialize(simulation)
    @simulation = simulation
    @logger = Rails.logger
  end

  # Met à jour les saisies utilisateur et recalcule les montants
  def update_user_inputs(user_inputs, options = {})
    # Convertir en Hash si c'est des ActionController::Parameters
    user_inputs = user_inputs.to_h if user_inputs.respond_to?(:to_h)

    @logger.info "🔄 Mise à jour simulation #{@simulation.id} avec #{user_inputs.length} saisies"

    begin
      # Parser les paramètres existants
      current_params = parse_current_parameters

      # Option pour remplacer complètement les données (nettoyage)
      if options[:clean_replace] || should_clean_replace?(user_inputs, current_params)
        @logger.info "🧹 Nettoyage et remplacement complet des données"
        current_params = default_parameters
      end

      # Si pas de données utilisateur et pas de paramètres existants, initialiser la structure
      if user_inputs.empty? && current_params["prime_cards"].empty?
        @logger.info "📝 Initialisation de la structure de données pour simulation #{@simulation.id}"
        # Retourner une structure valide mais vide
        return {
          success: true,
          total_amount: 0,
          category_used: current_params["category_used"],
          updated_cards: {},
          timestamp: Time.current.iso8601,
          message: "Structure initialisée"
        }
      end

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

  # Détermine si on doit nettoyer et remplacer complètement
  def should_clean_replace?(user_inputs, current_params)
    return false if user_inputs.empty?
    return false if current_params["prime_cards"].empty?

    # Détecter si on a un mélange de régions dans les slugs existants
    existing_slugs = []
    current_params["prime_cards"].each do |_, category_data|
      next unless category_data["primes"]
      category_data["primes"].each do |prime|
        existing_slugs << prime["slug"] if prime["user_input_value"].present?
      end
    end

    # Compter les préfixes de région différents
    region_prefixes = existing_slugs.map { |slug| slug.split('_').first }.uniq
    has_multiple_regions = region_prefixes.length > 1

    # Aussi nettoyer si les nouveaux slugs sont d'une région différente
    new_slugs = user_inputs.keys
    new_region_prefixes = new_slugs.map { |slug| slug.split('_').first }.uniq
    different_region = (region_prefixes & new_region_prefixes).empty?

    if has_multiple_regions || different_region
      @logger.info "🔍 Nettoyage nécessaire: régions multiples=#{has_multiple_regions}, région différente=#{different_region}"
      @logger.info "   Existants: #{existing_slugs.first(3)}"
      @logger.info "   Nouveaux: #{new_slugs.first(3)}"
      return true
    end

    false
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
      "category_used" => get_simulation_category,
      "calculation_timestamp" => Time.current.iso8601
    }
  end

  def get_simulation_category
    # Utiliser le champ category de la simulation, ou un fallback
    category = @simulation.category.presence || @simulation.categorie.presence || "2"
    @logger.info "� Catégorie trouvée: #{category} (category=#{@simulation.category}, categorie=#{@simulation.categorie})"
    @logger.info "�💰 Recalcul avec catégorie: #{category}"
    category
  end

  def update_prime_inputs(current_params, user_inputs)
    prime_cards = current_params["prime_cards"] || {}

    # Si aucune structure de primes n'existe et qu'on a des saisies utilisateur,
    # créer une structure de base
    if prime_cards.empty? && user_inputs.any?
      @logger.info "🏗️ Création de structure de primes de base pour saisies utilisateur"
      prime_cards = create_basic_prime_structure_for_inputs(user_inputs)
    end

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

      # Si la prime n'est pas trouvée, la créer
      unless prime_found
        @logger.info "🆕 Création de prime manquante: #{prime_slug}"
        create_missing_prime(prime_cards, prime_slug, user_value)
      end
    end

    current_params["prime_cards"] = prime_cards
    current_params["last_update"] = Time.current.iso8601
    current_params
  end

  # Crée une structure de base pour les primes quand aucune n'existe
  def create_basic_prime_structure_for_inputs(user_inputs)
    prime_cards = {}

    user_inputs.each do |prime_slug, user_value|
      # Déterminer la catégorie depuis le slug
      category_key = extract_category_from_slug(prime_slug)

      # Initialiser la catégorie si elle n'existe pas
      unless prime_cards[category_key]
        prime_cards[category_key] = {
          "titre" => category_key.humanize,
          "total" => 0,
          "primes" => []
        }
      end

      # Créer la prime
      prime_data = {
        "slug" => prime_slug,
        "titre" => prime_slug.humanize,
        "user_input_value" => user_value,
        "calculated_amount" => 0,
        "category_data" => create_default_category_data(prime_slug)
      }

      prime_cards[category_key]["primes"] << prime_data
    end

    prime_cards
  end

  # Crée une prime manquante dans la structure existante
  def create_missing_prime(prime_cards, prime_slug, user_value)
    category_key = extract_category_from_slug(prime_slug)

    # Initialiser la catégorie si elle n'existe pas
    unless prime_cards[category_key]
      prime_cards[category_key] = {
        "titre" => category_key.humanize,
        "total" => 0,
        "primes" => []
      }
    end

    # Créer la prime
    prime_data = {
      "slug" => prime_slug,
      "titre" => prime_slug.humanize,
      "user_input_value" => user_value,
      "calculated_amount" => 0,
      "category_data" => create_default_category_data(prime_slug)
    }

    prime_cards[category_key]["primes"] << prime_data
  end

  # Extrait la catégorie depuis le slug de la prime
  def extract_category_from_slug(prime_slug)
    # Exemples de slugs:
    # wallonie_toiture_isolation_thermique -> toiture
    # flandre_isolation_sols -> isolation
    parts = prime_slug.split('_')

    if parts.length >= 3
      parts[1] # deuxième partie = catégorie
    else
      "general" # catégorie par défaut
    end
  end

  # Crée des données de catégorie à partir de la base de données
  def create_default_category_data(prime_slug)
    # Récupérer la prime depuis la base de données
    prime = Prime.find_by(slug: prime_slug, region: @simulation.region)

    if prime
      category_used = get_simulation_category

      # Récupérer les données pour la catégorie de revenus de la simulation
      if prime.valeurs_par_categorie.present?
        # valeurs_par_categorie peut être un Hash ou une chaîne JSON
        valeurs = case prime.valeurs_par_categorie
                  when Hash
                    prime.valeurs_par_categorie
                  when String
                    JSON.parse(prime.valeurs_par_categorie)
                  else
                    {}
                  end

        category_data = valeurs[category_used.to_s]

        if category_data
          @logger.info "🎯 Données réelles récupérées pour #{prime_slug} catégorie #{category_used}: #{category_data['type']}"
          return category_data
        else
          @logger.warn "⚠️ Pas de données pour #{prime_slug} catégorie #{category_used}, catégories disponibles: #{valeurs.keys}"
        end
      end
    else
      @logger.warn "⚠️ Prime #{prime_slug} non trouvée en base pour région #{@simulation.region}"
    end

    # Fallback aux anciennes données par défaut seulement si rien trouvé
    @logger.warn "🔄 Utilisation données par défaut pour #{prime_slug}"
    if prime_slug.include?('isolation') || prime_slug.include?('toiture')
      {
        "type" => "montant_m2",
        "montant_m2" => 20.0 # Valeur par défaut
      }
    elsif prime_slug.include?('audit') || prime_slug.include?('etude')
      {
        "type" => "montant_fixe",
        "montant" => 500.0 # Valeur par défaut
      }
    else
      {
        "type" => "montant_fixe",
        "montant" => 100.0 # Valeur par défaut très basique
      }
    end
  end

  def recalculate_amounts(params)
    return unless params["prime_cards"]

    # S'assurer que la catégorie est à jour
    params["category_used"] = get_simulation_category
    category_used = params["category_used"]

    @logger.info "💰 Recalcul avec catégorie: #{category_used}"

    # Extraire les user_inputs depuis les prime_cards
    user_inputs = extract_user_inputs_from_params(params)

    # Utiliser nos nouvelles méthodes calculate_all_primes si disponibles
    if user_inputs.present? && should_use_new_calculation_method?
      @logger.info "🚀 Utilisation des nouvelles méthodes calculate_all_primes"

      begin
        service = get_regional_calculator_service
        result = service.calculate_all_primes(user_inputs)

        total_general = result[:total_general] || 0
        params["total_general"] = total_general.round(2)
        params["total"] = total_general.round(2) # Compatibilité
        params["calculation_timestamp"] = Time.current.iso8601

        @logger.info "✅ Total calculé avec nouvelles méthodes: #{total_general}€"
        return

      rescue => e
        @logger.warn "⚠️ Erreur avec nouvelles méthodes, fallback vers ancien système: #{e.message}"
        # Fallback vers l'ancienne méthode en cas d'erreur
      end
    end

    # Ancienne méthode de calcul (fallback)
    @logger.info "📊 Utilisation de l'ancienne méthode de calcul"
    recalculate_amounts_legacy(params)
  end

  def extract_user_inputs_from_params(params)
    user_inputs = {}
    return user_inputs unless params["prime_cards"]

    params["prime_cards"].each do |category_key, category_data|
      next unless category_data["primes"]

      category_data["primes"].each do |prime|
        user_input = prime["user_input_value"]
        if user_input.present? && user_input != 0 && user_input != "0"
          user_inputs[prime["slug"]] = user_input
        end
      end
    end

    user_inputs
  end

  def should_use_new_calculation_method?
    # Utiliser les nouvelles méthodes pour Bruxelles et Wallonie
    %w[bruxelles wallonie].include?(@simulation.region&.downcase)
  end

  def get_regional_calculator_service
    case @simulation.region&.downcase
    when 'bruxelles'
      Regions::Bruxelles::BruxellesPostLoginCalculatorService.new({}, user: @simulation.user)
    when 'wallonie'
      Regions::Wallonie::WalloniePostLoginCalculatorService.new({}, user: @simulation.user)
    else
      raise "Service non disponible pour la région: #{@simulation.region}"
    end
  end

  def recalculate_amounts_legacy(params)
    total_general = 0.0

    params["prime_cards"].each do |category_key, category_data|
      next unless category_data["primes"]

      category_total = 0.0

      category_data["primes"].each do |prime|
        result = calculate_prime_amount(prime, params["category_used"])
        amount = result[:amount]
        calculation_params = result[:params]

        # S'assurer que le montant est un nombre valide
        amount = amount.to_f.round(2)
        prime["calculated_amount"] = amount
        prime["calculation_params"] = calculation_params
        category_total += amount
      end

      category_data["total"] = category_total.round(2)
      total_general += category_total

      @logger.debug "📊 #{category_key}: #{category_total}€"
    end

    params["total_general"] = total_general.round(2)
    params["total"] = total_general.round(2) # Compatibilité
    params["calculation_timestamp"] = Time.current.iso8601

    @logger.info "✅ Total général calculé (legacy): #{total_general}€"
  end

  def calculate_prime_amount(prime, category_used)
    user_input = prime["user_input_value"]
    category_data = prime["category_data"]

    if user_input.nil? || user_input == 0 || user_input == "0" || user_input == ""
      return { amount: 0, params: { error: "Pas d'input utilisateur" } }
    end

    unless category_data
      return { amount: 0, params: { error: "Pas de données catégorie" } }
    end

    case category_data["type"]
    when "montant_fixe"
      # Prime forfaitaire
      amount = user_input.to_i > 0 ? category_data["montant"].to_f : 0
      params = {
        calculation_type: "montant_fixe",
        user_input: user_input,
        montant_forfait: category_data["montant"],
        categorie: category_used
      }
      { amount: amount, params: params }

    when "montant_m2"
      # Prime au m²
      surface = user_input.to_f
      montant_m2 = category_data["montant_m2"].to_f
      amount = surface * montant_m2
      params = {
        calculation_type: "montant_m2",
        surface_m2: surface,
        montant_par_m2: montant_m2,
        categorie: category_used
      }
      { amount: amount, params: params }

    when "montant_par_unite"
      # Prime par unité
      unites = user_input.to_f
      montant_unitaire = category_data["montant_unitaire"].to_f
      amount = unites * montant_unitaire
      params = {
        calculation_type: "montant_par_unite",
        unites: unites,
        montant_unitaire: montant_unitaire,
        categorie: category_used
      }
      { amount: amount, params: params }

    when "montant_m2_et_limite"
      # Type Flandre: Prime au m² avec surface max et plafond pourcentage
      surface = user_input.to_f
      montant_m2 = category_data["montant_m2"].to_f
      surface_max = category_data["surface_max"].to_f

      # Limiter la surface au maximum autorisé
      surface_prise_en_compte = [surface, surface_max].min
      montant_base = surface_prise_en_compte * montant_m2

      # Appliquer le plafond pourcentage si défini
      final_amount = if category_data["plafond_pourcentage"]
        plafond_pct = category_data["plafond_pourcentage"].to_f / 100.0
        # Ici il faudrait le coût total des travaux, pour l'instant on retourne le montant de base
        montant_base
      else
        montant_base
      end

      params = {
        calculation_type: "montant_m2_et_limite",
        surface_m2: surface,
        surface_prise_en_compte: surface_prise_en_compte,
        montant_par_m2: montant_m2,
        surface_max: surface_max,
        plafond: category_data["plafond_pourcentage"] ? (category_data["plafond_pourcentage"].to_s + "%") : nil,
        categorie: category_used
      }
      { amount: final_amount, params: params }

    when "montant_variable_m2_et_limite"
      # Type Flandre: Prime au m² variable selon le type d'isolation avec surface max
      surface = user_input.to_f
      surface_max = category_data["surface_max"].to_f

      # Limiter la surface au maximum autorisé
      surface_prise_en_compte = [surface, surface_max].min

      # Déterminer le montant/m² selon le type d'isolation
      # Par défaut, on prend "exterieur" qui est le plus courant
      montants_m2 = category_data["montants_m2"] || {}
      montant_m2 = montants_m2["exterieur"] || montants_m2.values.first || 0

      @logger.info "🏗️ Calcul variable m² - Type: exterieur, Surface: #{surface_prise_en_compte}m², Montant/m²: #{montant_m2}€"

      montant_base = surface_prise_en_compte * montant_m2.to_f

      # Appliquer le plafond pourcentage si défini
      final_amount = if category_data["plafond_pourcentage"]
        plafond_pct = category_data["plafond_pourcentage"].to_f / 100.0
        # Ici il faudrait le coût total des travaux, pour l'instant on retourne le montant de base
        montant_base
      else
        montant_base
      end

      params = {
        calculation_type: "montant_variable_m2_et_limite",
        surface_m2: surface,
        surface_prise_en_compte: surface_prise_en_compte,
        montant_par_m2: montant_m2,
        surface_max: surface_max,
        type_isolation: "exterieur",
        plafond: category_data["plafond_pourcentage"] ? (category_data["plafond_pourcentage"].to_s + "%") : nil,
        categorie: category_used
      }
      { amount: final_amount, params: params }

    when "pourcentage_et_plafond"
      # Type Flandre: Pourcentage du coût avec plafond maximum
      cout_travaux = user_input.to_f
      pourcentage = category_data["pourcentage"].to_f / 100.0
      plafond = category_data["plafond"].to_f

      montant_base = cout_travaux * pourcentage
      final_amount = [montant_base, plafond].min

      params = {
        calculation_type: "pourcentage_et_plafond",
        cout_travaux: cout_travaux,
        pourcentage: category_data["pourcentage"],
        plafond: plafond,
        montant_avant_plafond: montant_base,
        categorie: category_used
      }
      { amount: final_amount, params: params }

    when "forfait_et_plafond_facture"
      # Type Flandre: Forfait fixe OU pourcentage de la facture, selon le type choisi
      if category_data["forfaits"].present?
        # Cas pompe à chaleur : forfait selon le type + plafond pourcentage facture
        cout_facture = user_input.to_f

        # Pour l'instant, utiliser le forfait air-eau (le plus courant)
        # TODO: L'interface devra envoyer le type de pompe sélectionné
        forfait_base = category_data["forfaits"]["air_eau"] || category_data["forfaits"].values.first || 0

        # Si la facture est très faible (< 100€), considérer que c'est juste une sélection
        # et retourner le forfait de base
        if cout_facture < 100
          final_amount = forfait_base.to_f
          params = {
            calculation_type: "forfait_et_plafond_facture",
            forfait_base: forfait_base,
            cout_facture: cout_facture,
            type_pompe: "air_eau",
            mode: "forfait_seul",
            categorie: category_used
          }
        else
          # Appliquer le plafond pourcentage si défini
          if category_data["plafond_pourcentage"].present?
            plafond_pct = category_data["plafond_pourcentage"].to_f / 100.0
            plafond_facture = cout_facture * plafond_pct
            # Le montant est le minimum entre le forfait et le plafond pourcentage
            final_amount = [forfait_base.to_f, plafond_facture].min
            params = {
              calculation_type: "forfait_et_plafond_facture",
              forfait_base: forfait_base,
              cout_facture: cout_facture,
              plafond_pourcentage: category_data["plafond_pourcentage"],
              plafond_facture: plafond_facture,
              type_pompe: "air_eau",
              mode: "forfait_avec_plafond",
              categorie: category_used
            }
          else
            final_amount = forfait_base.to_f
            params = {
              calculation_type: "forfait_et_plafond_facture",
              forfait_base: forfait_base,
              cout_facture: cout_facture,
              type_pompe: "air_eau",
              mode: "forfait_seul",
              categorie: category_used
            }
          end
        end
      elsif category_data["forfait"].present?
        # Cas chauffe-eau : forfait fixe avec plafond pourcentage
        forfait = category_data["forfait"].to_f
        if category_data["plafond_pourcentage"].present?
          cout_travaux = user_input.to_f
          plafond_pct = category_data["plafond_pourcentage"].to_f / 100.0
          plafond_facture = cout_travaux * plafond_pct
          final_amount = [forfait, plafond_facture].min
          params = {
            calculation_type: "forfait_et_plafond_facture",
            forfait: forfait,
            cout_travaux: cout_travaux,
            plafond_pourcentage: category_data["plafond_pourcentage"],
            plafond_facture: plafond_facture,
            mode: "forfait_avec_plafond",
            categorie: category_used
          }
        else
          final_amount = forfait
          params = {
            calculation_type: "forfait_et_plafond_facture",
            forfait: forfait,
            cout_travaux: user_input,
            mode: "forfait_seul",
            categorie: category_used
          }
        end
      else
        final_amount = 0
        params = {
          calculation_type: "forfait_et_plafond_facture",
          error: "Pas de forfait défini",
          categorie: category_used
        }
      end

      { amount: final_amount, params: params }

    else
      @logger.warn "⚠️ Type de calcul inconnu: #{category_data['type']}"
      { amount: 0, params: { error: "Type de calcul inconnu: #{category_data['type']}", categorie: category_used } }
    end
  end

  def save_to_database(updated_params)
    # Calculer le total à partir des paramètres
    total_amount = updated_params["total_general"] || updated_params["total"] || 0

    # S'assurer que le total est un nombre valide
    total_amount = total_amount.to_f.round(2)

    # S'assurer que updated_params est un Hash avant conversion JSON
    params_json = case updated_params
                  when Hash
                    updated_params.to_json
                  when String
                    updated_params
                  else
                    @logger.error "❌ Type inattendu pour updated_params: #{updated_params.class}"
                    "{}"
                  end

    # Sauvegarder avec vérification d'erreur
    success = @simulation.update(
      parameters: params_json,
      total_simule: total_amount,
      updated_at: Time.current
    )

    if success
      @logger.info "💾 Simulation #{@simulation.id} sauvegardée: #{total_amount}€"
      # Vérification de la sauvegarde
      @simulation.reload
      if @simulation.total_simule != total_amount
        @logger.error "❌ Erreur: total_simule incohérent après sauvegarde"
      end
    else
      @logger.error "❌ Échec de la sauvegarde: #{@simulation.errors.full_messages.join(', ')}"
      raise "Échec de la sauvegarde: #{@simulation.errors.full_messages.join(', ')}"
    end
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
