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
        Rails.logger.info "🔍 Calcul prime: slug=#{prime_slug}, value=#{input_value}, type=#{input_type}"

        prime = Prime.find_by(slug: prime_slug, region: 'flandre')
        unless prime
          Rails.logger.warn "❌ Prime non trouvée: slug=#{prime_slug}, region=flandre"
          return { error: 'Prime non trouvée' }
        end
        Rails.logger.info "✅ Prime trouvée: #{prime.titre}"

        user_category = @category || determine_user_category
        Rails.logger.info "🏷️ Catégorie utilisateur: #{user_category}"

        category_data = prime.valeurs_par_categorie&.[](user_category.to_s)
        unless category_data
          Rails.logger.warn "❌ Catégorie #{user_category} non éligible pour #{prime_slug}"
          return { error: "Catégorie #{user_category} non éligible pour #{prime_slug}" }
        end
        Rails.logger.info "📊 Données catégorie: #{category_data.inspect}"

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

        # Note: les plafonds de groupe (catégories 3-4) sont appliqués globalement
        # dans calculate_all_primes via apply_group_ceilings_to_all, pas ici.

        {
          calculated_amount: montant,
          user_input_value: val,
          category_data: category_data
        }
      end

      def calculate_all_primes(inputs)
        Rails.logger.info "🏴󐁧󐁢󐁳󐁣󐁴󐁿 Calcul de toutes les primes Flandre avec: #{inputs.inspect}"

        results = {}
        totals_by_group = {}
        total_general = 0.0

        # Calculer les primes PEB si données présentes
        if inputs['peb'].present?
          Rails.logger.info "🏠 Calcul prime PEB"
          peb_result = calculate_peb_prime(inputs['peb'])
          if peb_result[:success]
            results['peb'] = {
              amount: peb_result[:montant],
              details: peb_result[:details],
              type: 'peb'
            }
            totals_by_group['peb'] = peb_result[:montant]
            total_general += peb_result[:montant]
            Rails.logger.info "✅ PEB calculé: #{peb_result[:montant]}€"
          else
            Rails.logger.warn "⚠️ Échec calcul PEB: #{peb_result[:error]}"
          end
        end

        # Calculer les primes Amiante si données présentes
        if inputs['amiante'].present?
          Rails.logger.info "☣️ Calcul prime Amiante"
          amiante_result = calculate_amiante_prime(inputs['amiante'])
          if amiante_result[:success]
            results['amiante'] = {
              amount: amiante_result[:montant],
              details: amiante_result[:details],
              type: 'amiante'
            }
            totals_by_group['amiante'] = amiante_result[:montant]
            total_general += amiante_result[:montant]
            Rails.logger.info "✅ Amiante calculé: #{amiante_result[:montant]}€"
          else
            Rails.logger.warn "⚠️ Échec calcul Amiante: #{amiante_result[:error]}"
          end
        end

        # ÉTAPE 1: Calculer toutes les primes normales (sans plafond de groupe)
        primes_montants = {}
        if inputs['primes'].present?
          Rails.logger.info "🔧 Calcul primes normales"
          inputs['primes'].each do |prime_slug, input_data|
            value = input_data['value']
            type = input_data['type'] # Pour les forfaits

            next if value.blank? && type.blank?

            result = calculate_prime(prime_slug, value, type)
            results[prime_slug] = result

            # Stocker le montant calculé pour application des plafonds de groupe
            if result[:calculated_amount] && result[:calculated_amount] > 0
              primes_montants[prime_slug] = result[:calculated_amount]
            end
          end
        end

        # ÉTAPE 2: Appliquer les plafonds de groupe (catégories 3 et 4 uniquement)
        user_category = @category || determine_user_category
        montants_finaux = apply_group_ceilings_to_all(primes_montants, user_category)

        # ÉTAPE 3: Mettre à jour les résultats avec les montants après plafonnement
        montants_finaux.each do |prime_slug, montant_final|
          if results[prime_slug]
            montant_original = results[prime_slug][:calculated_amount]
            results[prime_slug][:calculated_amount] = montant_final

            if montant_final != montant_original
              results[prime_slug][:ceiling_applied] = true
              results[prime_slug][:original_amount] = montant_original
              Rails.logger.info "⚖️ Plafond appliqué à #{prime_slug}: #{montant_original.round(2)}€ → #{montant_final.round(2)}€"
            end
          end
        end

        # ÉTAPE 4: Recalculer les totaux avec les montants plafonnés
        total_general = totals_by_group['peb'].to_f + totals_by_group['amiante'].to_f
        totals_by_group = { 'peb' => totals_by_group['peb'].to_f, 'amiante' => totals_by_group['amiante'].to_f }

        montants_finaux.each do |prime_slug, montant_final|
          work_type = determine_work_type_group_by_slug(prime_slug)
          totals_by_group[work_type] ||= 0.0
          totals_by_group[work_type] += montant_final
          total_general += montant_final
        end

        Rails.logger.info "💰 Total général Flandre après plafonds: #{total_general.round(2)}€"

        {
          prime_results: results,
          group_totals: totals_by_group,
          total_general: total_general
        }
      end

      # Nouvelle méthode: Appliquer les plafonds de groupe à toutes les primes
      def apply_group_ceilings_to_all(primes_montants, user_category)
        # Pas de plafonds pour les catégories 1 et 2
        if ['1', '2'].include?(user_category.to_s)
          Rails.logger.info "ℹ️ Catégorie #{user_category}: pas de plafonds de groupe"
          return primes_montants
        end

        Rails.logger.info "🔧 Application des plafonds de groupe pour catégorie #{user_category}"

        # Définir les groupes de plafond
        groupes_plafond = {
          'toiture' => ['isolation_toiture', 'renovation_toiture'],
          'murs' => ['isolation_murs', 'renovation_murs'],
          'sol' => ['isolation_sol', 'renovation_sol']
        }

        # Plafonds par groupe et catégorie
        plafonds_par_groupe = {
          'toiture' => { '1' => 0, '2' => 0, '3' => 4025, '4' => 5750 },
          'murs' => { '1' => 0, '2' => 0, '3' => 3500, '4' => 5000 },
          'sol' => { '1' => 0, '2' => 0, '3' => 1050, '4' => 1500 }
        }

        montants_finaux = primes_montants.dup

        # Appliquer les plafonds par groupe
        groupes_plafond.each do |groupe, slugs|
          plafond = plafonds_par_groupe[groupe][user_category.to_s] || Float::INFINITY

          # Calculer le total du groupe AVANT plafonnement
          total_groupe = slugs.sum { |slug| primes_montants[slug].to_f }

          if total_groupe > plafond && plafond > 0
            # Réduire proportionnellement tous les montants du groupe
            facteur = plafond / total_groupe
            Rails.logger.info "⚖️ Groupe '#{groupe}': total #{total_groupe.round(2)}€ > plafond #{plafond.round(2)}€"
            Rails.logger.info "   → Facteur de réduction: #{(facteur * 100).round(2)}%"

            slugs.each do |slug|
              if primes_montants[slug].to_f > 0
                montant_original = primes_montants[slug]
                montants_finaux[slug] = montant_original * facteur
                Rails.logger.info "   → #{slug}: #{montant_original.round(2)}€ → #{montants_finaux[slug].round(2)}€"
              end
            end
          elsif total_groupe > 0
            Rails.logger.info "✅ Groupe '#{groupe}': total #{total_groupe.round(2)}€ ≤ plafond #{plafond.round(2)}€ - pas de réduction"
          end
        end

        montants_finaux
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
        when 'isolation_murs'
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

      def determine_user_category
        # Utiliser le FlandreCategoryService dédié pour le calcul de catégorie
        return @category if @category.present?

        # Passer les paramètres nécessaires au service de catégorie
        category_params = {
          property_id: @params[:property_id],
          project_id: @params[:project_id]
        }
        category_service = Regions::Flandre::FlandreCategoryService.new(category_params, user: @user)
        result = category_service.determine_category

        if result[:eligible] && result[:category]
          @category = result[:category].to_s
        else
          @category = "2" # Catégorie par défaut
        end

        @category
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

      # Prime PEB/EPC-label supprimée définitivement (clôturée) — voir subsidy_bot_service.rb
      def calculate_peb_prime(peb_data)
        {
          success: false,
          error: "Prime PEB/EPC-label supprimée — plus de nouvelles demandes possibles",
          montant: 0.0
        }
      end

      # Calcul spécifique pour la prime Amiante Flandre
      def calculate_amiante_prime(amiante_data)
        Rails.logger.info "☣️ Calcul prime Amiante avec: #{amiante_data.inspect}"

        surface_toiture = amiante_data['surface_toiture'].to_f
        surface_murs = amiante_data['surface_murs'].to_f

        if surface_toiture <= 0 && surface_murs <= 0
          Rails.logger.warn "⚠️ Aucune surface spécifiée pour l'amiante"
          return {
            success: false,
            error: "Aucune surface spécifiée",
            montant: 0.0
          }
        end

        # Logique de calcul amiante Flandre
        # - 8€/m² pour la toiture
        # - 4€/m² pour les murs si pas de toiture
        # - 12€/m² pour les murs si toiture incluse

        montant_total = 0.0

        if surface_toiture > 0
          montant_total += surface_toiture * 8.0 # 8€/m² toiture

          if surface_murs > 0
            montant_total += surface_murs * 12.0 # 12€/m² murs si toiture incluse
          end
        elsif surface_murs > 0
          montant_total += surface_murs * 4.0 # 4€/m² murs uniquement
        end

        Rails.logger.info "✅ Prime Amiante calculée: #{montant_total}€ (toiture: #{surface_toiture}m², murs: #{surface_murs}m²)"

        {
          success: true,
          montant: montant_total,
          details: {
            surface_toiture: surface_toiture,
            surface_murs: surface_murs,
            tarif_toiture: 8.0,
            tarif_murs: surface_toiture > 0 ? 12.0 : 4.0
          },
          type: 'amiante'
        }
      end
    end
  end
end
