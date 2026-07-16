# Service d'éligibilité pour la région Wallonie (régime primes cash historique,
# valide jusqu'au 30/09/2026 — voir Regions::Wallonie::PretReduction pour le nouveau régime)

module Regions
  module Wallonie
    class WallonieEligibilityService < Regions::BaseService
      include Regions::Wallonie::CommonEligibilityChecks

      def check_eligibility
        log_calculation("Début vérification éligibilité Wallonie", @params)

        # Version post-login avec données réelles
        return ineligible_response("Utilisateseur non connecté") unless @user
        return check_eligibility_post_login
      end

      private

      def check_eligibility_post_login
        # Récupération des données réelles
        property = get_property
        project = user_project

        Rails.logger.info "=== DÉBUT VÉRIFICATION ÉLIGIBILITÉ WALLONIE ==="
        Rails.logger.info "Property ID: #{property&.id}, Project ID: #{project&.id}"
        Rails.logger.info "Params: property_id=#{get_param(:property_id)}, project_id=#{get_param(:project_id)}"

        return ineligible_response("Propriété non trouvée") unless property
        return ineligible_response("Projet non trouvé") unless project

        # 1. Localisation : Le bien doit être en Wallonie
        unless property_in_wallonie?(property)
          Rails.logger.error "ÉCHEC: Propriété non en Wallonie"
          return ineligible_response("Le logement doit être situé en Wallonie (hors Communauté germanophone)")
        end

        # 2. Destination : Le bien doit être destiné à l'habitation
        unless property_for_habitation?(property)
          Rails.logger.error "ÉCHEC: Bien non destiné à l'habitation"
          return ineligible_response("Le bien doit être destiné à être habité à minimum 50%")
        end

        # 3. Propriété : L'utilisateur doit être propriétaire
        unless user_is_owner?(property)
          Rails.logger.error "ÉCHEC: Utilisateur non propriétaire"
          return ineligible_response("Vous devez être propriétaire du logement (plein propriétaire, nu-propriétaire, usufruitier ou co-propriétaire)")
        end

        # 4. Résidence principale
        unless residence_principale?(property)
          Rails.logger.error "ÉCHEC: Non résidence principale"
          return ineligible_response("Le logement doit être occupé comme résidence principale dans les 24 mois suivant l'introduction de la demande")
        end

        # 5. Âge du logement : plus de 15 ans
        unless property_old_enough?(property)
          Rails.logger.error "ÉCHEC: Logement trop récent (#{property.annee_construction})"
          return ineligible_response("Le logement doit avoir été construit il y a plus de 15 ans")
        end

        # 6. Entrepreneur et 7. factures anciennes : désactivés (voir entrepreneur_valid?/factures_too_old? ci-dessous)

        Rails.logger.info "=== TOUTES LES VÉRIFICATIONS PASSÉES ✅ ==="
        eligible_response(category: nil, message: "Éligible aux primes Wallonie")
      end

      def property_eligible?(property)
        # Méthode conservée pour compatibilité
        property_in_wallonie?(property) && property_for_habitation?(property) && property_old_enough?(property)
      end

      def entrepreneur_valid?(project)
        return false unless project&.bce_number.present?

        project.bce_number.match?(/\A\d{10}\z/)
      end

      def factures_too_old?(project)
        return true unless project

        reference_date = project.invoice_date || project.work_completion_date
        return false unless reference_date

        (Date.current - reference_date).to_i > (2 * 365)
      end

      def check_basic_eligibility
        return ineligible_response("Utilisateur requis") unless @user

        property = get_property
        return ineligible_response("Propriété requise") unless property

        eligibility_checks = [
          { check: property_in_wallonie?(property), message: "Propriété non située en Wallonie" },
          { check: property_for_habitation?(property), message: "Propriété non destinée à l'habitation" },
          { check: user_is_owner?(property), message: "Vous devez être propriétaire" },
          { check: residence_principale?(property), message: "Doit être votre résidence principale" },
          { check: property_old_enough?(property), message: "Propriété construite il y a moins de 15 ans" },
          { check: @user.revenu_demandeur.present?, message: "Revenus non renseignés" }
        ]

        eligibility_checks.each do |criteria|
          return ineligible_response(criteria[:message]) unless criteria[:check]
        end

        eligible_response(message: "Éligible aux primes Wallonie")
      end
    end
  end
end
