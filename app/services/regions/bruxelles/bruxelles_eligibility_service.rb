# Service d'éligibilité pour la région Bruxelles
# Basé sur les spécificités du système RENOLUTION

module Regions
  module Bruxelles
    class BruxellesEligibilityService < Regions::BaseService
      def check_eligibility
        log_calculation("Début vérification éligibilité Bruxelles", @params)

        # Critères d'inéligibilité spécifiques à Bruxelles
        return ineligible_response("Le logement doit être situé en Région de Bruxelles-Capitale") if get_param(:localisation) == "non"
        return ineligible_response("Le bien doit être destiné au logement") if get_param(:destination) == "non"
        return ineligible_response("Vous devez être propriétaire du logement") if get_param(:propriete) == "non"
        return ineligible_response("Le logement doit être votre résidence principale") if get_param(:residence_principale) == "non"
        return ineligible_response("Le logement doit avoir plus de 10 ans") if get_param(:age_logement) == "non"
        return ineligible_response("Les travaux doivent être réalisés par un entrepreneur agréé") if get_param(:entrepreneur) == "non"
        return ineligible_response("Les factures doivent dater de moins de 4 ans") if get_param(:factures_anciennes) == "oui"

        # Vérifications spécifiques Bruxelles
        return ineligible_response("Une demande de permis d'urbanisme peut être requise") if urbanisme_required? && get_param(:autorisation_urbanisme) == "non"

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
        # Bruxelles a 3 catégories basées sur les revenus

        # Estimation rapide basée sur les revenus déclarés
        if get_param(:revenus_bas) == "oui"
          eligible_response(
            category: "bruxelles_cat1",
            message: "Éligible aux primes - Catégorie 1 (revenus les plus bas)",
            needs_refinement: false
          )
        elsif get_param(:revenus_moyens) == "oui"
          eligible_response(
            category: "bruxelles_cat2",
            message: "Éligible aux primes - Catégorie 2 (revenus moyens)",
            needs_refinement: false
          )
        elsif get_param(:revenus_eleves) == "oui"
          eligible_response(
            category: "bruxelles_cat3",
            message: "Éligible aux primes - Catégorie 3 (revenus élevés)",
            needs_refinement: false
          )
        else
          # Pas de revenu précisé, nécessite affinage
          eligible_response(
            category: "bruxelles_cat1-cat3",
            message: "Éligible aux primes - Catégorie à préciser après connexion",
            needs_refinement: true
          )
        end
      end

      def check_eligibility_post_login
        # Version complète avec données utilisateur
        property = user_property

        return ineligible_response("Propriété non trouvée") unless property
        return ineligible_response("Type de propriété non éligible") unless property_eligible?(property)

        # Calcul précis de la catégorie avec revenus réels
        calculate_precise_category
      end

      def property_eligible?(property)
        return false unless property

        # Vérification âge du logement (10 ans minimum à Bruxelles)
        if property.construction_year && (Date.current.year - property.construction_year) < 10
          return false
        end

        # Vérification type de bien (résidentiel uniquement)
        return false unless %w[house apartment].include?(property.property_type)

        true
      end

      def calculate_precise_category
        return ineligible_response("Revenus non renseignés") unless @user.household_income

        category = determine_income_category_bruxelles(@user.household_income)

        eligible_response(
          category: category,
          message: "Éligible aux primes - Catégorie #{category.gsub('bruxelles_', '')} confirmée"
        )
      end

      def determine_income_category_bruxelles(income)
        # Barèmes Bruxelles RENOLUTION 2024
        # (À ajuster selon les vrais seuils)

        family_size = get_family_size

        # Seuils indicatifs par taille de ménage
        thresholds = calculate_brussels_thresholds(family_size)

        return "bruxelles_cat1" if income <= thresholds[:cat1]
        return "bruxelles_cat2" if income <= thresholds[:cat2]
        "bruxelles_cat3"
      end

      def get_family_size
        # Calculer la taille du ménage
        base_size = @user.marital_status&.in?(%w[married cohabiting]) ? 2 : 1
        children = @user.children_count || 0
        elderly = @user.elderly_dependents || 0

        base_size + children + elderly
      end

      def calculate_brussels_thresholds(family_size)
        # Seuils Bruxelles selon taille ménage (exemples)
        base_cat1 = 25_000
        base_cat2 = 45_000

        # Majoration par personne supplémentaire
        additional_per_person = 5_000
        bonus = (family_size - 1) * additional_per_person

        {
          cat1: base_cat1 + bonus,
          cat2: base_cat2 + bonus
        }
      end

      def urbanisme_required?
        # Logique pour déterminer si autorisation d'urbanisme requise
        # Basé sur le type de travaux
        facade_works = get_param(:travaux_facade) == "oui"
        toiture_works = get_param(:travaux_toiture) == "oui"
        extension_works = get_param(:extension) == "oui"

        facade_works || extension_works
      end
    end
  end
end
