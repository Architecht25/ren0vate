# Calcul du revenu ajusté du ménage pour la Wallonie — source unique, utilisée par
# WallonieCategoryService (régime primes cash) et PretReduction::EligibilityService
# (nouveau régime prêt bonifié), pour éviter la désynchronisation entre les copies
# précédemment dupliquées dans simulations_controller#check_wallonie_real_eligibility.
module Regions
  module Wallonie
    class HouseholdIncomeCalculator
      DEDUCTION_PAR_PERSONNE = 5000

      def initialize(user)
        @user = user
      end

      def total_household_income
        total = @user.revenu_demandeur || 0

        if @user.situation_familiale.in?(%w[marie cohabitant couple]) && @user.revenu_conjoint
          total += @user.revenu_conjoint
        end

        total
      end

      def adjusted_income
        deductions = 0

        if @user.nombre_enfants && @user.nombre_enfants > 0
          deductions += @user.nombre_enfants * DEDUCTION_PAR_PERSONNE
        end

        if @user.respond_to?(:personnes_60_ans_et_plus) && @user.personnes_60_ans_et_plus && @user.personnes_60_ans_et_plus > 0
          deductions += @user.personnes_60_ans_et_plus * DEDUCTION_PAR_PERSONNE
        end

        if @user.respond_to?(:femme_enceinte) && @user.femme_enceinte == true
          deductions += DEDUCTION_PAR_PERSONNE
        end

        [total_household_income - deductions, 0].max
      end

      def total_deductions
        total_household_income - adjusted_income
      end
    end
  end
end
