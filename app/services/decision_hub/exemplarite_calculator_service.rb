module DecisionHub
  class ExemplariteCalculatorService
    attr_reader :simulation, :property

    def initialize(simulation)
      @simulation = simulation
      @property = simulation&.property
    end

    def calculate_exemplarite_potential
      return default_exemplarite_data unless @property&.region == 'bruxelles'
      return default_exemplarite_data unless is_entreprise?

      begin
        # Récupérer les investissements estimés de la simulation
        investissement_total = estimate_total_investment

        # Calculer les gains potentiels avec l'exemplarité
        gains = calculate_gains_by_criteria(investissement_total)

        {
          eligible: true,
          investissement_estime: investissement_total,
          gains_potentiels: gains,
          taille_entreprise: determine_company_size,
          age_entreprise: determine_company_age,
          exemplarite_actuelle: assess_current_exemplarite,
          recommandations_prioritaires: generate_priority_recommendations,
          impact_financier: calculate_financial_impact(gains)
        }
      rescue StandardError => e
        Rails.logger.error "Error calculating exemplarite: #{e.message}"
        default_exemplarite_data
      end
    end

    private

    def is_entreprise?
      @property&.is_entreprise? rescue false
    end

    def estimate_total_investment
      # Si on a une simulation avec des montants, on les utilise
      if @simulation&.total_simule && @simulation.total_simule > 0
        # On estime l'investissement comme 4x le montant des primes (ratio moyen 25%)
        @simulation.total_simule * 4
      else
        # Valeur par défaut pour l'exemple
        50000
      end
    end

    def determine_company_size
      return 'micro' unless @property&.nombre_salaries

      case @property.nombre_salaries
      when 0..9
        'micro'
      when 10..49
        'petite'
      when 50..249
        'moyenne'
      else
        'grande'
      end
    end

    def determine_company_age
      return 'recent' unless @property&.date_creation

      years = (Date.current - @property.date_creation) / 365.25
      years < 4 ? 'recent' : 'etablie'
    end

    def calculate_gains_by_criteria(investissement)
      taille = determine_company_size
      age = determine_company_age

      # Taux de base selon le type d'aide (moyenne)
      taux_base = 35.0

      # Majorations selon les critères
      majorations = {}

      # Majoration Starter
      if age == 'recent'
        majoration_starter = case taille
                           when 'micro' then 25.0
                           when 'petite' then 20.0
                           when 'moyenne' then 10.0
                           else 0.0
                           end
        majorations[:starter] = {
          taux: majoration_starter,
          montant: investissement * (majoration_starter / 100.0),
          description: "Entreprise récente (< 4 ans)"
        }
      end

      # Majoration Exemplarité Environnementale
      majoration_env = case taille
                     when 'micro', 'petite' then 30.0
                     when 'moyenne' then 20.0
                     else 0.0
                     end
      majorations[:environnemental] = {
        taux: majoration_env,
        montant: investissement * (majoration_env / 100.0),
        description: "Exemplarité environnementale"
      }

      # Majoration Exemplarité Sociale
      majoration_social = case taille
                        when 'micro', 'petite' then 30.0
                        when 'moyenne' then 20.0
                        else 0.0
                        end
      majorations[:social] = {
        taux: majoration_social,
        montant: investissement * (majoration_social / 100.0),
        description: "Exemplarité sociale"
      }

      # Calcul du total (plafonné à 80%)
      taux_total_brut = taux_base + majorations.values.sum { |m| m[:taux] }
      taux_final = [taux_total_brut, 80.0].min

      {
        taux_base: taux_base,
        majorations: majorations,
        taux_total_brut: taux_total_brut,
        taux_final: taux_final,
        montant_base: investissement * (taux_base / 100.0),
        montant_avec_majorations: investissement * (taux_final / 100.0),
        gain_supplementaire: investissement * ((taux_final - taux_base) / 100.0)
      }
    end

    def assess_current_exemplarite
      # Évaluation basique de l'exemplarité actuelle
      # Dans une vraie implémentation, cela pourrait être basé sur des données du profil
      {
        environnemental: {
          score: 25, # sur 100
          criteres_remplis: ["Certification énergétique de base"],
          criteres_manquants: ["ISO 14001", "Énergies renouvelables", "Gestion déchets avancée"]
        },
        social: {
          score: 15, # sur 100
          criteres_remplis: [],
          criteres_manquants: ["Plan de diversité", "Formation continue", "Partenariats sociaux"]
        }
      }
    end

    def generate_priority_recommendations
      [
        {
          domaine: "Environnemental",
          action: "Audit énergétique complet",
          impact: "Élevé",
          cout_estime: 2500,
          delai: "2-3 mois",
          roi_potentiel: 15000
        },
        {
          domaine: "Social",
          action: "Mise en place d'un plan de diversité",
          impact: "Élevé",
          cout_estime: 1000,
          delai: "1-2 mois",
          roi_potentiel: 15000
        },
        {
          domaine: "Environnemental",
          action: "Installation LED + gestion intelligente",
          impact: "Moyen",
          cout_estime: 5000,
          delai: "1 mois",
          roi_potentiel: 2000
        }
      ]
    end

    def calculate_financial_impact(gains)
      gain_total = gains[:gain_supplementaire]

      {
        gain_total: gain_total,
        roi_investissement_exemplarite: (gain_total / 10000.0 * 100).round(1), # ROI sur 10k€ d'efforts
        break_even_mois: gain_total > 0 ? (10000.0 / (gain_total / 12)).round(1) : nil,
        impact_tresorerie: gain_total
      }
    end

    def default_exemplarite_data
      {
        eligible: false,
        raison_ineligibilite: "Cette fonctionnalité est réservée aux entreprises bruxelloises",
        investissement_estime: 0,
        gains_potentiels: {},
        recommandations_prioritaires: []
      }
    end
  end
end
