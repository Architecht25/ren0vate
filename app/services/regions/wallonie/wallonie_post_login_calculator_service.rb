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

        {
          cards: cards_hash,
          total: total_general,
          category_used: category
        }
      end

      private

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
