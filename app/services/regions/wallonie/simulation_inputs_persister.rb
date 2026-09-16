module Regions
  module Wallonie
    class SimulationInputsPersister
      def self.call(simulation:, user_inputs:, prime_results: {})
        new(simulation, user_inputs, prime_results).call
      end

      def initialize(simulation, user_inputs, prime_results)
        @simulation = simulation
        @user_inputs = user_inputs
        @prime_results = prime_results
      end

      def call
        Rails.logger.info "💾 Sauvegarde des données spécifiques Wallonie: #{@user_inputs.inspect}"
        Rails.logger.info "💾 Résultats calculés: #{@prime_results.inspect}"

        # Ne pas sauvegarder si toutes les valeurs sont nulles/vides
        non_zero_values = @user_inputs.select { |k, v| v.present? && v != 0 && v != "0" }
        if non_zero_values.empty?
          Rails.logger.info "⚠️ Aucune donnée significative à sauvegarder pour Wallonie"
          return
        end

        existing_params = @simulation.parameters.present? ? JSON.parse(@simulation.parameters) : {}

        # Sauvegarder toutes les données Wallonie directement (clés qui commencent par wallonie_)
        @user_inputs.each do |key, value|
          if key.to_s.start_with?('wallonie_') && value.present?
            existing_params[key.to_s] = value
            Rails.logger.info "💾 Donnée Wallonie sauvegardée: #{key} = #{value}"
          end
        end

        if @prime_results.present?
          calculated_amounts = {}
          @prime_results.each do |slug, data|
            amount = data[:amount] || data['amount'] || 0
            calculated_amounts[slug.to_s] = amount
            Rails.logger.info "💾 Montant calculé sauvegardé: #{slug} = #{amount}€"
          end
          existing_params['calculated_amounts'] = calculated_amounts
        end

        existing_params['last_updated'] = Time.current.iso8601

        @simulation.update!(parameters: existing_params.to_json)

        Rails.logger.info "✅ #{non_zero_values.keys.length} données Wallonie sauvegardées avec succès"
      rescue => e
        Rails.logger.error "❌ Erreur lors de la sauvegarde Wallonie: #{e.message}"
      end
    end
  end
end
