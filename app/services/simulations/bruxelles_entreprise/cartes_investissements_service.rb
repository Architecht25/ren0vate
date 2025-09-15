module Simulations
  module BruxellesEntreprise
    class CartesInvestissementsService
      attr_reader :simulation, :user_inputs

      def initialize(simulation, user_inputs = {})
        @simulation = simulation
        @user_inputs = user_inputs
        Rails.logger.info "🎯 Service cartes investissements Bruxelles initialisé"
      end

      def calculate_all_primes
        Rails.logger.info "💰 Calcul de toutes les primes des cartes d'investissements"

        results = {
          primes_details: [],
          totaux_par_categorie: {},
          total_general: 0,
          parametres_entreprise: get_entreprise_parameters
        }

        # Récupérer toutes les aides Bruxelles entreprises
        aides = EntrepriseAide.where(region: "bruxelles")

        # Calculer les primes pour chaque aide avec un montant saisi
        aides.each do |aide|
          montant_investi = get_montant_for_aide(aide.slug)
          next if montant_investi <= 0

          prime_result = calculate_prime_for_aide(aide, montant_investi)
          next if prime_result[:montant_prime] <= 0

          # Ajouter aux résultats
          results[:primes_details] << prime_result

          # Additionner par catégorie
          categorie = aide.categorie
          results[:totaux_par_categorie][categorie] ||= 0
          results[:totaux_par_categorie][categorie] += prime_result[:montant_prime]

          # Total général
          results[:total_general] += prime_result[:montant_prime]
        end

        Rails.logger.info "✅ #{results[:primes_details].size} primes calculées - Total: #{results[:total_general]}€"
        results
      end

      def calculate_prime_for_aide(aide, montant_investi)
        # Récupérer les paramètres de l'entreprise
        taille_entreprise = get_taille_entreprise
        age_entreprise = get_age_entreprise

        # Vérifier l'éligibilité
        unless eligible_for_aide?(aide, taille_entreprise)
          return { montant_prime: 0, ineligible: true, raison: "Taille d'entreprise non éligible" }
        end

        # Calculer le taux avec majorations
        taux_base = aide.taux_aide || 25.0
        taux_final = calculate_taux_with_majorations(taux_base, taille_entreprise, age_entreprise, aide)

        # Calculer le montant de la prime
        montant_prime_brut = montant_investi * (taux_final / 100.0)

        # Appliquer les plafonds seulement si ils existent
        if aide.montant_max.present?
          montant_prime_final = [montant_prime_brut, aide.montant_max].min
        else
          montant_prime_final = montant_prime_brut # Pas de plafond
        end

        # Vérifier le montant minimum requis
        montant_min_requis = aide.montant_investissement_min_requis || 0
        if montant_investi < montant_min_requis
          return {
            montant_prime: 0,
            ineligible: true,
            raison: "Montant minimum requis: #{montant_min_requis}€"
          }
        end

        {
          aide_id: aide.id,
          slug: aide.slug,
          titre: aide.titre,
          categorie: aide.categorie,
          montant_investi: montant_investi,
          montant_prime: montant_prime_final.round,
          taux_base: taux_base,
          taux_final: taux_final,
          montant_max: aide.montant_max, # Vrai plafond ou nil
          majorations_appliquees: get_majorations_details(taux_base, taux_final, taille_entreprise, age_entreprise, aide),
          eligible: true
        }
      end

      def calculate_taux_with_majorations(taux_base, taille_entreprise, age_entreprise, aide)
        taux_final = taux_base

        # Majorations selon la taille d'entreprise
        case taille_entreprise
        when 'tpe'
          taux_final += 15 # +15% pour TPE
        when 'pme'
          taux_final += 10 # +10% pour PME
        when 'moyenne'
          taux_final += 5  # +5% pour moyennes entreprises
        end

        # Majoration pour jeunes entreprises
        if age_entreprise == 'moins_3_ans'
          taux_final += 10 # +10% pour entreprises < 3 ans
        end

        # Majorations spécifiques par catégorie
        case aide.categorie
        when 'transition_energetique'
          taux_final += 5 # +5% bonus transition énergétique
        when 'digitalisation'
          taux_final += 3 # +3% bonus digitalisation
        end

        # Plafonner à 70%
        [taux_final, 70.0].min
      end

      def eligible_for_aide?(aide, taille_entreprise)
        # Si pas de restriction de taille, éligible par défaut
        return true unless aide.tailles_eligibles&.any?

        # Vérifier si la taille de l'entreprise est dans la liste des tailles éligibles
        aide.tailles_eligibles.include?(taille_entreprise)
      end

      def get_majorations_details(taux_base, taux_final, taille_entreprise, age_entreprise, aide)
        majorations = []

        # Majoration taille entreprise
        majoration_taille = case taille_entreprise
                           when 'tpe' then 15
                           when 'pme' then 10
                           when 'moyenne' then 5
                           else 0
                           end

        if majoration_taille > 0
          majorations << {
            type: "taille_entreprise",
            nom: "Taille entreprise (#{taille_entreprise.upcase})",
            taux: majoration_taille,
            description: "Majoration selon la taille de l'entreprise"
          }
        end

        # Majoration âge entreprise
        if age_entreprise == 'moins_3_ans'
          majorations << {
            type: "jeune_entreprise",
            nom: "Jeune entreprise",
            taux: 10,
            description: "Entreprise créée depuis moins de 3 ans"
          }
        end

        # Majorations catégorielles
        case aide.categorie
        when 'transition_energetique'
          majorations << {
            type: "transition_energetique",
            nom: "Transition énergétique",
            taux: 5,
            description: "Bonus pour les investissements en transition énergétique"
          }
        when 'digitalisation'
          majorations << {
            type: "digitalisation",
            nom: "Digitalisation",
            taux: 3,
            description: "Bonus pour les investissements en digitalisation"
          }
        end

        majorations
      end

      def get_total_by_category
        results = calculate_all_primes
        results[:totaux_par_categorie]
      end

      def get_simulation_summary
        results = calculate_all_primes

        {
          entreprise: results[:parametres_entreprise],
          total_general: results[:total_general],
          nb_aides: results[:primes_details].size,
          categories: results[:totaux_par_categorie].map do |categorie, total|
            {
              nom: categorie.humanize,
              total: total,
              nb_aides: results[:primes_details].count { |p| p[:categorie] == categorie }
            }
          end
        }
      end

      private

      def get_montant_for_aide(aide_slug)
        # Récupérer le montant saisi par l'utilisateur pour cette aide
        @user_inputs[aide_slug]&.to_f || 0
      end

      def get_taille_entreprise
        @user_inputs['entreprise_taille'] || 'pme'
      end

      def get_age_entreprise
        @user_inputs['entreprise_age'] || 'plus_3_ans'
      end

      def get_entreprise_parameters
        {
          taille: get_taille_entreprise,
          age: get_age_entreprise,
          commune: @simulation&.property&.commune,
          region: 'bruxelles'
        }
      end
    end
  end
end
