module Regions
  module Bruxelles
    class BruxellesEntreprisesCalculatorService
      attr_reader :property, :project, :user_inputs

      def initialize(property, project, user_inputs = {})
        @property = property
        @project = project
        @user_inputs = user_inputs
        Rails.logger.info "🏢 Service calculateur entreprises Bruxelles initialisé"
      end

      def calculate_primes
        Rails.logger.info "🎯 Calcul des primes entreprises Bruxelles"

        calculated_primes = []

        # Récupérer toutes les aides entreprise de Bruxelles
        aides = EntrepriseAide.where(region: "bruxelles")

        aides.each do |aide|
          montant_investissement = get_investment_amount_for_aide(aide)
          next if montant_investissement <= 0

          # Calculer avec majorations
          majorations_service = Entreprises::BruxellesMajorationsService.new(@property, @project, aide)
          result = majorations_service.calculate_prime_with_majorations(montant_investissement)

          next if result[:montant_prime] <= 0

          calculated_primes << {
            aide_id: aide.id,
            slug: aide.slug,
            titre: aide.titre,
            montant_investissement: result[:montant_investissement],
            montant_prime: result[:montant_prime],
            taux_base: result[:majorations][:taux_base],
            taux_final: result[:majorations][:taux_final],
            majorations_appliquees: result[:majorations][:majorations_applicables],
            limites_appliquees: result[:limites_appliquees],
            details: result[:majorations][:details],
            calculation_type: "enterprise_with_majorations",
            system: "BRUXELLES_ENTREPRISES"
          }
        end

        Rails.logger.info "✅ #{calculated_primes.size} primes calculées"
        calculated_primes
      end

      def calculate_single_prime(aide_slug, montant_investissement)
        aide = EntrepriseAide.find_by(slug: aide_slug, region: "bruxelles")
        return nil unless aide

        majorations_service = Entreprises::BruxellesMajorationsService.new(@property, @project, aide)
        result = majorations_service.calculate_prime_with_majorations(montant_investissement)

        {
          aide: aide,
          result: result,
          calculation_summary: build_calculation_summary(aide, result)
        }
      end

      def get_majorations_details(aide_slug)
        aide = EntrepriseAide.find_by(slug: aide_slug, region: "bruxelles")
        return nil unless aide

        majorations_service = Entreprises::BruxellesMajorationsService.new(@property, @project, aide)
        majorations_service.calculate_majorations
      end

      private

      def get_investment_amount_for_aide(aide)
        # Récupérer le montant saisi par l'utilisateur pour cette aide
        user_input_key = aide.slug
        user_amount = @user_inputs[user_input_key].to_f

        return user_amount if user_amount > 0

        # Si pas de saisie utilisateur, utiliser le montant minimum requis ou 0
        aide.montant_investissement_min_requis&.to_f || 0
      end

      def build_calculation_summary(aide, result)
        summary = {
          titre: aide.titre,
          montant_investissement: result[:montant_investissement],
          montant_prime: result[:montant_prime],
          taux_final: result[:majorations][:taux_final]
        }

        if result[:majorations][:majorations_applicables].any?
          summary[:majorations] = result[:majorations][:majorations_applicables].map do |maj|
            {
              nom: maj[:nom],
              taux: "+#{maj[:taux_majoration]}%",
              criteres: maj[:criteres_remplis]
            }
          end
        end

        summary[:limites] = result[:limites_appliquees] if result[:limites_appliquees].any?
        summary
      end
    end
  end
end
