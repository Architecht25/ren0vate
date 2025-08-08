# Service d'éligibilité pour la région Wallonie
# Migré et amélioré depuis wallonie_eligibility_service.rb

module Regions
  module Wallonie
    class WallonieEligibilityService < Regions::BaseService
      def check_eligibility
        log_calculation("Début vérification éligibilité Wallonie", @params)

        # Version post-login avec données réelles
        return ineligible_response("Utilisateseur non connecté") unless @user
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

        # Si toutes les vérifications passent, retourner éligible
        eligible_response(category: nil, message: "Éligible aux primes Wallonie")
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
        # Vérification prioritaire : pourcentage d'habitation >= 50%
        if property.habitation_percentage.present?
          return property.habitation_percentage >= 50
        end

        # Pour Wallonie, vérifier type_propriete_wallonie ou occupation
        if property.type_propriete_wallonie.present?
          habitation_types = %w[
            logement_unifamilial
            appartement
            maison
            residence_principale
            habitation
          ]
          return property.type_propriete_wallonie.in?(habitation_types)
        end

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
        # Vérification : numéro BCE présent et valide
        return false unless project&.bce_number.present?

        # Validation basique du format BCE (10 chiffres)
        project.bce_number.match?(/\A\d{10}\z/)
      end

      def factures_too_old?(project)
        # Vérification : factures de moins de 2 ans
        return true unless project

        # Vérifier la date des factures (invoice_date) ou la date de fin des travaux
        reference_date = project.invoice_date || project.work_completion_date
        return false unless reference_date

        # Les factures sont considérées comme trop anciennes si > 2 ans
        (Date.current - reference_date).to_i > (2 * 365)
      end

      def check_basic_eligibility
        # Vérifie uniquement l'éligibilité sans calcul de catégorie
        return ineligible_response("Utilisateur requis") unless @user

        property = get_property
        return ineligible_response("Propriété requise") unless property

        project = user_project

        # Vérification des 7 critères d'éligibilité
        eligibility_checks = [
          { check: property_in_wallonie?(property), message: "Propriété non située en Wallonie" },
          { check: property_for_habitation?(property), message: "Propriété non destinée à l'habitation" },
          { check: user_is_owner?(property), message: "Vous devez être propriétaire" },
          { check: residence_principale?(property), message: "Doit être votre résidence principale" },
          { check: property_old_enough?(property), message: "Propriété construite il y a moins de 15 ans" },
          { check: entrepreneur_valid?(project), message: "Entrepreneur ou facturation non valide" },
          { check: @user.revenu_demandeur.present?, message: "Revenus non renseignés" }
        ]

        # Vérifier chaque critère
        eligibility_checks.each do |criteria|
          return ineligible_response(criteria[:message]) unless criteria[:check]
        end

        # Si tous les critères sont remplis
        eligible_response(
          message: "Éligible aux primes Wallonie"
        )
      end

      private

      def get_property
        # Récupère la propriété associée à la simulation
        property_id = get_param(:property_id)
        return nil unless property_id

        @user.properties.find_by(id: property_id)
      end
    end
  end
end
