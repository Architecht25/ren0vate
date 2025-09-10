module Entreprises
  class BruxellesMajorationsService
    attr_reader :property, :project, :aide

    def initialize(property, project, aide)
      @property = property
      @project = project
      @aide = aide
      Rails.logger.info "🔢 Service de majorations Bruxelles initialisé pour aide: #{aide.slug}"
    end

    def calculate_majorations
      Rails.logger.info "🎯 Calcul des majorations pour #{@aide.titre}"

      majorations_applicables = []
      taux_base = extract_base_rate
      taux_total = taux_base

      # Vérifier chaque type de majoration
      majorations_applicables << check_starter_majoration
      majorations_applicables << check_exemplaire_environnemental_majoration
      majorations_applicables << check_exemplaire_social_majoration

      # Filtrer les majorations non-null et calculer le taux total
      majorations_valides = majorations_applicables.compact

      majorations_valides.each do |majoration|
        taux_total += majoration[:taux_majoration]
      end

      # Appliquer le plafond maximum (généralement 80%)
      plafond_max = extract_max_ceiling
      taux_final = [taux_total, plafond_max].min

      result = {
        taux_base: taux_base,
        majorations_applicables: majorations_valides,
        taux_total_brut: taux_total,
        taux_final: taux_final,
        plafonne: taux_total > plafond_max,
        details: build_details_message(majorations_valides, taux_base, taux_final)
      }

      Rails.logger.info "✅ Majorations calculées: #{result}"
      result
    end

    def calculate_prime_with_majorations(montant_investissement)
      majorations_result = calculate_majorations
      montant_prime = montant_investissement * (majorations_result[:taux_final] / 100.0)

      # Appliquer les limites spécifiques de l'aide
      limites = @aide.modalites_paiement&.dig("limites")
      if limites
        montant_max_annuel = extract_monetary_value(limites["montant_max_annuel"])
        if montant_max_annuel && montant_prime > montant_max_annuel
          montant_prime = montant_max_annuel
        end

        intervention_minimum = extract_monetary_value(limites["intervention_minimum"])
        if intervention_minimum && montant_prime < intervention_minimum
          montant_prime = 0 # En dessous du minimum, pas d'aide
        end
      end

      {
        montant_investissement: montant_investissement,
        montant_prime: montant_prime.round(2),
        majorations: majorations_result,
        limites_appliquees: check_applied_limits(montant_prime, limites)
      }
    end

    private

    def extract_base_rate
      taux_base_str = @aide.modalites_paiement&.dig("taux_base") || "#{@aide.taux_aide}%"
      taux_base_str.gsub(/[^\d.]/, '').to_f
    end

    def extract_max_ceiling
      plafond_str = @aide.modalites_paiement&.dig("plafond_max") || "80%"
      plafond_str.gsub(/[^\d.]/, '').to_f
    end

    def extract_monetary_value(value_str)
      return nil unless value_str
      # Extraire la valeur numérique (supporte 15.000€, 15000€, etc.)
      value_str.gsub(/[^\d.]/, '').to_f
    end

    def check_starter_majoration
      return nil unless is_startup_eligible?

      majorations = @aide.modalites_paiement&.dig("majorations")
      return nil unless majorations

      taille_entreprise = determine_company_size

      case taille_entreprise
      when "micro"
        taux_str = majorations["starter_micro"]
        return nil unless taux_str
        {
          type: "starter_micro",
          nom: "Starter Micro-entreprise",
          description: "Majoration pour micro-entreprise récente",
          taux_majoration: taux_str.gsub(/[^\d.]/, '').to_f,
          criteres_remplis: ["Micro-entreprise", "Créée il y a moins de 4 ans"]
        }
      when "petite"
        taux_str = majorations["starter_petite"]
        return nil unless taux_str
        {
          type: "starter_petite",
          nom: "Starter Petite entreprise",
          description: "Majoration pour petite entreprise récente",
          taux_majoration: taux_str.gsub(/[^\d.]/, '').to_f,
          criteres_remplis: ["Petite entreprise", "Créée il y a moins de 4 ans"]
        }
      else
        nil
      end
    end

    def check_exemplaire_environnemental_majoration
      return nil unless has_environmental_exemplarity?

      majorations = @aide.modalites_paiement&.dig("majorations")
      return nil unless majorations

      taille_entreprise = determine_company_size

      case taille_entreprise
      when "micro"
        taux_str = majorations["exemplaire_environnemental_micro"]
        return nil unless taux_str
        {
          type: "exemplaire_environnemental_micro",
          nom: "Exemplarité Environnementale Micro",
          description: "Majoration pour démarche environnementale exemplaire",
          taux_majoration: taux_str.gsub(/[^\d.]/, '').to_f,
          criteres_remplis: determine_environmental_criteria
        }
      when "petite"
        taux_str = majorations["exemplaire_environnemental_petite"]
        return nil unless taux_str
        {
          type: "exemplaire_environnemental_petite",
          nom: "Exemplarité Environnementale Petite",
          description: "Majoration pour démarche environnementale exemplaire",
          taux_majoration: taux_str.gsub(/[^\d.]/, '').to_f,
          criteres_remplis: determine_environmental_criteria
        }
      else
        nil
      end
    end

    def check_exemplaire_social_majoration
      return nil unless has_social_exemplarity?

      majorations = @aide.modalites_paiement&.dig("majorations")
      return nil unless majorations

      taille_entreprise = determine_company_size

      case taille_entreprise
      when "micro"
        taux_str = majorations["exemplaire_social_micro"]
        return nil unless taux_str
        {
          type: "exemplaire_social_micro",
          nom: "Exemplarité Sociale Micro",
          description: "Majoration pour démarche sociale exemplaire",
          taux_majoration: taux_str.gsub(/[^\d.]/, '').to_f,
          criteres_remplis: determine_social_criteria
        }
      when "petite"
        taux_str = majorations["exemplaire_social_petite"]
        return nil unless taux_str
        {
          type: "exemplaire_social_petite",
          nom: "Exemplarité Sociale Petite",
          description: "Majoration pour démarche sociale exemplaire",
          taux_majoration: taux_str.gsub(/[^\d.]/, '').to_f,
          criteres_remplis: determine_social_criteria
        }
      else
        nil
      end
    end

    def determine_company_size
      return "micro" if @property.nombre_salaries.nil? || @property.nombre_salaries < 10
      return "petite" if @property.nombre_salaries < 50
      return "moyenne" if @property.nombre_salaries < 250
      "grande"
    end

    def is_startup_eligible?
      return false unless @property.date_creation.present?

      # Une entreprise est considérée comme "starter" si elle a moins de 4 ans
      years_since_creation = (Date.current - @property.date_creation) / 365.25
      years_since_creation < 4
    end

    def has_environmental_exemplarity?
      # Critères d'exemplarité environnementale
      # Pour l'instant, on se base sur le type d'aide et les secteurs
      environmental_sectors = ["renewable_energy", "green_tech", "circular_economy"]
      environmental_keywords = ["transition", "environnement", "écologique", "vert", "énergie"]

      # Vérifier si l'aide concerne l'environnement
      aide_environmental = environmental_keywords.any? { |keyword|
        @aide.titre.downcase.include?(keyword) ||
        @aide.description&.downcase&.include?(keyword) ||
        @aide.slug.include?(keyword)
      }

      # TODO: Ajouter des critères plus précis basés sur des champs spécifiques
      # comme certifications environnementales, labels, etc.
      aide_environmental
    end

    def has_social_exemplarity?
      # Critères d'exemplarité sociale
      social_indicators = []

      # Plan de diversité actif (déjà requis pour >50 employés, bonus si <50)
      if @property.plan_diversite_actif && @property.nombre_salaries.to_i <= 50
        social_indicators << "Plan de diversité volontaire"
      end

      # TODO: Ajouter d'autres critères sociaux comme:
      # - Formation continue des employés
      # - Égalité salariale
      # - Insertion professionnelle
      # - Partenariats avec des entreprises d'économie sociale

      social_keywords = ["formation", "recrutement", "social", "diversité", "inclusion"]
      aide_social = social_keywords.any? { |keyword|
        @aide.titre.downcase.include?(keyword) ||
        @aide.description&.downcase&.include?(keyword) ||
        @aide.slug.include?(keyword)
      }

      social_indicators.any? || aide_social
    end

    def determine_environmental_criteria
      criteria = []
      criteria << "Aide orientée transition environnementale" if has_environmental_exemplarity?
      # TODO: Ajouter des critères plus spécifiques
      criteria
    end

    def determine_social_criteria
      criteria = []
      criteria << "Plan de diversité actif" if @property.plan_diversite_actif
      criteria << "Aide orientée impact social" if has_social_exemplarity?
      # TODO: Ajouter des critères plus spécifiques
      criteria
    end

    def check_applied_limits(montant_prime, limites)
      applied = []
      return applied unless limites

      montant_max = extract_monetary_value(limites["montant_max_annuel"])
      if montant_max && montant_prime >= montant_max
        applied << "Plafond annuel de #{limites['montant_max_annuel']} appliqué"
      end

      intervention_min = extract_monetary_value(limites["intervention_minimum"])
      if intervention_min && montant_prime > 0 && montant_prime < intervention_min
        applied << "En dessous du minimum de #{limites['intervention_minimum']}"
      end

      applied
    end

    def build_details_message(majorations, taux_base, taux_final)
      message = "Taux de base: #{taux_base}%"

      if majorations.any?
        message += "\nMajorations appliquées:"
        majorations.each do |maj|
          message += "\n• #{maj[:nom]}: +#{maj[:taux_majoration]}%"
        end
      end

      message += "\nTaux final: #{taux_final}%"
      message
    end
  end
end
