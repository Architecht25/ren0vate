# Éligibilité THÉORIQUE au mécanisme de réduction de prêt bruxellois (printemps 2027, non officialisé).
# Critères calqués sur le régime wallon : bien situé à Bruxelles, habitation, propriétaire,
# résidence principale, bien construit depuis plus de 15 ans, et passoire énergétique
# (label PEB E, F ou G — même critère que la Wallonie).
module Regions
  module Bruxelles
    module PretReduction
      class EligibilityService < Regions::BaseService
        include Regions::Wallonie::CommonEligibilityChecks

        LABELS_ELIGIBLES = Regions::Wallonie::PretReduction::EligibilityService::LABELS_ELIGIBLES

        def check_eligibility
          log_calculation("Début vérification éligibilité Bruxelles (réduction de prêt, théorique)", @params)

          return ineligible_response("Utilisateur non connecté") unless @user

          check_eligibility_post_login
        end

        private

        def check_eligibility_post_login
          property = get_property
          project = user_project

          return ineligible_response("Propriété non trouvée") unless property
          return ineligible_response("Projet non trouvé") unless project

          unless property_in_bruxelles?(property)
            return ineligible_response("Le logement doit être situé en Région de Bruxelles-Capitale")
          end

          unless property_for_habitation?(property)
            return ineligible_response("Le bien doit être destiné à être habité à minimum 50%")
          end

          unless user_is_owner?(property)
            return ineligible_response("Vous devez être propriétaire du logement")
          end

          unless residence_principale?(property)
            return ineligible_response("Le logement doit être occupé comme résidence principale")
          end

          unless property_old_enough?(property)
            return ineligible_response("Le logement doit avoir été construit il y a plus de 15 ans")
          end

          unless Regions::Wallonie::PretReduction::TrancheService.new(@user).eligible_income?
            return ineligible_response("Revenus trop élevés pour ce mécanisme (plafond 122 800€ de revenu ajusté)")
          end

          label_peb = current_label_peb(property)
          unless label_peb.in?(LABELS_ELIGIBLES)
            return ineligible_response(
              "Ce mécanisme est réservé aux passoires énergétiques (label PEB E, F ou G). " \
              "Label actuel : #{label_peb || 'non renseigné'}."
            )
          end

          eligible_response(
            category: nil,
            message: "Éligible au mécanisme théorique de réduction de prêt bruxellois (label PEB #{label_peb})"
          )
        end

        def property_in_bruxelles?(property)
          return true if property.region.to_s.strip.downcase == "bruxelles"

          postal_code = property.code_postal
          return false unless postal_code.present?

          postal_code.to_i.between?(1000, 1299)
        end

        def current_label_peb(property)
          property.peb_donnees.avant_travaux.order(created_at: :desc).first&.label_peb
        end
      end
    end
  end
end
