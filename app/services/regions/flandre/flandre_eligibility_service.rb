# Service d'éligibilité pour la région Flandre
# Adaptation du pattern Wallonie avec les spécificités flamandes

module Regions
  module Flandre
    class FlandreEligibilityService < Regions::BaseService
      def check_eligibility
        log_calculation("Début vérification éligibilité Flandre", @params)

        # Version post-login avec données réelles
        return ineligible_response("Utilisateur non connecté") unless @user
        return check_eligibility_post_login
      end

      private

      def check_eligibility_post_login
        # Récupération des données réelles
        property = get_property
        project = user_project

        Rails.logger.info "=== DÉBUT VÉRIFICATION ÉLIGIBILITÉ FLANDRE ==="
        Rails.logger.info "Property ID: #{property&.id}, Project ID: #{project&.id}"
        Rails.logger.info "Params: property_id=#{get_param(:property_id)}, project_id=#{get_param(:project_id)}"

        return ineligible_response("Propriété non trouvée") unless property
        return ineligible_response("Projet non trouvé") unless project

        # Vérifications d'éligibilité basées sur le questionnaire Flandre

        # 1. "usage" => "Le bien est-il destiné à être habité ?"
        Rails.logger.info "=== Vérification 1: Usage habitation ==="
        unless bien_destine_habitation?(property)
          Rails.logger.error "ÉCHEC: Bien non destiné à l'habitation"
          return ineligible_response("Le bien doit être destiné à être habité")
        end
        Rails.logger.info "✅ Usage habitation OK"

        # 2. "propriétaire" => "Êtes-vous propriétaire du bien (min 1%)?"
        Rails.logger.info "=== Vérification 2: Propriétaire minimum 1% ==="
        unless proprietaire_minimum_1_pourcent?(property)
          Rails.logger.error "ÉCHEC: Utilisateur non propriétaire ou < 1%"
          return ineligible_response("Vous devez être propriétaire du bien (minimum 1%)")
        end
        Rails.logger.info "✅ Propriétaire minimum 1% OK"

        # 3. "annee" => "Le bien rénové a-t-il été construit avant le 1er janvier 2006 ?"
        Rails.logger.info "=== Vérification 3: Construction avant 2006 ==="
        unless construit_avant_2006?(property)
          Rails.logger.error "ÉCHEC: Bien construit après 2006 (#{property.annee_construction})"
          return ineligible_response("Le bien doit avoir été construit avant le 1er janvier 2006")
        end
        Rails.logger.info "✅ Construction avant 2006 OK"

        # 4. "appartement-copro" => Gestion par syndic requise si oui
        Rails.logger.info "=== Vérification 4: Appartement copropriété ==="
        if appartement_soumis_copropriete?(property)
          Rails.logger.error "ÉCHEC: Appartement en copropriété"
          return ineligible_response("La demande de primes doit être gérée et introduite par votre syndic de copropriété")
        end
        Rails.logger.info "✅ Pas d'appartement en copropriété OK"

        # 5. "demolition" => Reconstruction après démolition non éligible
        Rails.logger.info "=== Vérification 5: Pas de reconstruction ==="
        if reconstruction_apres_demolition?(project)
          Rails.logger.error "ÉCHEC: Reconstruction après démolition"
          return ineligible_response("Les logements reconstruits et qui bénéficient d'une TVA à 6% ne sont pas éligibles")
        end
        Rails.logger.info "✅ Pas de reconstruction OK"

        # 6. "facture_solde" => "La facture de solde des travaux date-t-elle de plus de 2 ans ?"
        # Commenté car pas pertinent pour l'éligibilité dans une simulation
        # Rails.logger.info "=== Vérification 6: Factures récentes ==="
        # if factures_trop_anciennes?(project)
        #   Rails.logger.error "ÉCHEC: Factures trop anciennes"
        #   return ineligible_response("La facture de solde de vos travaux doit dater de moins de 2 ans pour que les travaux soient éligibles aux primes")
        # end
        # Rails.logger.info "✅ Factures récentes OK"

        # 7. "travaux" => "Prévoyez-vous des travaux d'isolation ou de chauffage ?"
        Rails.logger.info "=== Vérification 7: Travaux éligibles ==="
        unless travaux_isolation_chauffage?(project)
          Rails.logger.error "ÉCHEC: Pas de travaux éligibles prévus"
          return ineligible_response("Vous devez prévoir des travaux éligibles pour bénéficier des primes actuelles")
        end
        Rails.logger.info "✅ Travaux éligibles OK"

        # 8. "autre_bien" => "Possédez-vous un autre bien/appartement/terrain, autre que le bien rénové?"
        # Note: En Flandre, posséder un autre bien peut affecter l'éligibilité ou la catégorie
        Rails.logger.info "=== Vérification 8: Autre bien ==="
        if possede_autre_bien?
          Rails.logger.info "INFO: Utilisateur possède un autre bien (impact sur catégorie)"
          # En Flandre, cela peut ne pas être éliminatoire mais affecter la catégorie
        end
        Rails.logger.info "✅ Autre bien vérifié"

        # 9. "appartement" => "Le bien rénové est-il un appartement non soumis à copropriété (vma)?"
        Rails.logger.info "=== Vérification 9: Appartement non copropriété ==="
        if appartement_non_copropriete?(property)
          Rails.logger.info "INFO: Appartement non soumis à copropriété (impact sur catégorie)"
          # Impact sur la catégorie mais pas éliminatoire
        end
        Rails.logger.info "✅ Type appartement vérifié"

        # 10. "immeuble-appartements" => "Le bien rénové est-il un immeuble à appartements destinés au logement?"
        Rails.logger.info "=== Vérification 10: Immeuble à appartements ==="
        if immeuble_a_appartements?(property)
          Rails.logger.info "INFO: Immeuble à appartements (impact sur catégorie)"
          # Impact sur la catégorie mais pas éliminatoire
        end
        Rails.logger.info "✅ Type immeuble vérifié"

        # 11. "type" => "Le bien rénové est-il une maison?"
        Rails.logger.info "=== Vérification 11: Type de bien (maison) ==="
        if est_une_maison?(property)
          Rails.logger.info "INFO: Le bien est une maison"
        else
          Rails.logger.info "INFO: Le bien n'est pas une maison (appartement, etc.)"
        end
        Rails.logger.info "✅ Type de bien vérifié"

        # 12. "peb" => "Le certificat PEB avant travaux de rénovation indique-t-il un label E, F?"
        Rails.logger.info "=== Vérification 12: Certificat PEB ==="
        if certificat_peb_e_f?(property)
          Rails.logger.info "INFO: Certificat PEB indique label E ou F (bonus possible)"
        else
          Rails.logger.info "INFO: Pas de certificat PEB E/F (pas de bonus spécifique)"
        end
        Rails.logger.info "✅ Certificat PEB vérifié"

        # 13. "protege" => "Êtes-vous un client protégé..."
        Rails.logger.info "=== Vérification 13: Client protégé ==="
        if est_client_protege?
          Rails.logger.info "INFO: Utilisateur est client protégé (catégorie 4 automatique)"
        else
          Rails.logger.info "INFO: Utilisateur n'est pas client protégé (catégorie selon revenus)"
        end
        Rails.logger.info "✅ Statut client protégé vérifié"

        # 14. "domicile" => "Êtes-vous ou serez-vous domicilié une fois le bien rénové?"
        # Si non domicilié => catégorie 1 automatiquement (pas d'inéligibilité)
        Rails.logger.info "=== Vérification 14: Domiciliation ==="
        if sera_domicilie?(property)
          Rails.logger.info "✅ Utilisateur domicilié (catégorie selon revenus)"
        else
          Rails.logger.info "INFO: Non domicilié => catégorie 1 automatique"
          # Pas de return ineligible_response, juste noter pour la catégorisation
        end
        Rails.logger.info "✅ Domiciliation vérifiée"

        # 15. Vérification de localisation en Flandre
        Rails.logger.info "=== Vérification 15: Localisation Flandre ==="
        unless property_in_flandre?(property)
          Rails.logger.error "ÉCHEC: Propriété non en Flandre"
          return ineligible_response("Le logement doit être situé en Région flamande")
        end
        Rails.logger.info "✅ Localisation Flandre OK"

        # Note: Les questions suivantes affectent la catégorie mais pas l'éligibilité de base :
        # - "peb" => Certificat PEB (bonus/malus)
        # - "protege" => Client protégé (catégorie automatique 4)
        # - "type" => Maison (information)
        # - "domicile" => Non domicilié (catégorie automatique 1)

        Rails.logger.info "=== TOUTES LES VÉRIFICATIONS FLANDRE PASSÉES ✅ ==="
        # Si toutes les vérifications passent, retourner éligible
        eligible_response(category: nil, message: "Éligible aux primes Flandre")
      end

      def user_project
        # Récupère le projet associé à la simulation en cours
        project_id = get_param(:project_id)
        return nil unless project_id

        @user.projects.find_by(id: project_id)
      end

      def property_in_flandre?(property)
        # Log pour debug
        Rails.logger.info "Checking property region: '#{property.region}' (raw) for property #{property.id}"
        Rails.logger.info "Property region class: #{property.region.class}"

        # Vérification via le champ region de la propriété (case-insensitive)
        if property.region.present?
          region_clean = property.region.to_s.strip.downcase
          Rails.logger.info "Cleaned region: '#{region_clean}'"

          if region_clean == 'flandre'
            Rails.logger.info "Property region matches 'flandre' (after cleaning)"
            return true
          end
        end

        # Vérification alternative par l'adresse si region non définie
        Rails.logger.info "Region field not matching, checking by postal code..."
        result = property_in_flandre_by_address?(property)
        Rails.logger.info "Postal code check result: #{result}"
        return result
      end

      def property_in_flandre_by_address?(property)
        # Codes postaux flamands
        postal_code = property.code_postal || property.cp
        return false unless postal_code.present?

        postal_int = postal_code.to_i

        # Définition des codes postaux flamands
        flandre_ranges = [
          (1500..1999),  # Brabant flamand (Halle-Vilvoorde)
          (2000..2999),  # Province d'Anvers
          (3000..3999),  # Brabant flamand et Limbourg
          (8000..8999),  # Flandre occidentale
          (9000..9999)   # Flandre orientale
        ]

        # Log pour debug
        Rails.logger.info "Checking postal code #{postal_int} for Flandre eligibility"

        in_flandre = flandre_ranges.any? { |range| range.include?(postal_int) }
        Rails.logger.info "Postal code #{postal_int} in Flandre: #{in_flandre}"

        in_flandre
      end

      # Nouvelles méthodes basées sur le questionnaire Flandre

      def bien_destine_habitation?(property)
        Rails.logger.info "Checking bien destiné habitation for property #{property.id}"
        Rails.logger.info "- habitation_percentage: #{property.habitation_percentage}"
        Rails.logger.info "- type_propriete_flandre: #{property.type_propriete_flandre}"
        Rails.logger.info "- occupation: #{property.occupation}"
        Rails.logger.info "- type: #{property.type}"

        # Question: "Le bien est-il destiné à être habité ?"
        # Vérifier si le bien a une fonction d'habitation
        if property.habitation_percentage.present?
          result = property.habitation_percentage > 0
          Rails.logger.info "Result from habitation_percentage > 0: #{result}"
          return result
        end

        # Vérifier via les types flamands
        if property.type_propriete_flandre.present?
          habitation_types = %w[
            woning
            appartement
            eengezinswoning
            hoofdverblijfplaats
            woonfunctie
            logement
            maison
          ]
          result = property.type_propriete_flandre.in?(habitation_types)
          Rails.logger.info "Result from type_propriete_flandre habitation: #{result}"
          return result
        end

        # Logique par défaut : si c'est un type résidentiel
        result = property.type&.include?('logement') ||
                property.type&.include?('woning') ||
                property.type&.include?('appartement') ||
                property.type&.include?('maison')
        Rails.logger.info "Result from type check habitation: #{result}"
        result
      end

      def proprietaire_minimum_1_pourcent?(property)
        Rails.logger.info "Checking propriétaire minimum 1% for property #{property.id}"

        # Question: "Êtes-vous propriétaire du bien (min 1%)?"
        # Vérifier si l'utilisateur est propriétaire avec au moins 1%

        # Si pourcentage de propriété défini explicitement
        if property.respond_to?(:pourcentage_propriete) && property.pourcentage_propriete.present?
          result = property.pourcentage_propriete >= 1
          Rails.logger.info "Result from pourcentage_propriete >= 1%: #{result}"
          return result
        end

        # Vérifier via type de propriétaire
        proprietaire_types = %w[
          eigenaar_bewoner
          eigenaar
          mede_eigenaar
          vruchtgebruiker
          naakte_eigenaar
          volle_eigenaar
          proprietaire_occupant
          proprietaire
          copropriétaire
          usufruitier
          nu_proprietaire
          plein_proprietaire
        ]

        result = property.type_propriete_flandre.in?(proprietaire_types) ||
                property.type_propriete.in?(proprietaire_types) ||
                property.user_id == @user.id

        Rails.logger.info "Result from propriétaire types: #{result}"
        result
      end

      def construit_avant_2006?(property)
        Rails.logger.info "Checking construction avant 2006 for property #{property.id}"
        Rails.logger.info "- annee_construction: #{property.annee_construction}"

        # Question: "Le bien rénové a-t-il été construit avant le 1er janvier 2006 ?"
        return false unless property.annee_construction

        result = property.annee_construction < 2006
        Rails.logger.info "- Construction avant 2006: #{result}"
        result
      end

      def appartement_soumis_copropriete?(property)
        Rails.logger.info "Checking appartement copropriété for property #{property.id}"

        # Question: "Le bien rénové est-il un appartement soumis à copropriété (vma)?"
        # Si oui → inéligible car géré par syndic

        copro_types = %w[
          appartement_copro
          vma_appartement
          copropriete
          appartement_vma
        ]

        result = property.type_propriete_flandre.in?(copro_types) ||
                property.type.in?(copro_types) ||
                (property.respond_to?(:copropriete) && property.copropriete == true)

        Rails.logger.info "Result appartement copropriété: #{result}"
        result
      end

      def reconstruction_apres_demolition?(project)
        Rails.logger.info "Checking reconstruction après démolition for project #{project&.id}"

        # Question: "Le bien rénové est-il une reconstruction complète après démolition,
        # ouvrant droit au taux réduit de TVA à 6 % ?"
        return false unless project

        # Vérifier via champs spécifiques
        result = project.respond_to?(:reconstruction_demolition) && project.reconstruction_demolition == true ||
                project.respond_to?(:tva_reduit_6_pourcent) && project.tva_reduit_6_pourcent == true ||
                project.type_travaux&.include?('reconstruction') ||
                project.type_travaux&.include?('demolition')

        Rails.logger.info "Result reconstruction démolition: #{result}"
        result
      end

      def factures_trop_anciennes?(project)
        Rails.logger.info "Checking factures anciennes for project #{project&.id}"

        # Question: "La facture de solde des travaux de rénovation date-t-elle de plus de 2 ans ?"
        return false unless project

        # Vérifier la date des factures (invoice_date) ou la date de fin des travaux
        reference_date = project.invoice_date || project.work_completion_date
        return false unless reference_date

        # Les factures sont trop anciennes si > 2 ans
        result = (Date.current - reference_date).to_i > (2 * 365)
        Rails.logger.info "Facture date: #{reference_date}, trop ancienne: #{result}"
        result
      end

      def travaux_isolation_chauffage?(project)
        Rails.logger.info "Checking travaux isolation/chauffage for project #{project&.id}"

        # Question: "Prévoyez-vous des travaux d'isolation ou de chauffage ?"
        return false unless project

        # Vérifier via type de travaux
        travaux_eligibles = %w[
          isolation
          chauffage
          isolation_toiture
          isolation_murs
          isolation_sol
          pompe_chaleur
          chaudiere
          ventilation
          fenetres
        ]

        result = project.type_travaux.present? &&
                travaux_eligibles.any? { |type| project.type_travaux.include?(type) }

        # Si pas de type spécifique, accepter par défaut (sera vérifié plus tard)
        result = true if project.type_travaux.blank?

        Rails.logger.info "Result travaux éligibles: #{result}"
        result
      end

      def possede_autre_bien?
        Rails.logger.info "Checking autre bien for user #{@user.id}"

        # Question: "Possédez-vous un autre bien/appartement/terrain, autre que le bien rénové?"
        # Vérifier via champ utilisateur spécifique
        if @user.respond_to?(:autre_bien_flandre)
          result = @user.autre_bien_flandre == true
          Rails.logger.info "Result from autre_bien_flandre: #{result}"
          return result
        end

        # Vérifier via le nombre de propriétés
        if @user.properties.count > 1
          Rails.logger.info "Result from multiple properties: true"
          return true
        end

        Rails.logger.info "Result autre bien: false (default)"
        false
      end

      def appartement_non_copropriete?(property)
        Rails.logger.info "Checking appartement non copropriété for property #{property.id}"

        # Question: "Le bien rénové est-il un appartement non soumis à copropriété (vma)?"
        # Appartement SANS copropriété

        appartement_types = %w[
          appartement
          vma_appartement
          appartement_individuel
        ]

        # Est un appartement MAIS pas en copropriété
        is_appartement = property.type_propriete_flandre.in?(appartement_types) ||
                        property.type.in?(appartement_types) ||
                        property.type&.include?('appartement')

        is_copropriete = appartement_soumis_copropriete?(property)

        result = is_appartement && !is_copropriete
        Rails.logger.info "Result appartement non copropriété: #{result}"
        result
      end

      def immeuble_a_appartements?(property)
        Rails.logger.info "Checking immeuble à appartements for property #{property.id}"

        # Question: "Le bien rénové est-il un immeuble à appartements destinés au logement?"

        immeuble_types = %w[
          immeuble_appartements
          multiple_appartements
          residentiel_multiple
          logements_multiples
        ]

        result = property.type_propriete_flandre.in?(immeuble_types) ||
                property.type.in?(immeuble_types) ||
                property.type&.include?('immeuble')

        Rails.logger.info "Result immeuble à appartements: #{result}"
        result
      end

      def sera_domicilie?(property)
        Rails.logger.info "Checking domiciliation for property #{property.id}"

        # Question: "Êtes-vous ou serez-vous domicilié une fois le bien rénové?"
        # En Flandre, la domiciliation est obligatoire

        # Vérifier via occupation actuelle ou future
        if property.occupation == 'residence_principale' || property.occupation == 'hoofdverblijfplaats'
          Rails.logger.info "Result from occupation residence_principale: true"
          return true
        end

        # Vérifier via champ spécifique domiciliation
        if property.respond_to?(:domicilie_flandre) && property.domicilie_flandre == true
          Rails.logger.info "Result from domicilie_flandre: true"
          return true
        end

        # Si c'est la propriété principale de l'utilisateur (adresse principale)
        if property.respond_to?(:adresse_principale) && property.adresse_principale == true
          Rails.logger.info "Result from adresse_principale: true"
          return true
        end

        # Exclusions explicites
        if property.occupation == 'residence_secondaire' || property.occupation == 'investissement'
          Rails.logger.info "Result from non-principal residence: false"
          return false
        end

        # Par défaut, on assume que l'utilisateur sera domicilié (sera vérifié à posteriori)
        Rails.logger.info "Result domiciliation (default): true"
        true
      end

      # Méthodes d'information pour les questions non-éliminatoires

      def certificat_peb_e_f?(property)
        # Question: "Le certificat PEB avant travaux de rénovation indique-t-il un label E, F?"
        # Cette information affecte les bonus mais n'est pas éliminatoire

        return false unless property.respond_to?(:peb_label_avant)

        peb_labels_eligibles = %w[E F]
        property.peb_label_avant.in?(peb_labels_eligibles)
      end

      def est_client_protege?
        # Question: "Êtes-vous un client protégé..."
        # Affecte directement la catégorie (→ Catégorie 4) mais n'est pas éliminatoire

        @user.respond_to?(:client_protege_flandre) && @user.client_protege_flandre == true
      end

      def est_une_maison?(property)
        # Question: "Le bien rénové est-il une maison?"
        # Information pour affichage, pas éliminatoire

        maison_types = %w[
          maison
          woning
          eengezinswoning
          maison_unifamiliale
        ]

        property.type_propriete_flandre.in?(maison_types) ||
        property.type.in?(maison_types) ||
        property.type&.include?('maison') ||
        property.type&.include?('woning')
      end

      # Méthodes conservées et adaptées pour la logique Flandre

      def user_is_owner?(property)
        # Renvoie vers la nouvelle méthode plus spécifique
        proprietaire_minimum_1_pourcent?(property)
      end

      def property_old_enough?(property)
        # Renvoie vers la nouvelle méthode avec critère 2006
        construit_avant_2006?(property)
      end

      def property_for_habitation?(property)
        # Renvoie vers la nouvelle méthode
        bien_destine_habitation?(property)
      end

      def residence_principale?(property)
        # En Flandre, résidence principale obligatoire mais pas vérifiée ici
        # (cette vérification fait partie du bien destiné à l'habitation)
        return true if property.occupation == 'residence_principale'
        return true if property.occupation == 'hoofdverblijfplaats'

        # Exclusions explicites
        return false if property.occupation == 'residence_secondaire'
        return false if property.occupation == 'investissement'
        return false if property.occupation == 'tweede_verblijf'

        # Par défaut, on assume résidence principale si pas d'indication contraire
        true
      end

      # Méthodes optionnelles pour critères spéciaux (non dans le questionnaire de base)

      def entrepreneur_agre_flandre?(project)
        Rails.logger.info "Checking entrepreneur agréé Flandre for project #{project&.id}"
        Rails.logger.info "- bce_number: #{project&.bce_number}"
        Rails.logger.info "- entrepreneur_agre_flandre: #{project&.entrepreneur_agre_flandre}"

        # Note: Cette vérification peut être optionnelle selon les critères réels
        # En Flandre, l'agrément peut être vérifié à posteriori
        return false unless project&.bce_number.present?

        # Si champ spécifique présent, l'utiliser
        if project.respond_to?(:entrepreneur_agre_flandre)
          return project.entrepreneur_agre_flandre == true
        end

        # Sinon, validation basique du BCE (minimum requis)
        result = project.bce_number.match?(/\A\d{10}\z/)
        Rails.logger.info "- BCE format valid (fallback): #{result}"
        result
      end

      def revenus_eligible_flandre?
        # Note: En Flandre, il n'y a pas de plafond d'inéligibilité strict
        # Le système fonctionne par catégories (1-4)
        # Cette méthode peut retourner true par défaut

        return true unless @user.revenu_demandeur.present?

        # Vérification très permissive - en Flandre les très hauts revenus
        # sont acceptés mais en catégorie 1 (primes minimales)
        revenus = @user.revenu_demandeur.to_i
        plafond_tres_eleve = 500_000 # Plafond symbolique très élevé

        Rails.logger.info "Revenus: #{revenus}, Plafond symbolique: #{plafond_tres_eleve}"
        revenus <= plafond_tres_eleve
      end

      def get_property
        # Récupère la propriété associée à la simulation
        property_id = get_param(:property_id)
        Rails.logger.info "🏠 get_property (Flandre): property_id param = #{property_id}"
        return nil unless property_id

        property = @user.properties.find_by(id: property_id)
        Rails.logger.info "🏠 get_property (Flandre): found property = #{property&.id}, region = '#{property&.region}'"
        property
      end
    end
  end
end
