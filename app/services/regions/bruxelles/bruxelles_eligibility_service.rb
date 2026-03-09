# Service d'éligibilité pour la région Bruxelles-Capitale
# Version simplifiée : pas de critères d'éligibilité stricts

module Regions
  module Bruxelles
    class BruxellesEligibilityService < Regions::BaseService
      def check_eligibility
        log_calculation("Début vérification éligibilité Bruxelles", @params)

        # Version post-login avec données réelles
        return ineligible_response("Utilisateur non connecté") unless @user
        return check_eligibility_post_login
      end

      private

      def check_eligibility_post_login
        # Récupération des données réelles
        property = get_property
        project = user_project

        Rails.logger.info "=== VÉRIFICATION ÉLIGIBILITÉ BRUXELLES (SIMPLIFIÉE) ==="
        Rails.logger.info "Property ID: #{property&.id}, Project ID: #{project&.id}"

        return ineligible_response("Propriété non trouvée") unless property
        return ineligible_response("Projet non trouvé") unless project

        # Vérification simple : le bien doit être à Bruxelles
        unless property_in_bruxelles?(property)
          Rails.logger.error "ÉCHEC: Propriété non à Bruxelles"
          return ineligible_response("Le logement doit être situé en Région de Bruxelles-Capitale")
        end

        Rails.logger.info "✅ Propriété à Bruxelles - Éligible"
        # Toute propriété à Bruxelles est éligible
        eligible_response(category: nil, message: "Éligible aux primes Bruxelles")
      end

      def get_property
        property_id = get_param(:property_id)
        return nil unless property_id

        @user.properties.find_by(id: property_id)
      end

      def user_project
        project_id = get_param(:project_id)
        return nil unless project_id

        @user.projects.find_by(id: project_id)
      end

      def property_in_bruxelles?(property)
        # Vérification via le champ region de la propriété
        if property.region.present?
          region_clean = property.region.to_s.strip.downcase
          return true if region_clean == 'bruxelles'
        end

        # Vérification alternative par code postal (1000-1299)
        postal_code = property.code_postal
        return false unless postal_code.present?

        postal_int = postal_code.to_i
        postal_int >= 1000 && postal_int <= 1299
      end

      def log_calculation(message, data = nil)
        Rails.logger.info "[BruxellesEligibilityService] #{message}"
        Rails.logger.info "[BruxellesEligibilityService] Data: #{data.inspect}" if data
      end
    end
  end
end
