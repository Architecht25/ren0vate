#!/usr/bin/env ruby

# Script de test pour vérifier les données de la simulation 81
sim = Simulation.find(81)
puts "=== Simulation 81 ==="
puts "Region: #{sim.region.inspect}"
puts "Total: #{sim.total_simule.inspect}"
puts "Parameters present: #{sim.parameters.present?}"

if sim.total_simule && sim.region
  puts "\n=== Test SavingsCalculatorService ==="
  calculator = SavingsCalculatorService.new(sim.total_simule, sim.region)
  savings = calculator.calculate_savings
  puts "Savings data: #{savings.inspect}"
  puts "Should show component: #{savings && savings[:savings_amount] > 500}"
  
  if savings
    puts "\nDetails:"
    puts "  Chasseur cost: #{savings[:chasseur_cost]}€"
    puts "  SaaS cost: #{savings[:saas_cost]}€"
    puts "  Savings amount: #{savings[:savings_amount]}€"
    puts "  Savings percentage: #{savings[:savings_percentage]}%"
  end
else
  puts "❌ Missing data for calculation"
end