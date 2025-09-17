#!/usr/bin/env ruby
# Script pour populer request_progresses avec un cas réaliste de Flandre
# Usage: rails runner scripts/populate_flandre_request_progress_clean.rb

puts "🏠 Création d'un cas réaliste Flandre avec 5 primes..."

# 1. Trouver ou créer un utilisateur de test
user = User.find_by(email: "test.flandre@example.com") || User.create!(
  email: "test.flandre@example.com",
  password: "password123",
  confirmed_at: Time.current,  # Pour éviter les problèmes Devise
  role: :user
)

puts "👤 Utilisateur trouvé/créé : #{user.email}"

# 2. Créer une property de test
property = Property.find_by(user: user, address: "Rue de Test 123, 1000 Bruxelles") || Property.create!(
  user: user,
  address: "Rue de Test 123, 1000 Bruxelles",
  city: "Bruxelles",
  postal_code: "1000",
  type: "house"
)

puts "🏠 Property trouvée/créée : #{property.address}"

# 3. Créer la première request en mode draft (évite les validations Flandre)
request = Request.create!(
  user: user,
  property: property,  # Associer la property
  title: "Demande test Flandre - Primes isolation",
  description: "Test de demande pour simuler différents états administratifs",
  status: 'draft',  # Mode draft pour éviter les validations
  region: 'flandre'
)

puts "📋 Request créée : #{request.title} (ID: #{request.id})"

# 4. Récupérer 5 primes Flandre existantes
puts "🔍 Récupération des primes Flandre existantes..."
primes = Prime.where(region: 'flandre').limit(5)

if primes.count < 5
  puts "❌ Pas assez de primes Flandre (trouvées: #{primes.count})"
  exit 1
end

puts "✅ #{primes.count} primes trouvées:"
primes.each do |prime|
  puts "  - #{prime.titre} (#{prime.slug})"
end

# 5. Créer les 5 request_progresses avec différents états
states = ['accorde', 'en_cours', 'incomplet', 'soumis', 'en_preparation']

puts "\n🏗️ Création des request_progresses..."

primes.each_with_index do |prime, index|
  state = states[index]

  # Montants selon l'état
  montant_demande = [2500, 1800, 3200, 1500, 2100][index]
  montant_accorde = state == 'accorde' ? montant_demande : nil

  request_progress = RequestProgress.create!(
    request: request,
    prime: prime,
    status_administratif: state,
    step: "#{state.capitalize} - #{prime.titre}",
    pourcentage: case state
                 when 'en_preparation' then 10
                 when 'soumis' then 30
                 when 'en_cours' then 60
                 when 'incomplet' then 40
                 when 'accorde' then 100
                 end,
    date_soumission: case state
                     when 'en_preparation' then nil
                     when 'soumis' then 2.weeks.ago.to_date
                     when 'en_cours' then 1.month.ago.to_date
                     when 'incomplet' then 3.weeks.ago.to_date
                     when 'accorde' then 2.months.ago.to_date
                     end,
    date_derniere_maj: case state
                       when 'en_preparation' then Date.current
                       when 'accorde' then 1.week.ago.to_date
                       else 1.day.ago.to_date
                       end,
    montant_demande: montant_demande,
    montant_accorde: montant_accorde,
    document_recu: ['accorde', 'en_cours'].include?(state),
    commentaires_admin: case state
                        when 'accorde' then "Prime accordée - Tous documents conformes"
                        when 'en_cours' then "Dossier en cours d'analyse"
                        when 'incomplet' then "Documents manquants - Factures requises"
                        when 'soumis' then "Dossier soumis - En attente d'analyse"
                        when 'en_preparation' then nil
                        end,
    email_suivi: "#{state}-#{prime.slug}-#{Time.current.to_i}@tracking.example.com"
  )

  puts "  ✅ #{prime.titre}: #{state} (#{montant_demande}€#{montant_accorde ? " → #{montant_accorde}€" : ""})"
end

puts "\n🎉 Script terminé avec succès !"
puts "📊 Données créées :"
puts "  - 1 utilisateur : #{user.email}"
puts "  - 1 property : #{property.address}"
puts "  - 1 request : #{request.title}"
puts "  - 5 request_progresses avec états variés"
puts "\n💡 Vous pouvez maintenant tester l'interface du decision hub avec ces données."
