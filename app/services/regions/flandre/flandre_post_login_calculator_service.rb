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

      # Méthodes de calcul dynamique des primes (publiques pour l'API)
      def calculate_prime(prime_slug, input_value, input_type = nil)
        prime = Prime.find_by(slug: prime_slug, region: 'flandre')
        return { error: 'Prime non trouvée' } unless prime

        user_category = @category || determine_user_category
        category_data = prime.valeurs_par_categorie&.[](user_category.to_s)

        return { error: "Catégorie #{user_category} non éligible pour #{prime_slug}" } unless category_data

        val = input_value.to_f
        montant = 0

        case category_data['type']
        when 'pourcentage_et_plafond'
          # Catégories 3-4: pourcentage du montant facture avec plafond
          pourcentage = category_data['pourcentage'].to_f
          plafond = category_data['plafond'].to_f
          montant = [(val * pourcentage / 100.0), plafond].min

        when 'montant_m2_et_limite'
          # Catégories 1-2: montant par m² avec limite de surface
          surface_max = category_data['surface_max']&.to_f || Float::INFINITY
          surface = [val, surface_max].min
          montant_m2 = category_data['montant_m2'].to_f
          montant = surface * montant_m2

        when 'montant_variable_m2_et_limite'
          # Isolation murs avec types différents
          type_mur = input_type || 'exterieur'
          montants_m2 = category_data['montants_m2'] || {}
          montant_m2 = montants_m2[type_mur].to_f
          surface_max = category_data['surface_max']&.to_f || Float::INFINITY
          surface = [val, surface_max].min
          montant = surface * montant_m2

        when 'forfait_et_plafond_facture'
          if prime_slug == 'warmtepompboiler'
            # Chauffe-eau thermodynamique
            forfait = category_data['forfait'].to_f
            plafond_pourcentage = category_data['plafond_pourcentage'].to_f
            montant = [val * (plafond_pourcentage / 100.0), forfait].min
          elsif prime_slug == 'warmtepomp'
            # Pompe à chaleur
            type_pompe = input_type || 'air_eau'
            forfaits = category_data['forfaits'] || {}
            montant = forfaits[type_pompe].to_f
          else
            montant = category_data['forfait'].to_f
          end

        when 'forfait', 'montant'
          montant = category_data['forfait']&.to_f || category_data['valeur']&.to_f || 0

        when 'prime_conditionnelle'
          montant = 0

        else
          return { error: "Type de prime non pris en charge : #{category_data['type']}" }
        end

        # Appliquer les plafonds de groupe pour catégories 3-4
        montant_final = apply_group_ceiling(prime_slug, montant, user_category)

        {
          calculated_amount: montant_final,
          user_input_value: val,
          category_data: category_data
        }
      end

      # Appliquer les plafonds de groupe (comme dans le JS)
      def apply_group_ceiling(prime_slug, montant_propose, user_category)
        # Catégories 1-2 : pas de plafond
        return montant_propose if ['1', '2'].include?(user_category.to_s)

        # Définir les groupes de plafond
        groupes_plafond = {
          'toiture' => ['isolation_toiture', 'renovation_toiture'],
          'murs' => ['isolation_murs_cat34', 'renovation_murs'],
          'sol' => ['isolation_sol', 'renovation_sol']
        }

        # Plafonds par groupe et catégorie (comme dans le JS)
        plafonds_par_groupe = {
          'toiture' => { '1' => 0, '2' => 0, '3' => 4025, '4' => 5750 },
          'murs' => { '1' => 0, '2' => 0, '3' => 3500, '4' => 5000 },
          'sol' => { '1' => 0, '2' => 0, '3' => 1050, '4' => 1500 }
        }

        # Trouver le groupe de cette prime
        groupe = nil
        groupes_plafond.each do |g, slugs|
          if slugs.include?(prime_slug)
            groupe = g
            break
          end
        end

        return montant_propose unless groupe

        plafond = plafonds_par_groupe[groupe][user_category.to_s] || Float::INFINITY

        # Pour l'instant, on applique juste le plafond simple
        # Dans une implémentation complète, il faudrait tenir compte des autres primes du groupe
        [montant_propose, plafond].min
      end

      def calculate_all_primes(inputs)
        results = {}
        totals_by_group = {}

        inputs.each do |prime_slug, input_data|
          value = input_data['value']
          type = input_data['type'] # Pour les forfaits

          next if value.blank? && type.blank?

          result = calculate_prime(prime_slug, value, type)
          results[prime_slug] = result

          # Grouper par type de travaux pour les totaux
          if result[:amount] && result[:amount] > 0
            work_type = determine_work_type_group_by_slug(prime_slug)
            totals_by_group[work_type] ||= 0
            totals_by_group[work_type] += result[:amount]
          end
        end

        {
          prime_results: results,
          group_totals: totals_by_group,
          total_general: totals_by_group.values.sum
        }
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

          # Récupérer la valeur saisie par l'utilisateur
          user_input_value = @params[:user_inputs]&.[](prime.slug) || 0
          input_type = determine_input_type_for_calculation(prime, user_category)

          # Calculer le montant avec notre nouvelle logique
          calculated_amount = 0
          if user_input_value.present? && user_input_value != 0
            calc_result = calculate_prime(prime.slug, user_input_value, input_type)
            calculated_amount = calc_result[:calculated_amount] || 0
            total += calculated_amount
          end

          prime_data = {
            id: prime.id,
            slug: prime.slug,
            titre: prime.titre,
            unite: prime.unite || "€",
            type: prime.type_de_valeur,
            input_type: determine_input_type(prime),
            placeholder: determine_placeholder(prime, user_category),
            calculated_amount: calculated_amount,
            user_input_value: user_input_value,
            conditions: prime.condition || "Voir conditions sur le site officiel",
            conseil: prime.conseil || "Faites appel à un professionnel certifié",
            category_data: build_category_data(prime, user_category)
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

      def determine_placeholder(prime, user_category = nil)
        # Utiliser le placeholder spécifique à la catégorie si disponible
        if user_category && prime.placeholder.is_a?(Hash)
          placeholder = prime.placeholder[user_category.to_s]
          return placeholder if placeholder.present?
        end

        # Sinon utiliser les placeholders par défaut
        case prime.slug
        when 'isolation_toiture'
          "Surface toiture en m²"
        when 'isolation_sol'
          user_category.in?(['3', '4']) ? "Montant total de la facture" : "Surface plancher en m²"
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

      def build_category_data(prime, user_category = nil)
        # Si une catégorie est fournie, utiliser les données spécifiques
        if user_category && prime.valeurs_par_categorie
          category_data = prime.valeurs_par_categorie[user_category.to_s]
          return category_data.merge(
            condition: prime.condition || "Selon conditions Flandre"
          ) if category_data
        end

        # Sinon, données par défaut
        {
          type: prime.type_de_valeur,
          condition: prime.condition || "Selon conditions Flandre",
          montant: prime.plafond || 0
        }
      end

      def determine_input_type_for_calculation(prime, user_category)
        # Pour certaines primes, le type d'input change selon la catégorie
        case prime.slug
        when 'warmtepomp'
          'air_eau' # Type de pompe par défaut
        else
          'number'
        end
      end

      private

      def determine_user_category
        # Utiliser le FlandreCategoryService dédié pour le calcul de catégorie
        return @category if @category.present?

        category_service = Regions::Flandre::FlandreCategoryService.new({}, user: @user)
        result = category_service.determine_category

        if result[:eligible] && result[:category]
          @category = result[:category].to_s
        else
          @category = "2" # Catégorie par défaut
        end

        @category
      end

      def calculate_dynamic_prime(prime, input_value, user_category)
        value = input_value.to_f
        return { amount: 0, details: 'Valeur invalide' } if value <= 0

        category_data = prime.valeurs_par_categorie[user_category.to_s]
        return { amount: 0, details: 'Catégorie non éligible' } unless category_data

        case category_data['type']
        when 'montant_m2_et_limite'
          calculate_surface_based(category_data, value)
        when 'pourcentage_et_plafond'
          calculate_percentage_based(category_data, value)
        else
          { amount: 0, details: 'Type de calcul non supporté' }
        end
      end

      def calculate_surface_based(data, surface)
        montant_m2 = data['montant_m2'].to_f
        surface_max = data['surface_max'].to_f

        # Limiter la surface au maximum autorisé
        surface_eligible = [surface, surface_max].min
        amount = surface_eligible * montant_m2

        {
          amount: amount,
          details: "#{surface_eligible} m² × #{montant_m2}€/m²",
          surface_used: surface_eligible,
          surface_max: surface_max
        }
      end

      def calculate_percentage_based(data, facture_amount)
        pourcentage = data['pourcentage'].to_f / 100
        plafond = data['plafond'].to_f

        amount_calculated = facture_amount * pourcentage
        amount = [amount_calculated, plafond].min

        {
          amount: amount,
          details: "#{data['pourcentage']}% de #{facture_amount}€ (max #{plafond}€)",
          percentage_applied: data['pourcentage'],
          base_amount: facture_amount,
          capped: amount_calculated > plafond
        }
      end

      def calculate_forfait_prime(prime, forfait_type, user_category)
        return { amount: 0, details: 'Type de forfait requis' } if forfait_type.blank?

        category_data = prime.valeurs_par_categorie[user_category.to_s]
        return { amount: 0, details: 'Catégorie non éligible' } unless category_data

        forfaits = category_data['forfaits']
        return { amount: 0, details: 'Forfaits non disponibles' } unless forfaits

        amount = forfaits[forfait_type].to_f

        {
          amount: amount,
          details: "Forfait #{forfait_type.humanize}",
          forfait_type: forfait_type
        }
      end

      # Calcul pour les primes de type 'surface' (€/m²)
      def calculate_surface_prime(prime, input_value, user_category)
        surface = input_value.to_f
        return { calculated_amount: 0, user_input_value: surface } if surface <= 0

        # Chercher le montant pour la catégorie utilisateur
        montant_data = extract_category_amount(prime, user_category)
        return { calculated_amount: 0, user_input_value: surface } unless montant_data

        case montant_data['type']
        when 'montant_m2_et_limite'
          # Catégories 1-2: montant par m² avec limite de surface
          montant_par_m2 = montant_data['montant_m2'].to_f
          surface_max = montant_data['surface_max']&.to_f || surface
          surface_effective = [surface, surface_max].min
          total = surface_effective * montant_par_m2
        when 'pourcentage_et_plafond'
          # Catégories 3-4: pourcentage du montant facture avec plafond
          # Pour type 'surface', on doit avoir un montant estimé, utilisons 50€/m² par défaut
          montant_estime = surface * 50 # Estimation coût isolation sol
          pourcentage = montant_data['pourcentage'].to_f / 100.0
          plafond = montant_data['plafond'].to_f
          total = [montant_estime * pourcentage, plafond].min
        else
          total = 0
        end

        {
          calculated_amount: total,
          user_input_value: surface,
          category_data: montant_data
        }
      end

      # Calcul pour les primes de type 'facture' (pourcentage du montant)
      def calculate_facture_prime(prime, input_value, user_category)
        montant_facture = input_value.to_f
        return { calculated_amount: 0, user_input_value: montant_facture } if montant_facture <= 0

        # Chercher le montant pour la catégorie utilisateur
        montant_data = extract_category_amount(prime, user_category)
        return { calculated_amount: 0, user_input_value: montant_facture } unless montant_data&.dig('montant')

        pourcentage = montant_data['montant'].to_f / 100.0
        total = montant_facture * pourcentage

        {
          calculated_amount: total,
          user_input_value: montant_facture,
          category_data: montant_data
        }
      end

      # Calcul pour les primes de type 'montant' (montant fixe basé sur input)
      def calculate_montant_prime(prime, input_value, user_category)
        montant_input = input_value.to_f
        return { calculated_amount: 0, user_input_value: montant_input } if montant_input <= 0

        # Chercher le montant pour la catégorie utilisateur
        montant_data = extract_category_amount(prime, user_category)
        return { calculated_amount: 0, user_input_value: montant_input } unless montant_data&.dig('montant')

        pourcentage = montant_data['montant'].to_f / 100.0
        total = montant_input * pourcentage

        {
          calculated_amount: total,
          user_input_value: montant_input,
          category_data: montant_data
        }
      end

      # Calcul pour les primes de type 'montant_facture'
      def calculate_montant_facture_prime(prime, input_value, user_category)
        montant_facture = input_value.to_f
        return { calculated_amount: 0, user_input_value: montant_facture } if montant_facture <= 0

        # Chercher le montant pour la catégorie utilisateur
        montant_data = extract_category_amount(prime, user_category)
        return { calculated_amount: 0, user_input_value: montant_facture } unless montant_data&.dig('montant')

        pourcentage = montant_data['montant'].to_f / 100.0
        total = montant_facture * pourcentage

        {
          calculated_amount: total,
          user_input_value: montant_facture,
          category_data: montant_data
        }
      end

      # Calcul pour les primes de type 'montant_variable_m2_et_limite'
      def calculate_montant_variable_m2_prime(prime, input_value, user_category)
        surface = input_value.to_f
        return { calculated_amount: 0, user_input_value: surface } if surface <= 0

        # Chercher le montant pour la catégorie utilisateur
        montant_data = extract_category_amount(prime, user_category)
        return { calculated_amount: 0, user_input_value: surface } unless montant_data&.dig('montant')

        montant_par_m2 = montant_data['montant'].to_f
        total = surface * montant_par_m2

        # Appliquer une limite si définie
        if montant_data['limite']
          limite = montant_data['limite'].to_f
          total = [total, limite].min
        end

        {
          calculated_amount: total,
          user_input_value: surface,
          category_data: montant_data
        }
      end

      # Méthode helper pour extraire le montant selon la catégorie
      def extract_category_amount(prime, user_category)
        return nil unless prime.valeurs_par_categorie

        # Chercher d'abord pour la catégorie exacte
        category_data = prime.valeurs_par_categorie[user_category.to_s]
        return category_data if category_data

        # Sinon prendre la première disponible
        prime.valeurs_par_categorie.values.first
      end

      def determine_work_type_group_by_slug(prime_slug)
        slug = prime_slug.downcase

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

      def log_calculation(message, data = nil)
        puts "[Regions::Flandre::FlandrePostLoginCalculatorService] #{message}"
        puts "  Data: #{data}" if data
      end
    end
  end
end
