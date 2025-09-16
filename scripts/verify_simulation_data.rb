#!/usr/bin/env ruby
# Script pour vérifier et corriger les données de simulation existantes

require_relative '../config/environment'

class SimulationDataVerifier
  def initialize
    @logger = Rails.logger
    @fixed_count = 0
    @error_count = 0
  end

  def verify_and_fix_all
    puts "🔍 Vérification des simulations existantes..."

    simulations = Simulation.all
    puts "📊 Total de #{simulations.count} simulations à vérifier"

    simulations.find_each do |simulation|
      verify_simulation(simulation)
    end

    puts "\n✅ Vérification terminée:"
    puts "   - #{@fixed_count} simulations corrigées"
    puts "   - #{@error_count} erreurs détectées"
  end

  private

  def verify_simulation(simulation)
    print "🔍 Simulation #{simulation.id} (#{simulation.titre})... "

    problems = []

    # Vérifier la cohérence du total
    if simulation.total_simule.nil?
      problems << "total_simule manquant"
    end

    # Vérifier les paramètres JSON
    if simulation.parameters.present?
      begin
        params_data = JSON.parse(simulation.parameters)

        # Vérifier la cohérence total_simule vs parameters
        params_total = params_data['total_general'] || params_data['total'] || 0
        if simulation.total_simule.to_f != params_total.to_f
          problems << "total incohérent (DB: #{simulation.total_simule}, JSON: #{params_total})"
        end

      rescue JSON::ParserError => e
        problems << "JSON invalide: #{e.message}"
      end
    elsif simulation.total_simule.to_f > 0
      problems << "total_simule présent mais parameters manquant"
    end

    if problems.any?
      puts "❌ Problèmes: #{problems.join(', ')}"
      fix_simulation(simulation, problems)
    else
      puts "✅ OK"
    end
  end

  def fix_simulation(simulation, problems)
    begin
      fixed = false

      # Corriger le total manquant
      if simulation.total_simule.nil? && simulation.parameters.present?
        params_data = JSON.parse(simulation.parameters)
        params_total = params_data['total_general'] || params_data['total'] || 0
        if params_total > 0
          simulation.update_column(:total_simule, params_total)
          puts "  ✅ Total corrigé: #{params_total}€"
          fixed = true
        end
      end

      # Corriger les incohérences de total
      if simulation.parameters.present?
        params_data = JSON.parse(simulation.parameters)
        params_total = params_data['total_general'] || params_data['total'] || 0

        if simulation.total_simule.to_f != params_total.to_f && params_total > 0
          simulation.update_column(:total_simule, params_total)
          puts "  ✅ Total synchronisé: #{params_total}€"
          fixed = true
        end
      end

      if fixed
        @fixed_count += 1
      else
        @error_count += 1
      end

    rescue => e
      puts "  ❌ Erreur lors de la correction: #{e.message}"
      @error_count += 1
    end
  end
end

# Exécuter le script
if __FILE__ == $0
  verifier = SimulationDataVerifier.new
  verifier.verify_and_fix_all
end
