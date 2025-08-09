# Calculateur de primes post-login pour Flandre
# Basé sur le modèle Wallonie qui fonctionne, adapté aux données Flandre

module Regions
  module Flandre
    class FlandrePostLoginCalculatorService < Regions::BaseService
      
      def generate_prime_cards(category_result)
        log_calculation("Génération cartes primes Flandre", category_result)

        category = category_result[:category]
        user_property = user_property()

        return { prime_cards: {}, total_general: 0 } unless user_property

        eligible_categories = determine_eligible_categories(category)
        user_property = @property

        organize_primes_into_cards(eligible_categories, category)
      end

      private

      def organize_primes_into_cards(eligible_categories, user_category)
        start_time = Time.current
        prime_cards = {}
        total_general = 0

        # Récupérer toutes les primes éligibles
        all_primes = Prime.where(category_id: eligible_categories, region: 'flandre')
        
        # Organiser par type de travaux logique
        organized_groups = organize_by_work_type(all_primes)
        
        organized_groups.each do |group_key, group_primes|
          next if group_primes.empty?
          
          category_data = build_grouped_prime_data(group_primes, user_category, group_key)
          next if category_data[:primes].empty?

          prime_cards[group_key] = category_data
          total_general += category_data[:total]
        end

        duration = Time.current - start_time
        log_calculation("Calculation completed in #{duration.round(3)}s for #{prime_cards.count} logical groups")

        {
          prime_cards: prime_cards,
          total_general: total_general,
          category_used: user_category,
          calculation_timestamp: Time.current.iso8601,
          calculation_duration: duration.round(3)
        }
      end

      def determine_eligible_categories(user_category)
        # Mapping des catégories de revenus vers les catégories de primes éligibles
        case user_category.to_s
        when '1', '2'
          [95, 97] # Isolation générale + isolation murs cat 1-2
        when '3', '4'
          [95, 96] # Isolation générale + isolation murs cat 3-4
        else
          [95] # Catégorie par défaut
        end
      end

      def organize_by_work_type(all_primes)
        groups = {
          'isolation_enveloppe' => [],
          'menuiserie' => [],
          'chauffage' => [],
          'travaux_preparatoires' => [],
          'renovation_associee' => []
        }

        all_primes.each do |prime|
          group_key = determine_work_type_group(prime)
          groups[group_key] << prime if groups.key?(group_key)
        end

        groups
      end

      def determine_work_type_group(prime)
        slug = prime.slug.downcase

        case slug
        when /isolation_toiture|isolation_sol|isolation_mur/
          'isolation_enveloppe'
        when /ramen|deuren|fenetre|porte/
          'menuiserie'
        when /warmtepomp|chaudiere|chauffage|warmtepompboiler/
          'chauffage'
        when /voorbereiding|preparation/
          'travaux_preparatoires'
        when /renovation/
          'renovation_associee'
        else
          'isolation_enveloppe' # par défaut
        end
      end

      def build_grouped_prime_data(group_primes, user_category, group_key)
        group_info = get_work_type_info(group_key)
        primes_data = []
        total = 0

        group_primes.each do |prime|
          next unless prime_eligible_for_category?(prime, user_category)

          prime_data = {
            id: prime.id,
            slug: prime.slug,
            titre: prime.titre,
            unite: prime.unite || "€",
            type: prime.type_de_valeur,
            input_type: determine_input_type(prime),
            placeholder: determine_placeholder(prime),
            calculated_amount: 0,
            user_input_value: determine_default_value(prime),
            conditions: prime.condition || "Voir conditions sur le site officiel",
            conseil: prime.conseil || "Faites appel à un professionnel certifié",
            category_data: build_category_data(prime)
          }

          primes_data << prime_data
        end

        {
          id: group_info[:key],
          title: group_info[:title],
          icon: group_info[:icon],
          primes: primes_data,
          total: total
        }
      end

      def get_work_type_info(group_key)
        # Mapping des groupes logiques vers les infos d'affichage
        work_type_mapping = {
          'isolation_enveloppe' => { key: "isolation_enveloppe", title: "Isolation de l'enveloppe", icon: "house-gear" },
          'menuiserie' => { key: "menuiserie", title: "Menuiserie", icon: "door-open" },
          'chauffage' => { key: "chauffage", title: "Chauffage et eau chaude", icon: "thermometer-half" },
          'travaux_preparatoires' => { key: "travaux_preparatoires", title: "Travaux préparatoires", icon: "tools" },
          'renovation_associee' => { key: "renovation_associee", title: "Rénovation associée", icon: "house-check" }
        }

        work_type_mapping[group_key] || { key: "autre", title: "Autres travaux", icon: "cog" }
      end

      def build_prime_data(category_primes, user_category, property, category_id)
        category_info = get_category_info(category_id)
        primes_data = []
        total = 0

        category_primes.each do |prime|
          next unless prime_eligible_for_category?(prime, user_category)

          prime_data = {
            id: prime.id,
            slug: prime.slug,
            titre: prime.titre,
            unite: prime.unite || "€",
            type: prime.type_de_valeur,
            input_type: determine_input_type(prime),
            placeholder: determine_placeholder(prime),
            calculated_amount: 0,
            user_input_value: determine_default_value(prime),
            conditions: prime.condition || "Voir conditions sur le site officiel",
            conseil: prime.conseil || "Faites appel à un professionnel certifié",
            category_data: build_category_data(prime)
          }

          primes_data << prime_data
        end

        {
          id: category_info[:key],
          title: category_info[:title],
          icon: category_info[:icon],
          primes: primes_data,
          total: total
        }
      end

      def get_category_info(category_id)
        # Mapping des IDs de catégories vers les infos d'affichage
        category_mapping = {
          95 => { key: "isolation_envelope", title: "Isolation de l'enveloppe", icon: "house-gear" },
          96 => { key: "isolation_murs_cat34", title: "Isolation murs (cat. 3-4)", icon: "bricks" },
          97 => { key: "isolation_murs_cat12", title: "Isolation murs (cat. 1-2)", icon: "bricks" },
          98 => { key: "chauffage_eau", title: "Chauffage et eau", icon: "thermometer-half" },
          99 => { key: "ouvertures", title: "Ouvertures", icon: "door-open" },
          100 => { key: "travaux_preparatoires", title: "Travaux préparatoires", icon: "tools" },
          101 => { key: "renovation_associee", title: "Rénovation associée", icon: "house-check" }
        }

        category_mapping[category_id] || { key: "autre", title: "Autres travaux", icon: "cog" }
      end

      def determine_category_key(category_id)
        get_category_info(category_id)[:key]
      end

      def prime_eligible_for_category?(prime, user_category)
        return true if prime.eligible_categories.blank?
        prime.eligible_categories.include?(user_category.to_s)
      end

      def determine_input_type(prime)
        case prime.type_de_valeur
        when 'montant_fixe', 'forfait'
          'checkbox'
        when 'dynamique', 'surface', 'montant_variable_m2_et_limite', 'montant_facture', 'facture', 'montant'
          'number'
        else
          'text'
        end
      end

      def determine_placeholder(prime)
        case prime.slug
        when 'isolation_toiture'
          "Surface toiture en m²"
        when 'isolation_sol'
          "Surface plancher en m²"
        when 'isolation_murs_cat34', 'isolation_murs_cat12'
          "Montant facture isolation murs"
        when 'ramen_deuren'
          "Surface portes et fenêtres en m²"
        when 'warmtepomp'
          "Pompe à chaleur installée (oui/non)"
        when 'warmtepompboiler'
          "Montant boiler thermodynamique"
        when 'voorbereiding_isolatie'
          "Montant facture préparation isolation"
        when 'voorbereiding_sanitair_elec'
          "Montant facture préparation sanitaire/électrique"
        when 'renovation_toiture'
          "Surface toiture rénovée en m²"
        when 'renovation_murs'
          "Surface murs rénovés en m²"
        when 'renovation_sol'
          "Surface sol rénové en m²"
        else
          case prime.type_de_valeur
          when 'montant_fixe', 'forfait'
            "Forfaitaire - cocher si applicable"
          when 'surface', 'montant_variable_m2_et_limite'
            "Surface en m²"
          when 'dynamique', 'montant'
            "Montant en €"
          when 'montant_facture', 'facture'
            "Montant total de la facture"
          else
            "Valeur"
          end
        end
      end

      def determine_default_value(prime)
        case prime.type_de_valeur
        when 'montant_fixe', 'forfait'
          0
        else
          0
        end
      end

      def build_category_data(prime)
        {
          type: prime.type_de_valeur,
          condition: prime.condition || "Selon conditions Flandre",
          montant: prime.plafond || 0
        }
      end

      def log_calculation(message, data = nil)
        puts "[Regions::Flandre::FlandrePostLoginCalculatorService] #{message}"
        puts "  Data: #{data}" if data
      end
    end
  end
end
