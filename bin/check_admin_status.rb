#!/usr/bin/env ruby

# Script de vérification rapide du statut d'administrateur
# Usage: ruby bin/check_admin_status.rb

require_relative '../config/environment'

puts "🔍 Vérification du statut d'administrateur"
puts "=" * 45

admin_email = "robin@primes-services.be"
user = User.find_by(email: admin_email)

if user.nil?
  puts "❌ ALERTE: Utilisateur #{admin_email} non trouvé!"
  puts "   Action requise: Créer le compte administrateur"
  exit 1
elsif user.admin?
  puts "✅ SUCCÈS: #{admin_email} est administrateur"
  puts "   Statut: #{user.display_role}"
  puts "   Accès admin: #{user.can_access_admin? ? 'Autorisé' : 'Refusé'}"
else
  puts "⚠️  ATTENTION: #{admin_email} n'est PAS administrateur!"
  puts "   Rôle actuel: #{user.display_role}"
  puts "   Action requise: Exécuter 'rails production:ensure_admin'"
  exit 1
end

total_admins = User.admin.count
puts "\n📊 Statistiques administrateurs:"
puts "   Total administrateurs: #{total_admins}"

if total_admins == 1
  puts "   ✅ Configuration sécurisée: un seul administrateur"
else
  puts "   ⚠️  Attention: #{total_admins} administrateurs détectés"
end

puts "\n🚀 Système prêt pour la production!"
