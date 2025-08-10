module Entreprises
  class BruxellesAidesDataService
    # Service d'accès aux données des aides aux entreprises bruxelloises
    # Source: Base de données EntrepriseAide + economie-emploi.brussels

    def self.get_all_categories
      # Récupération dynamique des catégories depuis la base de données
      categories_data = {}

      EntrepriseAide.par_region('bruxelles').actives.group_by(&:categorie).each do |categorie, aides|
        categories_data[categorie.to_sym] = {
          name: format_category_name(categorie),
          icon: get_category_icon(categorie),
          description: get_category_description(categorie),
          color: get_category_color(categorie),
          aides: aides.map { |aide| format_aide_for_category(aide) }
        }
      end

      categories_data
    end

    def self.get_category_details(category_key)
      categorie = category_key.to_s
      aides = EntrepriseAide.par_region('bruxelles').par_categorie(categorie).actives

      aides.map { |aide| format_aide_details(aide) }
    end

    def self.get_aide_by_slug(slug)
      aide = EntrepriseAide.find_by(slug: slug, region: 'bruxelles')
      return nil unless aide

      format_aide_details(aide)
    end

    def self.search_aides_compatible(criteres = {})
      aides = EntrepriseAide.par_region('bruxelles').actives

      # Filtrage par taille d'entreprise
      if criteres[:taille_entreprise].present?
        aides = aides.pour_taille(criteres[:taille_entreprise])
      end

      # Filtrage par catégorie
      if criteres[:categorie].present?
        aides = aides.par_categorie(criteres[:categorie])
      end

      aides.map { |aide| format_aide_summary(aide) }
    end

    private

    def self.format_category_name(categorie)
      case categorie
      when 'transition_economique'
        "Transition économique"
      when 'investissements'
        "Investissements"
      when 'recrutement_formation'
        "Recrutement et formation"
      when 'expertise_services'
        "Expertise et services externes"
      when 'nuisances_chantier'
        "Nuisances chantier"
      when 'exportation'
        "Exportation"
      else
        categorie.humanize
      end
    end

    def self.get_category_icon(categorie)
      case categorie
      when 'transition_economique'
        "🌱"
      when 'investissements'
        "🏭"
      when 'recrutement_formation'
        "👥"
      when 'expertise_services'
        "🎯"
      when 'nuisances_chantier'
        "🚧"
      when 'exportation'
        "🌍"
      else
        "📋"
      end
    end

    def self.get_category_description(categorie)
      case categorie
      when 'transition_economique'
        "Accompagnement vers la transition sociale, environnementale et numérique"
      when 'investissements'
        "Soutien aux investissements matériels et immobiliers"
      when 'recrutement_formation'
        "Aides à l'embauche et formation du personnel"
      when 'expertise_services'
        "Consultance générale, études et audits"
      when 'nuisances_chantier'
        "Dédommagement pour impact de chantiers publics"
      when 'exportation'
        "Primes temporairement suspendues"
      else
        "Aides spécialisées"
      end
    end

    def self.get_category_color(categorie)
      case categorie
      when 'transition_economique'
        "success"
      when 'investissements'
        "primary"
      when 'recrutement_formation'
        "info"
      when 'expertise_services'
        "warning"
      when 'nuisances_chantier'
        "orange"
      when 'exportation'
        "secondary"
      else
        "light"
      end
    end

    def self.format_aide_for_category(aide)
      {
        slug: aide.slug,
        nom: aide.titre,
        montant_min: aide.montant_min,
        montant_max: aide.montant_max,
        taux: aide.taux_aide,
        description: aide.description,
        url: aide.url_officielle,
        statut: aide.statut
      }
    end

    def self.format_aide_details(aide)
      {
        slug: aide.slug,
        titre: aide.titre,
        description: aide.description,
        categorie: aide.categorie,
        montant_min: aide.montant_min,
        montant_max: aide.montant_max,
        taux_aide: aide.taux_aide,
        secteurs_eligibles: aide.secteurs_eligibles,
        tailles_eligibles: aide.tailles_eligibles,
        conditions_eligibilite: aide.conditions_eligibilite,
        documents_requis: aide.documents_requis,
        url_officielle: aide.url_officielle,
        statut: aide.statut
      }
    end

    def self.format_aide_summary(aide)
      {
        slug: aide.slug,
        titre: aide.titre,
        categorie: format_category_name(aide.categorie),
        montant_estime: "#{aide.montant_min}€ - #{aide.montant_max}€",
        taux: "#{aide.taux_aide}%",
        compatibilite: "✅ Compatible"
      }
    end
  end
end
