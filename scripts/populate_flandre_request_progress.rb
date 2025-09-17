#!/usr/bin/env ruby
# Scr# 1. Trouver ou créer un utilisateur de test
user = User.find_by(email: "test.flandre@example.com") || User.create!(
  email: "test.flandre@example.com",
  password: "password123",
  confirmed_at: Time.current,  # Pour éviter les problèmes Devise
  role: :user
)

puts "👤 Utilisateur trouvé/créé : #{user.email}"

# 2. Créer la première request en mode draft (évite les validations Flandre)
request = Request.create!(
  user: user,
  title: "Demande test Flandre - Primes isolation",
  description: "Test de demande pour simuler différents états administratifs",
  status: 'draft',  # Mode draft pour éviter les validations
  region: 'flandre'
)uler request_progresses avec un cas réaliste de Flandre
# Usage: rails runner scripts/populate_flandre_request_progress.rb

puts "🏠 Création d'un cas réaliste Flandre avec 5 primes..."

# 1. Prendre 5 primes existantes de Flandre
puts "🔍 Récupération des primes Flandre existantes..."

primes = Prime.where(region: 'flandre').limit(5)
if primes.count < 5
  puts "❌ Il faut au moins 5 primes Flandre en base. Exécutez d'abord: rails db:seed"
  exit 1
end

puts "✅ #{primes.count} primes trouvées:"
primes.each { |p| puts "  - #{p.titre} (#{p.slug})" }

# 2. Créer un "request" fictif simple en utilisant une simulation existante
simulation = Simulation.first
unless simulation
  puts "❌ Aucune simulation trouvée. Le script a besoin d'au moins une simulation."
  exit 1
end

# Créer un request minimal en contournant les validations
request = Request.new
request.assign_attributes(
  property_id: simulation.property_id,
  project_id: simulation.project_id,
  region: 'flandre',
  status: 'en_cours'
)
# Sauvegarder sans validations pour les données de test
request.save!(validate: false)

puts "✅ Request de test créé: ##{request.id}"

# 3. Créer les request_progresses avec différents états
progress_data = [
  {
    prime_index: 0,
    status: :accorde,
    pourcentage: 100,
    step: "Finalisé",
    montant_demande: 3500,
    montant_accorde: 3200,
    commentaires: "Prime accordée partiellement - Maximum atteint pour cette catégorie"
  },
  {
    prime_index: 1,
    status: :en_cours,
    pourcentage: 75,
    step: "En évaluation technique",
    montant_demande: 4800,
    montant_accorde: nil,
    commentaires: "Dossier technique en cours d'examen. Visite prévue le 25/09."
  },
  {
    prime_index: 2,
    status: :incomplet,
    pourcentage: 40,
    step: "Documents manquants",
    montant_demande: 2800,
    montant_accorde: nil,
    commentaires: "Manque: facture entrepreneur agréé + certificat matériaux"
  },
  {
    prime_index: 3,
    status: :soumis,
    pourcentage: 25,
    step: "Accusé de réception",
    montant_demande: 1200,
    montant_accorde: nil,
    commentaires: "Dossier soumis le 15/09. En attente d'accusé de réception."
  },
  {
    prime_index: 4,
    status: :en_preparation,
    pourcentage: 10,
    step: "Collecte documents",
    montant_demande: 600,
    montant_accorde: nil,
    commentaires: "Préparation dossier - Rendez-vous auditeur programmé"
  }
]

puts "\n🔄 Création des RequestProgress..."

progress_data.each_with_index do |data, index|
  prime = primes[data[:prime_index]]

  # Créer le RequestProgress
  progress = RequestProgress.find_or_create_by!(
    request: request,
    prime: prime
  ) do |rp|
    rp.email_suivi = "#{prime.code.downcase}@tracking.ren0vate.be"
  end

  # Générer un numéro de dossier réaliste
  numero_dossier = data[:status] != :en_preparation ? "2025-FL-#{prime.category.upcase}-#{rand(10000..99999)}" : nil

  # Mettre à jour avec les données spécifiques
  progress.update!(
    pourcentage: data[:pourcentage],
    step: data[:step],
    status_administratif: data[:status],
    montant_demande: data[:montant_demande],
    montant_accorde: data[:montant_accorde],
    numero_dossier: numero_dossier,
    commentaires_admin: data[:commentaires],
    completed: data[:status] == :accorde,
    completed_at: data[:status] == :accorde ? 1.week.ago : nil,
    date_soumission: case data[:status]
                     when :accorde then 3.weeks.ago.to_date
                     when :en_cours then 2.weeks.ago.to_date
                     when :incomplet then 10.days.ago.to_date
                     when :soumis then 2.days.ago.to_date
                     else nil
                     end,
    date_derniere_maj: Date.current,
    document_recu: [:accorde, :en_cours].include?(data[:status])
  )

  puts "  ✅ #{prime.nom} - #{progress.status_administratif} (#{progress.pourcentage}%)"
  puts "     💰 Demandé: #{progress.montant_demande}€ | Accordé: #{progress.montant_accorde || 'En attente'}€"
  puts "     📋 Dossier: #{progress.numero_dossier || 'Non attribué'}"
end

# 5. Résumé final
puts "\n" + "="*60
puts "📊 RÉSUMÉ DU CAS FLANDRE CRÉÉ"
puts "="*60

total_demande = RequestProgress.joins(:request).where(requests: { id: request.id }).sum(:montant_demande)
total_accorde = RequestProgress.joins(:request).where(requests: { id: request.id }).sum(:montant_accorde)

puts "🏠 Request ID: #{request.id}"
puts "📍 Région: #{request.region.upcase}"
puts "💰 Total demandé: #{total_demande}€"
puts "✅ Total accordé: #{total_accorde}€"
puts "📈 Taux d'octroi: #{total_demande > 0 ? (total_accorde / total_demande * 100).round(1) : 0}%"

puts "\n📋 ÉTAT DES PRIMES:"
RequestProgress.joins(:request, :prime)
                .where(requests: { id: request.id })
                .includes(:prime)
                .order(:created_at)
                .each do |rp|
  status_icon = case rp.status_administratif
                when 'accorde' then '✅'
                when 'en_cours' then '⏳'
                when 'incomplet' then '⚠️'
                when 'soumis' then '📤'
                when 'en_preparation' then '📝'
                else '❓'
                end

  puts "#{status_icon} #{rp.prime.nom} - #{rp.status_administratif} (#{rp.pourcentage}%)"
  puts "    Step: #{rp.step}"
  puts "    Dossier: #{rp.numero_dossier || 'N/A'}"
end

puts "\n🎯 Cas d'usage créé avec succès !"
puts "   Utilisez ces données pour tester votre interface de suivi."
puts "   Request ID: #{request.id} pour vos tests."
