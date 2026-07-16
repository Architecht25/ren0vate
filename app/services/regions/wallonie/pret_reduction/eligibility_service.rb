# Service d'éligibilité pour le nouveau régime wallon (Rénopack/Rénoprêt, dès le 01/10/2026).
# Réutilise les critères communs (région, habitation, propriétaire, résidence principale,
# âge du logement) partagés avec l'ancien régime primes cash, et ajoute le critère PEB
# bloquant propre à cette réforme.
module Regions
  module Wallonie
    module PretReduction
      class EligibilityService < Regions::BaseService
        include Regions::Wallonie::CommonEligibilityChecks

        # ⚠️ Le texte source (articles L'Echo) ne mentionne que E/F/D comme labels éligibles —
        # G n'est pas cité, probablement un oubli du texte réglementaire plutôt qu'une exclusion
        # volontaire. À valider avec le fondateur/le texte définitif avant mise en production.
        LABELS_ELIGIBLES = %w[D E F].freeze

        def check_eligibility
          log_calculation("Début vérification éligibilité Wallonie (régime réduction de prêt)", @params)

          return ineligible_response("Utilisateur non connecté") unless @user
          check_eligibility_post_login
        end

        private

        def check_eligibility_post_login
          property = get_property
          project = user_project

          return ineligible_response("Propriété non trouvée") unless property
          return ineligible_response("Projet non trouvé") unless project

          unless property_in_wallonie?(property)
            return ineligible_response("Le logement doit être situé en Wallonie (hors Communauté germanophone)")
          end

          unless property_for_habitation?(property)
            return ineligible_response("Le bien doit être destiné à être habité à minimum 50%")
          end

          unless user_is_owner?(property)
            return ineligible_response("Vous devez être propriétaire du logement (plein propriétaire, nu-propriétaire, usufruitier ou co-propriétaire)")
          end

          unless residence_principale?(property)
            return ineligible_response("Le logement doit être occupé comme résidence principale dans les 24 mois suivant l'introduction de la demande")
          end

          unless property_old_enough?(property)
            return ineligible_response("Le logement doit avoir été construit il y a plus de 15 ans")
          end

          label_peb = current_label_peb(property)
          unless label_peb.in?(LABELS_ELIGIBLES)
            return ineligible_response(
              "Ce régime est réservé aux logements avec un label PEB E ou F (viser au minimum D), " \
              "ou D (viser au minimum C). Label actuel : #{label_peb || 'non renseigné'}."
            )
          end

          eligible_response(
            category: nil,
            message: "Éligible au nouveau régime wallon de réduction de prêt (label PEB #{label_peb})"
          )
        end

        def current_label_peb(property)
          property.peb_donnees.avant_travaux.order(created_at: :desc).first&.label_peb
        end
      end
    end
  end
end
