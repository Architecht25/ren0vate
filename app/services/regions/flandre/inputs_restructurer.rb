module Regions
  module Flandre
    # Restructure les données plates (formulaire) en structure attendue par
    # FlandrePostLoginCalculatorService.
    module InputsRestructurer
      PRIME_SLUGS = %w[
        isolation_toiture isolation_murs isolation_sol
        ramen_deuren warmtepomp warmtepompboiler voorbereiding_isolatie
        voorbereiding_sanitair_elec renovation_toiture renovation_murs renovation_sol
      ].freeze

      def self.call(flat_inputs)
        Rails.logger.info "🔄 Restructuration des données Flandre: #{flat_inputs.inspect}"

        structured = { 'primes' => {} }

        # Extraire le type de pompe s'il est présent (envoyé séparément) —
        # permet la chaîne vide (reset "Choisir")
        warmtepomp_type = flat_inputs['warmtepomp_type']

        flat_inputs.each do |key, value|
          if PRIME_SLUGS.include?(key.to_s)
            # C'est une prime normale - inclure même 0 pour effacer les anciennes valeurs
            type = key.to_s == 'warmtepomp' ? warmtepomp_type : nil
            structured['primes'][key] = { 'value' => value.to_f, 'type' => type }
          elsif key.to_s.start_with?('peb_')
            structured['peb'] ||= {}
            structured['peb'][key.to_s.sub('peb_', '')] = value
          elsif key.to_s.start_with?('amiante_')
            structured['amiante'] ||= {}
            structured['amiante'][key.to_s.sub('amiante_', '')] = value
          end
        end

        structured.delete('primes') if structured['primes'].empty?
        structured.delete('peb') if structured['peb']&.empty?
        structured.delete('amiante') if structured['amiante']&.empty?

        Rails.logger.info "✅ Données restructurées: #{structured.inspect}"
        structured
      end
    end
  end
end
