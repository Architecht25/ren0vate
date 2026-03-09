# Calculateur de primes post-login pour la Wallonie
# Version complète avec données utilisateur précises

module Regions
  module Wallonie
    class WalloniePostLoginCalculatorService < Regions::BaseService
      def calculate_primes(category_result)
        log_calculation("Début calcul primes post-login Wallonie", category_result)

        category = category_result[:category]
        user_property = user_property()

        return [] unless user_property

        primes = Prime.where(region: 'wallonie').order(:ordre_affichage)
        calculate_precise_primes(primes, category, user_property)
      end

      # Méthode publique pour calculer toutes les primes avec inputs utilisateur
      def calculate_all_primes(inputs)
        # Stocker les inputs temporairement
        @params = { user_inputs: inputs }

        # Récupérer la catégorie et propriété utilisateur
        category = @category || determine_user_category()
        user_property = user_property()

        return { prime_results: {}, total_general: 0 } unless user_property

        # Récupérer toutes les primes Wallonie
        primes = Prime.where(region: 'wallonie').order(:ordre_affichage)

        results = {}
        total_general = 0

        primes.each do |prime|
          next unless prime_eligible_for_category?(prime, category)

          # Convertir R1, R2, etc. en wallonie_r1, wallonie_r2, etc.
          wallonie_category = category.match?(/^R\d+$/) ? "wallonie_#{category.downcase}" : category
          category_data = prime.valeurs_par_categorie&.[](wallonie_category)
          next unless category_data

          # Récupérer la saisie utilisateur pour cette prime
          user_input_value = inputs[prime.slug] || inputs[prime.slug.to_s]

          # Calculer le montant selon le type et la saisie utilisateur
          calculated_amount = calculate_amount_with_user_input(
            prime,
            category_data,
            user_property,
            user_input_value
          )

          if calculated_amount > 0
            results[prime.slug] = {
              amount: calculated_amount,
              prime_id: prime.id,
              titre: prime.titre,
              unite: prime.unite
            }
            total_general += calculated_amount
          end
        end

        {
          prime_results: results,
          total_general: total_general
        }
      end

      # Méthode publique pour calculer une prime individuelle (utilisée par l'API AJAX)
      def calculate_prime(prime_slug, input_value, input_type = nil)
        Rails.logger.info "🔍 Calcul prime Wallonie: slug=#{prime_slug}, value=#{input_value}, type=#{input_type}"

        # Récupérer la prime depuis la base de données
        prime = Prime.find_by(slug: prime_slug, region: 'wallonie')
        unless prime
          Rails.logger.warn "❌ Prime non trouvée: slug=#{prime_slug}, region=wallonie"
          return { error: 'Prime non trouvée' }
        end
        Rails.logger.info "✅ Prime trouvée: #{prime.titre}"

        # Récupérer la catégorie utilisateur
        user_category = @category || determine_user_category
        Rails.logger.info "🏷️ Catégorie utilisateur: #{user_category}"

        # Convertir R1, R2, etc. en wallonie_r1, wallonie_r2, etc.
        wallonie_category = user_category.match?(/^R\d+$/) ? "wallonie_#{user_category.downcase}" : user_category.to_s

        # Récupérer les données de catégorie
        category_data = prime.valeurs_par_categorie&.[](wallonie_category)
        unless category_data
          Rails.logger.warn "❌ Catégorie #{wallonie_category} non éligible pour #{prime_slug}"
          return { error: "Catégorie #{wallonie_category} non éligible pour #{prime_slug}" }
        end
        Rails.logger.info "📊 Données catégorie: #{category_data.inspect}"

        val = input_value.to_f
        montant = 0

        # Calculer le montant selon le type de prime
        case category_data['type']
        when 'montant_fixe', 'montant_forfaitaire'
          # Montant fixe forfaitaire (ex: appropriation charpente)
          # input_value devrait être 1 (oui) ou 0 (non)
          if val > 0
            montant = category_data['montant'].to_f
          end

        when 'montant_m2'
          # Montant par m² (ex: remplacement couverture, isolation)
          montant_m2 = category_data['montant_m2'].to_f
          surface_max = category_data['surface_max']&.to_f || Float::INFINITY
          surface = [val, surface_max].min
          montant = surface * montant_m2

        when 'pourcentage'
          # Pourcentage du montant des travaux avec plafond (ex: certaines installations)
          pourcentage = category_data['pourcentage'].to_f
          plafond = category_data['plafond']&.to_f || Float::INFINITY
          montant_calcule = (val * pourcentage) / 100.0
          montant = [montant_calcule, plafond].min

        when 'montant_variable'
          # Montant variable selon sous-type (ex: PAC air/eau vs air/air)
          if input_type.present? && category_data['montants'].is_a?(Hash)
            montant = category_data['montants'][input_type].to_f
          else
            montant = category_data['montant_defaut']&.to_f || 0
          end

        when 'montant_unite'
          # Montant par unité (ex: nombre de fenêtres, radiateurs)
          montant_par_unite = category_data['montant_par_unite'].to_f
          nombre_unites = val.to_i
          montant = nombre_unites * montant_par_unite

        else
          Rails.logger.warn "⚠️ Type de prime non pris en charge: #{category_data['type']}"
          return { error: "Type de prime non pris en charge : #{category_data['type']}" }
        end

        Rails.logger.info "💰 Montant calculé: #{montant}€"

        {
          calculated_amount: montant,
          user_input_value: val,
          category_data: category_data,
          prime_title: prime.titre,
          prime_unite: prime.unite
        }
      end

      private

      def calculate_precise_primes(primes, category, property)
        calculated_primes = []

        primes.each do |prime|
          next unless prime_eligible_for_category?(prime, category)

          precise_amount = calculate_precise_amount(prime, category, property)
          next if precise_amount <= 0

          calculated_primes << {
            prime_id: prime.id,
            slug: prime.slug,
            titre: prime.titre,
            precise_amount: precise_amount,
            unite: prime.unite,
            calculation_type: "precise",
            conditions: prime.condition,
            conseil: prime.conseil,
            category_used: category,
            property_data: relevant_property_data(property, prime),
            calculation_details: build_calculation_details(prime, category, property, precise_amount)
          }
        end

        calculated_primes
      end

      def prime_eligible_for_category?(prime, category)
        return false unless prime.eligible_categories.present?

        # Convertir R1, R2, etc. en wallonie_r1, wallonie_r2, etc.
        wallonie_category = category.match?(/^R\d+$/) ? "wallonie_#{category.downcase}" : category

        prime.eligible_categories.include?(wallonie_category)
      end

      def calculate_precise_amount(prime, category, property)
        # Convertir R1, R2, etc. en wallonie_r1, wallonie_r2, etc.
        wallonie_category = category.match?(/^R\d+$/) ? "wallonie_#{category.downcase}" : category
        category_data = prime.valeurs_par_categorie&.[](wallonie_category)
        return 0 unless category_data

        case category_data["type"]
        when "montant_fixe"
          category_data["montant"] || 0

        when "montant_m2"
          surface = get_relevant_surface(property, prime)
          return 0 unless surface&.positive?

          montant_m2 = category_data["montant_m2"] || 0
          surface_max = category_data["surface_max"]

          effective_surface = surface_max ? [surface, surface_max].min : surface
          effective_surface * montant_m2

        when "pourcentage"
          # Nécessite le montant des travaux (depuis les paramètres ou propriété)
          montant_travaux = get_work_amount(property, prime)
          return 0 unless montant_travaux&.positive?

          pourcentage = category_data["pourcentage"] || 0
          plafond = category_data["plafond"]

          montant_calcule = (montant_travaux * pourcentage) / 100
          plafond ? [montant_calcule, plafond].min : montant_calcule

        when "montant_variable"
          # Basé sur des caractéristiques spécifiques
          calculate_variable_amount(prime, category_data, property)

        else
          0
        end
      end

      def get_relevant_surface(property, prime)
        # Déterminer la surface pertinente selon le type de prime
        case prime.slug
        when /toiture|toit/
          property.roof_surface
        when /facade|mur/
          property.wall_surface
        when /sol|plancher/
          property.floor_surface
        else
          property.total_surface || property.liveable_surface
        end
      end

      def get_work_amount(property, prime)
        # Récupérer le montant des travaux depuis les projets/simulations
        # ou depuis les paramètres du calcul
        work_amount = get_param(:montant_travaux) || get_param("montant_travaux_#{prime.slug}")
        return work_amount.to_f if work_amount

        # Sinon chercher dans les projets de la propriété
        property.projects&.sum(&:estimated_cost) || 0
      end

      def calculate_variable_amount(prime, category_data, property)
        # Logique spécifique selon le type de prime
        case prime.slug
        when /chaudiere|chauffage/
          calculate_heating_amount(category_data, property)
        when /ventilation/
          calculate_ventilation_amount(category_data, property)
        else
          category_data["montant_defaut"] || 0
        end
      end

      def calculate_heating_amount(category_data, property)
        # Exemple de calcul pour chaudière selon puissance
        puissance = property.heating_power || get_param(:puissance_chaudiere)
        return 0 unless puissance

        if puissance <= 100
          category_data["montant_jusque_100kw"] || 0
        else
          category_data["montant_plus_100kw"] || 0
        end
      end

      def calculate_ventilation_amount(category_data, property)
        # Calcul selon le nombre de logements
        nb_logements = property.housing_units || 1
        montant_par_logement = category_data["montant_par_logement"] || 0

        nb_logements * montant_par_logement
      end

      def relevant_property_data(property, prime)
        {
          total_surface: property.total_surface,
          construction_year: property.construction_year,
          property_type: property.property_type,
          heating_type: property.heating_type
        }
      end

      def build_calculation_details(prime, category, property, amount)
        {
          prime_slug: prime.slug,
          category: category,
          calculation_method: "post_login_precise",
          amount: amount,
          timestamp: Time.current
        }
      end

      public

      def generate_prime_cards(category_result)
        log_calculation("Génération cartes primes Wallonie", category_result)

        category = category_result[:category]
        user_property = user_property()

        return { cards: {}, total: 0 } unless user_property

        primes = Prime.where(region: 'wallonie').order(:ordre_affichage)
        organize_primes_into_cards(primes, category, user_property)
      end

      def organize_primes_into_cards(primes, category, property)
        # Créer les cartes par catégorie
        cards_hash = {}

        # Audit énergétique
        audit_primes = primes.select { |p| p.slug.include?('audit') }
        if audit_primes.any?
          card_primes = audit_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['audit'] = {
              id: 'audit',
              title: 'Audit énergétique',
              icon: 'search',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        # Toiture (inclut les primes wallonie + génériques)
        toiture_primes = primes.select { |p|
          p.slug.include?('toiture') &&
          (p.slug.include?('wallonie_') || p.slug == 'isolation_toiture' || p.slug == 'renovation_toiture')
        }
        if toiture_primes.any?
          card_primes = toiture_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['toiture'] = {
              id: 'toiture',
              title: 'Travaux de toiture',
              icon: 'house-check',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        # Murs et façades (7 primes Wallonie)
        murs_primes = primes.select { |p|
          p.slug.include?('wallonie_') &&
          (p.slug.include?('mur') || p.slug.include?('merule') || p.slug.include?('radon'))
        }
        if murs_primes.any?
          card_primes = murs_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['murs'] = {
              id: 'murs',
              title: 'Travaux Murs',
              icon: 'bricks',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        # Sols (seulement les 4 primes sols spécifiques)
        sols_primes = primes.select { |p|
          p.slug.include?('isolation_sols') ||
          p.slug.include?('remplacement_supports_circulation') ||
          p.slug.include?('isolation_finition_planchers')
        }
        if sols_primes.any?
          card_primes = sols_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['sols'] = {
              id: 'sols',
              title: 'Isolation de sols',
              icon: 'layer-group',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        # Menuiseries
        menuiseries_primes = primes.select { |p| p.slug.include?('menuiseries') || p.slug.include?('vitrages') }
        if menuiseries_primes.any?
          card_primes = menuiseries_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['menuiseries'] = {
              id: 'menuiseries',
              title: 'Menuiseries',
              icon: 'door-open',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        # SUPPRESSION DE LA CATÉGORIE INSTALLATIONS (erronée)

        # Installation électrique
        installation_electrique_primes = primes.select { |p| p.slug.include?('installation_electrique') }
        if installation_electrique_primes.any?
          card_primes = installation_electrique_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['installation_electrique'] = {
              id: 'installation_electrique',
              title: 'Installation électrique',
              icon: 'lightning-charge',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        # Installation gaz
        installation_gaz_primes = primes.select { |p| p.slug.include?('installation_gaz') }
        if installation_gaz_primes.any?
          card_primes = installation_gaz_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['installation_gaz'] = {
              id: 'installation_gaz',
              title: 'Installation gaz',
              icon: 'fire',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        # Système chauffage (5 primes principales)
        systeme_chauffage_primes = primes.select { |p|
          p.slug.include?('pac_') ||
          p.slug.include?('chaudiere') ||
          p.slug.include?('chauffe_eau_solaire') ||
          p.slug.include?('poele')
        }
        if systeme_chauffage_primes.any?
          card_primes = systeme_chauffage_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['systeme_chauffage'] = {
              id: 'systeme_chauffage',
              title: 'Système chauffage',
              icon: 'thermometer-half',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        # Améliorations chauffage (9 primes d'amélioration)
        ameliorations_chauffage_primes = primes.select { |p| p.slug.include?('chauffage_') }
        if ameliorations_chauffage_primes.any?
          card_primes = ameliorations_chauffage_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['ameliorations_chauffage'] = {
              id: 'ameliorations_chauffage',
              title: 'Améliorations chauffage',
              icon: 'cog',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        # Ventilation (4 primes)
        ventilation_primes = primes.select { |p| p.slug.include?('vmc') }
        if ventilation_primes.any?
          card_primes = ventilation_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['ventilation'] = {
              id: 'ventilation',
              title: 'Ventilation',
              icon: 'wind',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        # ECS - Eau Chaude Sanitaire (6 primes)
        ecs_primes = primes.select { |p| p.slug.include?('ecs_') }
        if ecs_primes.any?
          card_primes = ecs_primes.map { |prime| build_prime_data(prime, category, property) }.compact
          if card_primes.any?
            cards_hash['ecs'] = {
              id: 'ecs',
              title: 'Eau chaude sanitaire',
              icon: 'tint',
              primes: card_primes,
              total: card_primes.sum { |p| p[:calculated_amount] }
            }
          end
        end

        total_general = cards_hash.values.sum { |card| card[:total] }

        # Retourner une structure unifiée compatible avec calculate_all_primes
        # ET rétrocompatible avec l'ancien système de cartes
        {
          prime_cards: cards_hash,      # Pour rétrocompatibilité
          total_general: total_general, # Format unifié
          category_used: category,

          # Format compatible avec calculate_all_primes (pour unification future)
          prime_results: flatten_cards_to_primes(cards_hash),
          total: total_general          # Alias pour :total_general
        }
      end

      private

      # Convertit le format cartes en format prime_results pour unification
      def flatten_cards_to_primes(cards_hash)
        prime_results = {}

        cards_hash.each do |card_id, card_data|
          next unless card_data[:primes].is_a?(Array)

          card_data[:primes].each do |prime_data|
            prime_slug = prime_data[:slug]
            prime_results[prime_slug] = {
              amount: prime_data[:calculated_amount] || 0,
              prime_id: prime_data[:prime_id],
              titre: prime_data[:titre],
              unite: prime_data[:unite]
            }
          end
        end

        prime_results
      end

      def determine_user_category
        # Utiliser le WallonieCategoryService dédié pour le calcul de catégorie
        return @category if @category.present?

        category_service = Regions::Wallonie::WallonieCategoryService.new({}, user: @user)
        result = category_service.determine_category

        if result[:eligible] && result[:category]
          @category = result[:category].to_s
        else
          @category = "R2" # Catégorie par défaut
        end

        @category
      end

      def user_inputs
        # Récupérer les saisies utilisateur depuis les paramètres
        @params[:user_inputs] || {}
      end

      def build_prime_data(prime, category, property)
        return nil unless prime_eligible_for_category?(prime, category)

        # Convertir R1, R2, etc. en wallonie_r1, wallonie_r2, etc.
        wallonie_category = category.match?(/^R\d+$/) ? "wallonie_#{category.downcase}" : category
        category_data = prime.valeurs_par_categorie&.[](wallonie_category)
        return nil unless category_data

        # Récupérer la saisie utilisateur pour cette prime
        user_input_value = user_inputs[prime.slug] || user_inputs[prime.slug.to_s]

        # Calculer le montant selon le type et la saisie utilisateur
        calculated_amount = calculate_amount_with_user_input(
          prime,
          category_data,
          property,
          user_input_value
        )

        # Toujours retourner la prime pour permettre l'interaction utilisateur
        # même si le montant calculé est 0
        {
          id: prime.id,
          slug: prime.slug,
          titre: prime.titre,
          unite: prime.unite,
          type: category_data["type"],
          input_type: determine_input_type(category_data["type"]),
          placeholder: prime.placeholder&.[](wallonie_category)&.presence || "Entrez la valeur",
          calculated_amount: calculated_amount,
          user_input_value: user_input_value, # Sauvegarder la saisie
          conditions: prime.condition,
          conseil: prime.conseil,
          category_data: category_data
        }
      end

      def calculate_amount_with_user_input(prime, category_data, property, user_input)
        # Si pas de saisie utilisateur, utiliser la logique par défaut
        return calculate_default_amount(prime, category_data, property) unless user_input.present?

        case category_data["type"]
        when "montant_fixe"
          # 0 ou 1 (Non/Oui)
          user_input.to_i == 1 ? (category_data["montant"] || 0) : 0
        when "montant_m2"
          # Surface saisie * montant au m²
          surface = user_input.to_f
          montant_m2 = category_data["montant_m2"] || 0
          surface_max = category_data["surface_max"]

          effective_surface = surface_max ? [surface, surface_max].min : surface
          effective_surface * montant_m2
        when "pourcentage"
          # Montant des travaux saisi * pourcentage
          montant_travaux = user_input.to_f
          pourcentage = category_data["pourcentage"] || 0
          plafond = category_data["plafond"]

          montant_calcule = (montant_travaux * pourcentage) / 100
          plafond ? [montant_calcule, plafond].min : montant_calcule
        else
          0
        end
      end

      def calculate_default_amount(prime, category_data, property)
        # Commencer à 0€ par défaut - l'utilisateur doit interagir pour voir les montants
        0
      end

      def determine_input_type(type)
        case type
        when "montant_fixe"
          "checkbox"
        when "montant_m2", "pourcentage"
          "number"
        else
          "text"
        end
      end

      def get_relevant_surface(property, prime)
        # Retourner la surface réelle de la propriété, sinon 0
        property&.surface_habitable || 0
      end

      def get_work_amount(property, prime)
        # Pas de montant par défaut - l'utilisateur doit saisir
        0
      end
    end
  end
end
