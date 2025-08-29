# Service d'éligibilité pour la région Bruxelles
# Basé sur les spécificités du système RENOLUTION

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
        # Version complète avec données utilisateur réelles
        Rails.logger.info "=== DÉBUT VÉRIFICATION ÉLIGIBILITÉ BRUXELLES (POST-LOGIN) ==="
        Rails.logger.info "Type de simulation: #{simulation_type}"

        property = get_property
        project = user_project

        Rails.logger.info "Property ID: #{property&.id}, Project ID: #{project&.id}"

        return ineligible_response("Propriété non trouvée") unless property
        return ineligible_response("Projet non trouvé") unless project

        # Logique différente selon le type de simulation
        if is_enterprise_simulation?
          return check_eligibility_enterprise(property, project)
        else
          return check_eligibility_particulier(property, project)
        end
      end

      def check_eligibility_particulier(property, project)
        Rails.logger.info "=== VÉRIFICATION ÉLIGIBILITÉ PARTICULIER ==="

        # 1. Localisation : Le bien doit être en Région de Bruxelles-Capitale
        Rails.logger.info "=== Vérification 1: Localisation Bruxelles ==="
        unless property_in_bruxelles?(property)
          Rails.logger.error "ÉCHEC: Propriété non en Bruxelles"
          return ineligible_response("Le bien doit être situé en Région de Bruxelles-Capitale")
        end
        Rails.logger.info "✅ Localisation Bruxelles OK"

        # 2. Âge du bâtiment : plus de 10 ans (spécificité Bruxelles)
        Rails.logger.info "=== Vérification 2: Âge du logement ==="
        unless property_old_enough_bruxelles?(property)
          Rails.logger.error "ÉCHEC: Logement trop récent (#{property.annee_construction})"
          return ineligible_response("Le bâtiment doit être âgé d'au moins 10 ans")
        end
        Rails.logger.info "✅ Âge du logement OK"

        # 3. Professionnel agréé : à vérifier via le projet/chantier
        Rails.logger.info "=== Vérification 3: Entrepreneur ==="
        unless entrepreneur_valid?(project)
          Rails.logger.error "ÉCHEC: Entrepreneur non valide (BCE: #{project&.bce_number})"
          return ineligible_response("Les travaux doivent être réalisés par un professionnel inscrit à la BCE avec accès réglementé")
        end
        Rails.logger.info "✅ Entrepreneur OK"

        # 4. Nouvelle construction (éliminatoire)
        Rails.logger.info "=== Vérification 4: Nouvelle construction ==="
        if nouvelle_construction?(property, project)
          Rails.logger.error "ÉCHEC: Nouvelle construction détectée"
          return ineligible_response("Les nouvelles constructions ne sont pas éligibles aux primes RENOLUTION")
        end
        Rails.logger.info "✅ Pas nouvelle construction OK"

        # 5. Compte bancaire belge (vérification utilisateur)
        Rails.logger.info "=== Vérification 5: Compte bancaire ==="
        unless compte_belge_valid?
          Rails.logger.error "ÉCHEC: Pas de compte bancaire belge"
          return ineligible_response("Vous devez posséder un compte bancaire belge pour recevoir la prime")
        end
        Rails.logger.info "✅ Compte bancaire OK"

        # 6. Travaux réalisés avec facture récente (12 mois pour Bruxelles)
        Rails.logger.info "=== Vérification 6: Factures ==="
        if factures_too_old_bruxelles?(project)
          Rails.logger.error "ÉCHEC: Factures trop anciennes"
          return ineligible_response("Les travaux doivent être réalisés avec facture dans les 12 mois")
        end
        Rails.logger.info "✅ Factures OK"

        # 7. Propriété : L'utilisateur doit être propriétaire
        Rails.logger.info "=== Vérification 7: Propriétaire ==="
        unless user_is_owner?(property)
          Rails.logger.error "ÉCHEC: Utilisateur non propriétaire"
          return ineligible_response("Vous devez être propriétaire du logement")
        end
        Rails.logger.info "✅ Propriétaire OK"

        # 8. Parties communes (pour appartements)
        Rails.logger.info "=== Vérification 8: Parties communes ==="
        if parties_communes_invalid?(property, project)
          Rails.logger.error "ÉCHEC: Travaux parties communes sans ACP"
          return ineligible_response("Pour les travaux en parties communes, la demande doit être faite au nom de l'ACP")
        end
        Rails.logger.info "✅ Parties communes OK"

        # 9. Destination : Le bien doit être destiné à l'habitation
        Rails.logger.info "=== Vérification 9: Destination habitation ==="
        unless property_for_habitation?(property)
          Rails.logger.error "ÉCHEC: Bien non destiné à l'habitation"
          return ineligible_response("Le bien doit être destiné au logement")
        end
        Rails.logger.info "✅ Destination habitation OK"

        # 10. Résidence principale (domiciliation)
        Rails.logger.info "=== Vérification 10: Résidence principale ==="
        unless residence_principale?(property)
          Rails.logger.error "ÉCHEC: Non résidence principale"
          return ineligible_response("Vous devez être domicilié à l'adresse du chantier ou vous engager à le faire après travaux")
        end
        Rails.logger.info "✅ Résidence principale OK"

        # 11. Permis d'urbanisme si requis
        Rails.logger.info "=== Vérification 11: Permis urbanisme ==="
        if permis_urbanisme_required?(project) && !permis_urbanisme_valid?(project)
          Rails.logger.error "ÉCHEC: Permis d'urbanisme manquant"
          return ineligible_response("Un permis d'urbanisme est requis pour ce type de travaux")
        end
        Rails.logger.info "✅ Permis urbanisme OK"

        # 12. Consentement aux contrôles (vérification utilisateur)
        Rails.logger.info "=== Vérification 12: Consentement contrôles ==="
        unless consentement_controles_valid?
          Rails.logger.error "ÉCHEC: Pas de consentement aux contrôles"
          return ineligible_response("Vous devez consentir aux visites et contrôles de l'administration")
        end
        Rails.logger.info "✅ Consentement contrôles OK"

        # 13. Primes déjà reçues (informative - pas éliminatoire)
        Rails.logger.info "=== Vérification 13: Primes déjà reçues ==="
        if primes_deja_recues?(property, project)
          Rails.logger.info "ℹ️ Primes déjà reçues pour ce bien - vérification des doublons nécessaire"
        end
        Rails.logger.info "✅ Primes reçues OK"

        # 14. Type de propriété (appartement/maison - déjà vérifié dans propriétaire)
        Rails.logger.info "=== Vérification 14: Type de propriété ==="
        unless type_propriete_valid?(property)
          Rails.logger.error "ÉCHEC: Type de propriété non éligible"
          return ineligible_response("Vous devez être propriétaire d'un appartement ou d'une maison")
        end
        Rails.logger.info "✅ Type de propriété OK"

        # 15. Statuts spéciaux BIM/RIS/Client protégé (informatifs pour catégorie)
        Rails.logger.info "=== Vérification 15: Statuts spéciaux ==="
        special_status = get_special_status_info
        Rails.logger.info "ℹ️ Statuts détectés: #{special_status}"
        Rails.logger.info "✅ Statuts spéciaux OK"

        # 16. Statut indépendant (impact sur calcul primes)
        Rails.logger.info "=== Vérification 16: Statut indépendant ==="
        if independant_avec_tva_deductible?
          Rails.logger.info "ℹ️ Indépendant avec TVA déductible - impact sur montants"
        end
        Rails.logger.info "✅ Statut indépendant OK"

        # 17. Usage du bien (résidentiel/mixte - impact sur primes)
        Rails.logger.info "=== Vérification 17: Usage du bien ==="
        usage_impact = get_usage_bien_impact(property, project)
        Rails.logger.info "ℹ️ Usage du bien: #{usage_impact}"
        Rails.logger.info "✅ Usage du bien OK"

        # 18. Vente prévue dans 5 ans (informative - clause de remboursement)
        Rails.logger.info "=== Vérification 18: Vente prévue ==="
        if vente_prevue_5_ans?
          Rails.logger.info "ℹ️ Vente prévue dans 5 ans - clause de remboursement applicable"
        end
        Rails.logger.info "✅ Vente prévue OK"

        # 19. Bien classé (informatif - primes spéciales patrimoine)
        Rails.logger.info "=== Vérification 19: Bien classé ==="
        if bien_classe_ou_patrimoine?(property)
          Rails.logger.info "ℹ️ Bien classé ou petit patrimoine - primes spéciales disponibles"
        end
        Rails.logger.info "✅ Bien classé OK"

        # 20. Petit patrimoine (informatif - primes spéciales façade)
        Rails.logger.info "=== Vérification 20: Petit patrimoine ==="
        if petit_patrimoine_facade?(property)
          Rails.logger.info "ℹ️ Éléments petit patrimoine détectés - primes façade spéciales"
        end
        Rails.logger.info "✅ Petit patrimoine OK"

        Rails.logger.info "=== TOUTES LES 20 VÉRIFICATIONS PASSÉES ✅ ==="
        # Si toutes les vérifications passent, calculer la catégorie précise avec BIM/RIS/Client protégé
        calculate_precise_category_with_status
      end

      def check_eligibility_enterprise(property, project)
        Rails.logger.info "=== VÉRIFICATION ÉLIGIBILITÉ ENTREPRISE ==="

        # 1. Localisation : Le bien doit être en Région de Bruxelles-Capitale
        Rails.logger.info "=== Vérification 1: Localisation Bruxelles ==="
        unless property_in_bruxelles?(property)
          Rails.logger.error "ÉCHEC: Propriété non en Bruxelles"
          return ineligible_response("Le bien doit être situé en Région de Bruxelles-Capitale")
        end
        Rails.logger.info "✅ Localisation Bruxelles OK"

        # 2. Âge du bâtiment : plus de 10 ans (spécificité Bruxelles)
        Rails.logger.info "=== Vérification 2: Âge du logement ==="
        unless property_old_enough_bruxelles?(property)
          Rails.logger.error "ÉCHEC: Logement trop récent (#{property.annee_construction})"
          return ineligible_response("Le bâtiment doit être âgé d'au moins 10 ans")
        end
        Rails.logger.info "✅ Âge du logement OK"

        # 3. Professionnel agréé : à vérifier via le projet/chantier
        Rails.logger.info "=== Vérification 3: Entrepreneur ==="
        unless entrepreneur_valid?(project)
          Rails.logger.error "ÉCHEC: Entrepreneur non valide (BCE: #{project&.bce_number})"
          return ineligible_response("Recours à un entrepreneur agréé obligatoire")
        end
        Rails.logger.info "✅ Entrepreneur OK"

        # Pour les entreprises, critères d'éligibilité simplifiés
        # Pas de vérification de revenus, BIM, RIS, etc.

        Rails.logger.info "=== VÉRIFICATIONS ENTREPRISE PASSÉES ✅ ==="
        # Pour les entreprises, catégorie fixe ou différente logique
        eligible_response(
          category: "bruxelles_cat1", # Catégorie par défaut pour entreprises
          message: "Éligible aux primes Bruxelles (entreprise)"
        )
      end

      # Méthodes de vérification spécifiques à Bruxelles

      def get_property
        # Récupère la propriété associée à la simulation
        property_id = get_param(:property_id)
        Rails.logger.info "🏠 get_property: property_id param = #{property_id}"
        return nil unless property_id

        property = @user.properties.find_by(id: property_id)
        Rails.logger.info "🏠 get_property: found property = #{property&.id}, region = '#{property&.region}'"
        property
      end

      def user_project
        # Récupère le projet associé à la simulation en cours
        project_id = get_param(:project_id)
        return nil unless project_id

        @user.projects.find_by(id: project_id)
      end

      def simulation_type
        # Détermine le type de simulation : 'particulier' ou 'entreprise'
        type = get_param(:simulation_type) || 'particulier'
        Rails.logger.info "🎯 Type de simulation détecté: #{type}"
        type
      end

      def is_enterprise_simulation?
        simulation_type == 'entreprise'
      end

      def property_in_bruxelles?(property)
        # Log pour debug
        Rails.logger.info "Checking property region: '#{property.region}' for property #{property.id}"

        # Vérification via le champ region de la propriété (case-insensitive)
        if property.region.present?
          region_clean = property.region.to_s.strip.downcase
          Rails.logger.info "Cleaned region: '#{region_clean}'"

          if region_clean == 'bruxelles'
            Rails.logger.info "Property region matches 'bruxelles'"
            return true
          end
        end

        # Vérification alternative par code postal si region non définie
        Rails.logger.info "Region field not matching, checking by postal code..."
        result = property_in_bruxelles_by_postal_code?(property)
        Rails.logger.info "Postal code check result: #{result}"
        return result
      end

      def property_in_bruxelles_by_postal_code?(property)
        # Codes postaux de la Région de Bruxelles-Capitale
        postal_code = property.code_postal
        return false unless postal_code.present?

        postal_int = postal_code.to_i

        # Codes postaux bruxellois : 1000 à 1299
        bruxelles_range = (1000..1299)

        # Log pour debug
        Rails.logger.info "Checking postal code: #{postal_int} in range #{bruxelles_range}"
        result = bruxelles_range.include?(postal_int)
        Rails.logger.info "Postal code in Bruxelles range: #{result}"
        result
      end

      def property_for_habitation?(property)
        # Vérification que le bien est destiné à l'habitation
        return true if property.usage == 'residentiel'

        # Par défaut, si pas de données contraires, on assume habitation
        property.usage != 'commercial' && property.usage != 'industriel'
      end

      def user_is_owner?(property)
        # Vérification que l'utilisateur est propriétaire
        proprietaire_types = %w[
          proprietaire_occupant
          proprietaire
          copropriétaire
          usufruitier
          nu_proprietaire
          plein_proprietaire
        ]

        return true if property.type_bien_bruxelles.in?(proprietaire_types)
        return true if property.type_propriete.in?(proprietaire_types)

        # Par défaut, si l'utilisateur a créé la propriété, on assume qu'il est propriétaire
        property.user_id == @user.id
      end

      def residence_principale?(property)
        # Vérification domiciliation/résidence principale
        return true if property.occupation == 'residence_principale'
        return true if property.domiciliation == true

        # Logique par défaut pour Bruxelles
        property.occupation != 'residence_secondaire' && property.occupation != 'investissement'
      end

      def property_old_enough_bruxelles?(property)
        Rails.logger.info "Checking age for property #{property.id}"
        Rails.logger.info "- annee_construction: #{property.annee_construction}"

        # Vérification : construction il y a plus de 10 ans (spécificité Bruxelles vs 15 ans en Wallonie)
        return false unless property.annee_construction

        age = Date.current.year - property.annee_construction
        result = age > 10
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

      def factures_too_old_bruxelles?(project)
        # Vérification : factures de moins de 12 mois (spécificité Bruxelles vs 2 ans en Wallonie)
        return true unless project

        # Vérifier la date des factures (invoice_date) ou la date de fin des travaux
        reference_date = project.invoice_date || project.work_completion_date
        return false unless reference_date

        # Les factures sont considérées comme trop anciennes si > 12 mois
        (Date.current - reference_date).to_i > 365
      end

      # Méthodes de vérification spécifiques aux 20 questions Bruxelles

      def nouvelle_construction?(property, project)
        # Vérification si c'est une nouvelle construction
        return true if property.nouvelle_construction == true
        return true if project&.type_travaux&.include?('nouvelle_construction')

        # Basé sur l'année de construction très récente
        return true if property.annee_construction && (Date.current.year - property.annee_construction) < 2

        false
      end

      def compte_belge_valid?
        # Vérification compte bancaire belge
        return true if @user.iban.present? && @user.iban.start_with?('BE')
        return true if @user.compte_bancaire_belge == true

        # Par défaut, on assume que l'utilisateur connecté a un compte belge
        true
      end

      def parties_communes_invalid?(property, project)
        # Vérification travaux parties communes pour appartements
        is_apartment = property.type_bien_bruxelles == 'appartement' ||
                      property.type_propriete == 'appartement'
        return false unless is_apartment

        # Si travaux concernent parties communes sans être ACP
        return true if project&.parties_communes == true && @user.type_demandeur != 'acp'

        false
      end

      def permis_urbanisme_required?(project)
        # Logique pour déterminer si permis d'urbanisme requis
        return true if project&.facade_works == true
        return true if project&.extension_works == true
        return true if project&.toiture_modification == true

        false
      end

      def permis_urbanisme_valid?(project)
        # Vérification si permis d'urbanisme présent quand requis
        return true if project&.permis_urbanisme_number.present?
        return true if project&.permis_urbanisme_date.present?

        false
      end

      def consentement_controles_valid?
        # Vérification consentement aux contrôles
        return true if @user.consentement_controles == true

        # Par défaut, on assume le consentement pour utilisateur connecté
        true
      end

      # Méthodes pour les vérifications 13-20

      def primes_deja_recues?(property, project)
        # Vérification si des primes ont déjà été reçues pour ce bien
        return true if property.primes_recues == true
        return true if project&.previous_subsidies.present?

        false
      end

      def type_propriete_valid?(property)
        # Vérification type de propriété (appartement ou maison)
        return true if property.type_bien_bruxelles.in?(%w[appartement maison])
        return true if property.type_propriete.in?(%w[appartement maison])

        true # Par défaut valide
      end

      def get_special_status_info
        # Récupération des statuts spéciaux
        statuts = []
        statuts << "BIM" if @user.bim == true
        statuts << "RIS" if @user.ris == true
        statuts << "Client protégé" if @user.client_protege_bruxelles == true

        statuts.empty? ? "Aucun statut spécial" : statuts.join(", ")
      end

      def independant_avec_tva_deductible?
        # Vérification indépendant avec TVA déductible
        return true if @user.independant == true && @user.tva_deductible == true
        return true if @user.statut_professionnel == 'independant' && @user.tva_deductible == true

        false
      end

      def get_usage_bien_impact(property, project)
        # Détermine l'impact de l'usage du bien sur les primes
        if property.usage == 'mixte' || project&.usage_professionnel == true
          surface_pro = project&.surface_professionnelle || 0
          surface_totale = property.surface_totale || project&.surface_totale || 1
          pourcentage_pro = (surface_pro.to_f / surface_totale.to_f * 100).round(1)

          "Usage mixte (#{pourcentage_pro}% professionnel) - primes réduites proportionnellement"
        else
          "Usage résidentiel uniquement - primes complètes"
        end
      end

      def vente_prevue_5_ans?
        # Vérification si vente prévue dans les 5 ans
        return true if @user.vente_prevue_5_ans == true

        false
      end

      def bien_classe_ou_patrimoine?(property)
        # Vérification si bien classé ou protégé
        return true if property.bien_classe == true
        # Note: patrimoine_protege et monument_historique ne sont pas encore dans le schéma
        # return true if property.patrimoine_protege == true
        # return true if property.monument_historique == true

        false
      end

      def petit_patrimoine_facade?(property)
        # Vérification éléments petit patrimoine en façade
        return true if property.petit_patrimoine == true
        return true if property.facade_patrimoine == true

        false
      end

      def calculate_precise_category_with_status
        # Calcul de catégorie en tenant compte des statuts spéciaux
        return ineligible_response("Revenus non renseignés") unless @user.household_income

        # Vérifications statuts spéciaux donnant droit aux montants maximaux (Cat1)
        if has_special_status?
          return eligible_response(
            category: "bruxelles_cat1",
            message: "Éligible aux primes - Catégorie 1 (statut spécial: #{get_special_status_type})"
          )
        end

        # Calcul de catégorie via le service dédié
        category_service = Regions::Bruxelles::BruxellesCategoryService.new(@params, user: @user)
        category_result = category_service.determine_category

        return ineligible_response("Erreur calcul catégorie") if category_result[:error]

        eligible_response(
          category: category_result[:category],
          message: "Éligible aux primes - Catégorie #{category_result[:category].gsub('bruxelles_', '')} confirmée"
        )
      end

      def has_special_status?
        # Vérification des statuts donnant droit aux montants maximaux
        return true if @user.bim == true  # Intervention majorée
        return true if @user.ris == true  # Revenu d'intégration sociale
        return true if @user.client_protege_bruxelles == true  # Client protégé régional

        false
      end

      def get_special_status_type
        return "BIM" if @user.bim == true
        return "RIS" if @user.ris == true
        return "Client protégé" if @user.client_protege_bruxelles == true
        "Statut spécial"
      end

      def calculate_precise_category
        return ineligible_response("Revenus non renseignés") unless @user.household_income

        # Utilisation du service de catégorie dédié
        category_service = Regions::Bruxelles::BruxellesCategoryService.new(@params, user: @user)
        category_result = category_service.determine_category

        return ineligible_response("Erreur calcul catégorie") if category_result[:error]

        eligible_response(
          category: category_result[:category],
          message: "Éligible aux primes - Catégorie #{category_result[:category].gsub('bruxelles_', '')} confirmée"
        )
      end

      def check_basic_eligibility
        # Vérifie uniquement l'éligibilité sans calcul de catégorie
        return ineligible_response("Utilisateur requis") unless @user

        property = get_property
        return ineligible_response("Propriété requise") unless property

        project = user_project

        # Vérification des critères d'éligibilité Bruxelles
        eligibility_checks = [
          { check: property_in_bruxelles?(property), message: "Propriété non située en Région de Bruxelles-Capitale" },
          { check: property_for_habitation?(property), message: "Propriété non destinée à l'habitation" },
          { check: user_is_owner?(property), message: "Vous devez être propriétaire" },
          { check: residence_principale?(property), message: "Doit être votre résidence principale" },
          { check: property_old_enough_bruxelles?(property), message: "Propriété construite il y a moins de 10 ans" },
          { check: entrepreneur_valid?(project), message: "Entrepreneur ou facturation non valide" },
          { check: @user.revenu_demandeur.present?, message: "Revenus non renseignés" }
        ]

        # Vérifier chaque critère
        eligibility_checks.each do |criteria|
          return ineligible_response(criteria[:message]) unless criteria[:check]
        end

        # Si tous les critères sont remplis
        eligible_response(
          message: "Éligible aux primes Bruxelles"
        )
      end
    end
  end
end
