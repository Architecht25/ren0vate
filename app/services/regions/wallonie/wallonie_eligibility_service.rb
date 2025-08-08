# Service d'éligibilité pour la région Wallonie
# Migré et amélioré depuis wallonie_eligibility_service.rb

module Regions
  module Wallonie
    class WallonieEligibilityService < Regions::BaseService
      def check_eligibility
        log_calculation("Début vérification éligibilité Wallonie", @params)

        # Version post-login avec données réelles
        return ineligible_response("Utilisates eur non connecté") unless @user
        return check_eligibility_post_login
      end

      private

      def check_eligibility_post_login
        # Récupération des données réelles
        property = user_property
        project = user_project

        return ineligible_response("Propriété non trouvée") unless property
        return ineligible_response("Projet non trouvé") unless project

        # Vérifications d'éligibilité basées sur les données réelles

        # 1. Localisation : Le bien doit être en Wallonie
        return ineligible_response("Le logement doit être situé en Wallonie (hors Communauté germanophone)") unless property_in_wallonie?(property)

        # 2. Destination : Le bien doit être destiné à l'habitation
        return ineligible_response("Le bien doit être destiné à être habité à minimum 50%") unless property_for_habitation?(property)

        # 3. Propriété : L'utilisateur doit être propriétaire
        return ineligible_response("Vous devez être propriétaire du logement (plein propriétaire, nu-propriétaire, usufruitier ou co-propriétaire)") unless user_is_owner?(property)

        # 4. Résidence principale : vérification via les champs du bien
        return ineligible_response("Le logement doit être occupé comme résidence principale dans les 24 mois suivant l'introduction de la demande") unless residence_principale?(property)

        # 5. Âge du logement : plus de 15 ans
        return ineligible_response("Le logement doit avoir été construit il y a plus de 15 ans") unless property_old_enough?(property)

        # 6. Entrepreneur : à vérifier via le projet/chantier
        return ineligible_response("L'entrepreneur doit être inscrit à la Banque Carrefour des Entreprises avec les codes NACE appropriés") unless entrepreneur_valid?(project)

        # 7. Factures anciennes : vérification via le projet
        return ineligible_response("Les factures doivent dater de moins de 2 ans") if factures_too_old?(project)

        # Si toutes les vérifications passent, calculer la catégorie
        calculate_precise_category
      end

      def property_eligible?(property)
        # Méthode conservée pour compatibilité
        property_in_wallonie?(property) && property_for_habitation?(property) && property_old_enough?(property)
      end

      # Nouvelles méthodes de vérification basées sur les données réelles

      def user_project
        # Récupère le projet associé à la simulation en cours
        project_id = get_param(:project_id)
        return nil unless project_id

        @user.projects.find_by(id: project_id)
      end

      def property_in_wallonie?(property)
        # Vérification via le champ region de la propriété
        property.region&.downcase == 'wallonie'
      end

      def property_for_habitation?(property)
        # Pour Wallonie, vérifier type_propriete_wallonie ou occupation
        # Si pas de données spécifiques, on assume que c'est pour l'habitation
        return true if property.type_propriete_wallonie.present?
        return true if property.occupation == 'residence_principale'

        # Logique par défaut : si c'est un logement, on assume habitation >= 50%
        property.type&.include?('logement') || property.type&.include?('maison') || property.type&.include?('appartement')
      end

      def user_is_owner?(property)
        # Vérification via type_propriete_wallonie ou type_propriete
        proprietaire_types = %w[
          proprietaire_occupant
          proprietaire
          copropriétaire
          usufruitier
          nu_proprietaire
          plein_proprietaire
        ]

        return true if property.type_propriete_wallonie.in?(proprietaire_types)
        return true if property.type_propriete.in?(proprietaire_types)

        # Par défaut, si l'utilisateur a créé la propriété, on assume qu'il est propriétaire
        property.user_id == @user.id
      end

      def residence_principale?(property)
        # Vérification via le champ occupation ou type
        return true if property.occupation == 'residence_principale'

        # Logique par défaut pour Wallonie
        # Si pas de données contraires, on assume résidence principale
        property.occupation != 'residence_secondaire' && property.occupation != 'investissement'
      end

      def property_old_enough?(property)
        # Vérification : construction il y a plus de 15 ans
        return false unless property.annee_construction

        (Date.current.year - property.annee_construction) > 15
      end

      def entrepreneur_valid?(project)
        # Pour l'instant, on assume que c'est valide
        # TODO: À implémenter selon les données disponibles dans le projet
        # Pourrait vérifier un champ entrepreneur_bce ou similar
        true
      end

      def factures_too_old?(project)
        # Vérification : factures de moins de 2 ans
        # Pour l'instant, on assume que c'est bon
        # TODO: À implémenter selon les données de factures dans le projet
        false
      end

      def calculate_precise_category
        # Utiliser les vraies données de revenus de l'utilisateur
        return ineligible_response("Revenus non renseignés") unless @user.household_income

        # Prise en compte des déductions (enfants, personnes âgées)
        adjusted_income = calculate_adjusted_income(@user.household_income)
        category = determine_income_category(adjusted_income)

        # Récupération des données du projet pour les conditions spéciales
        project = user_project

        # Conditions spéciales basées sur les données réelles du projet
        toiture_only = projet_toiture_seulement?(project)
        audit_prevu = projet_avec_audit?(project)

        if toiture_only
          eligible_response(
            category: category,
            message: "Éligible aux primes toiture - Catégorie #{category} confirmée",
            special_conditions: {
              travaux_toiture: true,
              audit_recommande: !audit_prevu
            }
          )
        else
          eligible_response(
            category: category,
            message: "Éligible aux primes - Catégorie #{category} confirmée",
            special_conditions: {
              audit_recommande: !audit_prevu
            }
          )
        end
      end

      def projet_toiture_seulement?(project)
        # TODO: À implémenter selon la structure des travaux dans le projet
        # Exemple : project.works.all? { |work| work.category == 'toiture' }
        false # Par défaut
      end

      def projet_avec_audit?(project)
        # Vérifier si un audit est prévu/présent
        return true if project&.property&.audit_energetique

        # TODO: Autres vérifications selon les données disponibles
        false
      end

      def calculate_adjusted_income(base_income)
        # Déduction de 5.000€ par enfant à charge, grossesse en cours ou personne > 60 ans
        # Cette logique dépend de votre modèle User
        deductions = 0

        if @user.respond_to?(:children_count) && @user.children_count
          deductions += @user.children_count * 5000
        end

        if @user.respond_to?(:elderly_count) && @user.elderly_count
          deductions += @user.elderly_count * 5000
        end

        [base_income - deductions, 0].max
      end

      def determine_income_category(adjusted_income)
        # Barèmes Wallonie 2025 (revenus imposables après déductions)
        return "R1" if adjusted_income <= 25_400
        return "R2" if adjusted_income <= 36_200
        return "R3" if adjusted_income <= 51_800
        return "R4" if adjusted_income <= 79_000
        return "R5" if adjusted_income <= 114_400
        "R6" # Au-delà de 114.400€
      end
    end
  end
end
