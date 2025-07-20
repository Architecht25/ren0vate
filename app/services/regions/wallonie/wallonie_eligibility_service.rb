# Service d'éligibilité pour la région Wallonie
# Migré et amélioré depuis wallonie_eligibility_service.rb

module Regions
  module Wallonie
    class WallonieEligibilityService < Regions::BaseService
      def check_eligibility
        log_calculation("Début vérification éligibilité Wallonie", @params)

        # Critères d'inéligibilité (réponse "non" = éliminatoire)
        return ineligible_response("Le logement doit être situé en Wallonie") if get_param(:localisation) == "non"
        return ineligible_response("Le bien doit être destiné à être habité à minimum 50%") if get_param(:destination) == "non"
        return ineligible_response("Vous devez être propriétaire du logement") if get_param(:propriete) == "non"
        return ineligible_response("Le logement doit être occupé comme résidence principale") if get_param(:residence_principale) == "non"
        return ineligible_response("Le logement doit avoir plus de 15 ans") if get_param(:age_logement) == "non"
        return ineligible_response("Un audit énergétique est requis") if get_param(:audit) == "non"
        return ineligible_response("L'entrepreneur doit être inscrit à la BCE") if get_param(:entrepreneur) == "non"
        return ineligible_response("Les factures doivent dater de moins de 2 ans") if get_param(:factures_anciennes) == "oui"

        # Logique adaptée selon pré-login vs post-login
        if @is_post_login
          check_eligibility_post_login
        else
          check_eligibility_pre_login
        end
      end

      private

      def check_eligibility_pre_login
        # Version simplifiée pour utilisateurs non connectés
        if get_param(:revenus) == "non"
          # Revenus <= 114 400€ → Besoin d'affinage R1-R4
          eligible_response(
            category: "R1-R4",
            message: "Éligible aux primes - Catégorie à affiner après connexion",
            needs_refinement: true
          )
        else
          # Revenus > 114 400€ → Catégorie R5 directe
          eligible_response(
            category: "R5",
            message: "Éligible aux primes - Catégorie R5"
          )
        end
      end

      def check_eligibility_post_login
        # Version complète avec données utilisateur
        property = user_property

        # Vérifications supplémentaires avec données réelles
        return ineligible_response("Propriété non trouvée") unless property
        return ineligible_response("Type de propriété non éligible") unless property_eligible?(property)

        # Calcul précis de la catégorie avec revenus réels
        calculate_precise_category
      end

      def property_eligible?(property)
        # Logique de vérification de la propriété
        # À adapter selon votre modèle Property
        return false unless property
        return false if property.construction_year && (Date.current.year - property.construction_year) < 15

        true
      end

      def calculate_precise_category
        # Utiliser les vraies données de revenus de l'utilisateur
        return ineligible_response("Revenus non renseignés") unless @user.household_income

        category = determine_income_category(@user.household_income)

        eligible_response(
          category: category,
          message: "Éligible aux primes - Catégorie #{category} confirmée"
        )
      end

      def determine_income_category(income)
        # Barèmes Wallonie 2024 (à ajuster selon vos données)
        return "R1" if income <= 23_000
        return "R2" if income <= 35_000
        return "R3" if income <= 50_000
        return "R4" if income <= 79_000
        return "R5"
      end
    end
  end
end
