module Regions
  # Éligibilité "réelle" (revenus) d'une simulation déjà catégorisée — distinct
  # des services Regions::*::*EligibilityService qui vérifient l'éligibilité
  # structurelle (localisation, propriété, âge du bien) en amont.
  class SimulationEligibilityChecker
    def self.call(simulation)
      new(simulation).call
    end

    def initialize(simulation)
      @simulation = simulation
    end

    def call
      return { eligible: false, reason: "Simulation non trouvée" } unless @simulation
      return { eligible: false, reason: "Utilisateur non trouvé" } unless @simulation.property&.user

      user = @simulation.property.user

      case @simulation.region&.downcase
      when 'wallonie'
        wallonie_eligibility(user)
      when 'flandre'
        flandre_eligibility(user)
      when 'bruxelles'
        # Les primes Renolution ont été supprimées, mais Monuments & Sites reste actif
        # L'éligibilité spécifique est gérée dans chaque carte de simulation
        {
          eligible: true,
          reason: "Aucune prime générale de rénovation énergétique n'est actuellement ouverte à " \
                  "Bruxelles (Renolution supprimé). Petit Patrimoine et Monuments & Sites restent " \
                  "accessibles séparément."
        }
      else
        { eligible: false, reason: "Région non supportée" }
      end
    end

    private

    def wallonie_eligibility(user)
      return { eligible: false, reason: "Revenus non renseignés" } unless user.revenu_demandeur

      if @simulation.regime_effectif == "reduction_pret"
        params = { property_id: @simulation.property_id, project_id: @simulation.project_id }
        result = Regions::Wallonie::PretReduction::EligibilityService.new(params, user: user).check_eligibility
        return { eligible: result[:eligible], reason: result[:message] }
      end

      adjusted_income = Regions::Wallonie::HouseholdIncomeCalculator.new(user).adjusted_income
      threshold = Regions::Wallonie::WallonieCategoryService::ELIGIBILITY_THRESHOLD

      if adjusted_income > threshold
        {
          eligible: false,
          reason: "Revenus trop élevés (#{adjusted_income.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}€ > #{threshold.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}€)"
        }
      else
        { eligible: true }
      end
    end

    def flandre_eligibility(user)
      return { eligible: false, reason: "Revenus non renseignés" } unless user.revenu_demandeur

      # Calcul du revenu total du ménage
      total_income = user.revenu_demandeur
      if user.situation_familiale.in?(%w[marie cohabitant couple]) && user.revenu_conjoint
        total_income += user.revenu_conjoint
      end

      # Déductions Flandre : 4 320 € par personne à charge
      nb_charges = (user.nombre_enfants || 0)
      nb_charges += user.personnes_agees_charge if user.respond_to?(:personnes_agees_charge) && user.personnes_agees_charge
      deductions = nb_charges * 4_320
      adjusted_income = [total_income - deductions, 0].max

      # Seuils de revenu Flandre 2025 — catégorie 1 = revenus élevés, toujours éligible
      # En Flandre il n'y a pas de seuil d'inéligibilité, seulement des catégories
      # Toutes les catégories sont éligibles (la catégorie détermine le montant de la prime)
      { eligible: true }
    end
  end
end
