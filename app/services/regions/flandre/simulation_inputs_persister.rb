module Regions
  module Flandre
    # Persiste les saisies utilisateur (PEB, amiante, primes) et les montants
    # calculés dans Simulation#parameters, au format lu par restore_prime_inputs.
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
        Rails.logger.info "💾 Sauvegarde des données spécifiques Flandre: #{@user_inputs.inspect}"
        Rails.logger.info "💾 Résultats calculés: #{@prime_results.inspect}"

        if @user_inputs.empty?
          Rails.logger.info "⚠️ Aucune donnée à sauvegarder (user_inputs vide)"
          return
        end

        existing_params = @simulation.parameters.present? ? JSON.parse(@simulation.parameters) : {}

        if @user_inputs['peb'].present?
          existing_params['peb_data'] = @user_inputs['peb']
          Rails.logger.info "💾 Données PEB sauvegardées: #{@user_inputs['peb'].inspect}"
        end

        if @user_inputs['amiante'].present?
          existing_params['amiante_data'] = @user_inputs['amiante']
          Rails.logger.info "💾 Données Amiante sauvegardées: #{@user_inputs['amiante'].inspect}"
        end

        # Convertir les primes au format attendu par restore_prime_inputs
        if @user_inputs['primes'].present?
          existing_params['prime_cards'] ||= {}

          @user_inputs['primes'].each do |slug, prime_data|
            next unless prime_data['value'].present?

            category = Regions::PrimeCategory.from_slug(slug)

            existing_params['prime_cards'][category] ||= {
              'total' => 0,
              'primes' => []
            }

            existing_prime = existing_params['prime_cards'][category]['primes'].find { |p| p['slug'] == slug }
            if existing_prime
              existing_prime['user_input_value'] = prime_data['value']
            else
              existing_params['prime_cards'][category]['primes'] << {
                'slug' => slug,
                'user_input_value' => prime_data['value']
              }
            end
          end

          Rails.logger.info "💾 Données primes sauvegardées dans le bon format"
        end

        # Sauvegarder aussi les données brutes pour la restructuration (fallback)
        @user_inputs.each do |key, value|
          if key != 'peb' && key != 'amiante' && key != 'primes' && !value.nil?
            existing_params[key] = value
          end
        end

        if @prime_results.present?
          calculated_amounts = {}
          @prime_results.each do |slug, data|
            amount = data[:amount] || data[:calculated_amount] || data['amount'] || data['calculated_amount'] || 0
            calculated_amounts[slug.to_s] = amount
            Rails.logger.info "💾 Montant calculé sauvegardé: #{slug} = #{amount}€"
          end
          existing_params['calculated_amounts'] = calculated_amounts
        end

        existing_params['last_updated'] = Time.current.iso8601

        @simulation.update!(parameters: existing_params.to_json)

        Rails.logger.info "✅ Données Flandre sauvegardées avec succès"
      rescue => e
        Rails.logger.error "❌ Erreur lors de la sauvegarde Flandre: #{e.message}"
      end
    end
  end
end
