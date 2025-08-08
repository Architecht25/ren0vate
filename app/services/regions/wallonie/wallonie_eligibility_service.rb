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

        Rails.logger.info "=== DÉBUT VÉRIFICATION ÉLIGIBILITÉ WALLONIE ==="
        Rails.logger.info "Property ID: #{property&.id}, Project ID: #{project&.id}"

        return ineligible_response("Propriété non trouvée") unless property
        return ineligible_response("Projet non trouvé") unless project

        # Vérifications d'éligibilité basées sur les données réelles

        # 1. Localisation : Le bien doit être en Wallonie
        Rails.logger.info "=== Vérification 1: Localisation Wallonie ==="
        unless property_in_wallonie?(property)
          Rails.logger.error "ÉCHEC: Propriété non en Wallonie"
          return ineligible_response("Le logement doit être situé en Wallonie (hors Communauté germanophone)")
        end
        Rails.logger.info "✅ Localisation Wallonie OK"

        # 2. Destination : Le bien doit être destiné à l'habitation
        Rails.logger.info "=== Vérification 2: Destination habitation ==="
        unless property_for_habitation?(property)
          Rails.logger.error "ÉCHEC: Bien non destiné à l'habitation"
          return ineligible_response("Le bien doit être destiné à être habité à minimum 50%")
        end
        Rails.logger.info "✅ Destination habitation OK"

        # 3. Propriété : L'utilisateur doit être propriétaire
        Rails.logger.info "=== Vérification 3: Propriétaire ==="
        unless user_is_owner?(property)
          Rails.logger.error "ÉCHEC: Utilisateur non propriétaire"
          return ineligible_response("Vous devez être propriétaire du logement (plein propriétaire, nu-propriétaire, usufruitier ou co-propriétaire)")
        end
        Rails.logger.info "✅ Propriétaire OK"

        # 4. Résidence principale : vérification via les champs du bien
        Rails.logger.info "=== Vérification 4: Résidence principale ==="
        unless residence_principale?(property)
          Rails.logger.error "ÉCHEC: Non résidence principale"
          return ineligible_response("Le logement doit être occupé comme résidence principale dans les 24 mois suivant l'introduction de la demande")
        end
        Rails.logger.info "✅ Résidence principale OK"

        # 5. Âge du logement : plus de 15 ans
        Rails.logger.info "=== Vérification 5: Âge du logement ==="
        unless property_old_enough?(property)
          Rails.logger.error "ÉCHEC: Logement trop récent (#{property.annee_construction})"
          return ineligible_response("Le logement doit avoir été construit il y a plus de 15 ans")
        end
        Rails.logger.info "✅ Âge du logement OK"

        # 6. Entrepreneur : à vérifier via le projet/chantier
        Rails.logger.info "=== Vérification 6: Entrepreneur ==="
        unless entrepreneur_valid?(project)
          Rails.logger.error "ÉCHEC: Entrepreneur non valide (BCE: #{project&.bce_number})"
          return ineligible_response("L'entrepreneur doit être inscrit à la Banque Carrefour des Entreprises avec les codes NACE appropriés")
        end
        Rails.logger.info "✅ Entrepreneur OK"

        # 7. Factures anciennes : vérification via le projet
        Rails.logger.info "=== Vérification 7: Factures ==="
        if factures_too_old?(project)
          Rails.logger.error "ÉCHEC: Factures trop anciennes"
          return ineligible_response("Les factures doivent dater de moins de 2 ans")
        end
        Rails.logger.info "✅ Factures OK"

        Rails.logger.info "=== TOUTES LES VÉRIFICATIONS PASSÉES ✅ ==="
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
        # Log pour debug
        Rails.logger.info "Checking property region: '#{property.region}' for property #{property.id}"

        # Vérification via le champ region de la propriété
        if property.region.present? && property.region.downcase == 'wallonie'
          Rails.logger.info "Property region matches 'wallonie'"
          return true
        end

        # Vérification alternative par l'adresse si region non définie ou différente
        Rails.logger.info "Region field not matching, checking by postal code..."
        if property.region.blank? || property.region.downcase != 'wallonie'
          result = property_in_wallonie_by_address?(property)
          Rails.logger.info "Postal code check result: #{result}"
          return result
        end

        Rails.logger.info "Property not in Wallonie"
        false
      end

      def property_in_wallonie_by_address?(property)
        # Code postal belge pour Wallonie
        # Codes postaux wallons selon les provinces
        postal_code = property.code_postal || property.cp
        return false unless postal_code.present?

        postal_int = postal_code.to_i

        # Définition complète des codes postaux wallons
        wallonie_ranges = [
          (1300..1499),  # Brabant wallon (La Hulpe = 1310 ici !)
          (4000..4999),  # Province de Liège
          (5000..5999),  # Province de Namur
          (6000..6999),  # Hainaut (Charleroi region)
          (7000..7999),  # Hainaut (Mons region)
          (6700..6799),  # Partie du Luxembourg belge
          (6800..6999)   # Suite Luxembourg belge
        ]

        # Log pour debug
        Rails.logger.info "Checking postal code #{postal_int} for Wallonie eligibility"

        in_wallonie = wallonie_ranges.any? { |range| range.include?(postal_int) }
        Rails.logger.info "Postal code #{postal_int} in Wallonie: #{in_wallonie}"

        in_wallonie
      end

      def property_for_habitation?(property)
        Rails.logger.info "Checking habitation for property #{property.id}"
        Rails.logger.info "- habitation_percentage: #{property.habitation_percentage}"
        Rails.logger.info "- type_propriete_wallonie: #{property.type_propriete_wallonie}"
        Rails.logger.info "- occupation: #{property.occupation}"
        Rails.logger.info "- type: #{property.type}"

        # Vérification prioritaire : pourcentage d'habitation >= 50%
        if property.habitation_percentage.present?
          result = property.habitation_percentage >= 50
          Rails.logger.info "Result from habitation_percentage: #{result}"
          return result
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
          result = property.type_propriete_wallonie.in?(habitation_types)
          Rails.logger.info "Result from type_propriete_wallonie: #{result}"
          return result
        end

        if property.occupation == 'residence_principale'
          Rails.logger.info "Result from occupation residence_principale: true"
          return true
        end

        # Logique par défaut : si c'est un logement, on assume habitation >= 50%
        result = property.type&.include?('logement') || property.type&.include?('maison') || property.type&.include?('appartement')
        Rails.logger.info "Result from type check: #{result}"
        result
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
        Rails.logger.info "Checking age for property #{property.id}"
        Rails.logger.info "- annee_construction: #{property.annee_construction}"

        # Vérification : construction il y a plus de 15 ans
        return false unless property.annee_construction

        age = Date.current.year - property.annee_construction
        result = age > 15
        Rails.logger.info "- Property age: #{age} years, result: #{result}"
        result
      end

      def entrepreneur_valid?(project)
        Rails.logger.info "Checking entrepreneur for project #{project&.id}"
        Rails.logger.info "- bce_number: #{project&.bce_number}"

        # Vérification : numéro BCE présent et valide
        return false unless project&.bce_number.present?

        # Validation basique du format BCE (10 chiffres)
        result = project.bce_number.match?(/\A\d{10}\z/)
        Rails.logger.info "- BCE format valid: #{result}"
        result
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
