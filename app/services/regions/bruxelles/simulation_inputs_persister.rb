module Regions
  module Bruxelles
    # Symétrique à Regions::Wallonie/Flandre::SimulationInputsPersister : construit
    # parameters['prime_cards'] au même format (groupé par catégorie, avec
    # 'calculated_amount'/'slug'/'user_input_value') pour que Simulation#primes_count
    # et l'affichage de l'historique fonctionnent sans changement supplémentaire.
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
        Rails.logger.info "💾 Sauvegarde des données spécifiques Bruxelles: #{@user_inputs.inspect}"
        Rails.logger.info "💾 Résultats calculés: #{@prime_results.inspect}"

        existing_params = @simulation.parameters.present? ? JSON.parse(@simulation.parameters) : {}

        prime_cards = {}
        calculated_amounts = {}

        @prime_results.each do |slug, data|
          amount = (data[:amount] || data['amount'] || 0).to_f
          next unless amount > 0

          category = Regions::PrimeCategory.from_slug(slug.to_s)
          prime_cards[category] ||= { 'total' => 0, 'primes' => [] }

          prime_cards[category]['primes'] << {
            'slug' => slug.to_s,
            'titre' => data[:titre] || data['titre'] || slug.to_s.humanize,
            'calculated_amount' => amount,
            'user_input_value' => @user_inputs[slug.to_s] || @user_inputs[slug.to_sym] || 1
          }
          prime_cards[category]['total'] += amount
          calculated_amounts[slug.to_s] = amount
        end

        existing_params['prime_cards'] = prime_cards
        existing_params['calculated_amounts'] = calculated_amounts if calculated_amounts.present?
        existing_params['last_updated'] = Time.current.iso8601

        @simulation.update!(parameters: existing_params.to_json)

        Rails.logger.info "✅ Données Bruxelles sauvegardées avec succès (#{prime_cards.keys.length} catégories, #{calculated_amounts.keys.length} primes > 0)"
      rescue => e
        Rails.logger.error "❌ Erreur lors de la sauvegarde Bruxelles: #{e.message}"
      end
    end
  end
end
