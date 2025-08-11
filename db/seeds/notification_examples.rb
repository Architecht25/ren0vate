# Seeds pour créer des exemples de notifications
puts "🔔 Création d'exemples de notifications..."

# Récupérer le premier utilisateur pour les tests
user = User.first
unless user
  puts "❌ Aucun utilisateur trouvé. Créez d'abord un utilisateur."
  exit
end

property = user.properties.first
project = user.projects.first
simulation = user.simulations.first

created_count = 0

# 1. Notification de dossier incomplet
if property
  notification = Notification.create_dossier_incomplet(
    user,
    property,
    ["Facture entrepreneur", "Certificat PEB"]
  )
  created_count += 1
  puts "✅ Notification dossier incomplet créée"
end

# 2. Notification de facture manquante
if project
  notification = Notification.create_facture_manquante(
    user,
    project,
    "isolation de la toiture"
  )
  created_count += 1
  puts "✅ Notification facture manquante créée"
end

# 3. Deadline proche
deadline = 10.days.from_now
notification = Notification.create_deadline_proche(
  user,
  deadline,
  "soumission de votre dossier de prime RENOLUTION"
)
created_count += 1
puts "✅ Notification deadline proche créée"

# 4. Conseil d'optimisation
if simulation
  notification = Notification.create_conseil_optimisation(
    user,
    simulation,
    "En combinant l'isolation des murs avec celle de la toiture, vous pourriez économiser jusqu'à 15% sur vos travaux et augmenter vos primes de 2,500€."
  )
  created_count += 1
  puts "✅ Notification conseil d'optimisation créée"
end

# 5. Prochaine étape
notification = Notification.create_etape_suivante(
  user,
  "Contactez un entrepreneur certifié pour obtenir vos devis. Nous avons une liste d'entrepreneurs partenaires dans votre région."
)
created_count += 1
puts "✅ Notification étape suivante créée"

# 6. Document requis
prime = Prime.where(region: "bruxelles").first
if prime
  notification = Notification.create_document_requis(
    user,
    prime,
    "Attestation entrepreneur signée et datée"
  )
  created_count += 1
  puts "✅ Notification document requis créée"
end

# 7. Simulation va expirer
if simulation
  notification = Notification.create_simulation_expiration(
    user,
    simulation,
    12
  )
  created_count += 1
  puts "✅ Notification simulation expiration créée"
end

# 8. Nouvelle prime éligible
if prime
  notification = Notification.create_prime_eligible(
    user,
    prime,
    "Suite à l'analyse de votre profil, vous êtes maintenant éligible à cette prime suite aux nouveaux critères 2025."
  )
  created_count += 1
  puts "✅ Notification prime éligible créée"
end

# 9. Vérification requise
notification = Notification.create_verification_requise(
  user,
  "vos informations de contact",
  "Votre numéro de téléphone semble incomplet dans votre profil."
)
created_count += 1
puts "✅ Notification vérification requise créée"

# 10. Suivi de projet
if project
  notification = Notification.create_suivi_projet(
    user,
    project,
    "Vos travaux d'isolation sont maintenant terminés. N'oubliez pas de télécharger vos factures finales pour compléter votre dossier de prime."
  )
  created_count += 1
  puts "✅ Notification suivi projet créée"
end

# Notifications admin d'exemple
puts "\n📢 Création de notifications admin d'exemple..."

# Notification légale
Notification.create_admin_notification(
  type: :admin_legal,
  title: "Mise à jour réglementaire - Primes RENOLUTION 2025",
  message: "📋 De nouveaux critères d'éligibilité entrent en vigueur le 1er mars 2025 pour les primes d'isolation. Les seuils de revenus ont été ajustés. Consultez votre simulateur pour vérifier votre éligibilité.",
  category: :legal,
  priority: :haute,
  target_users: User.where(region: "bruxelles"),
  expires_at: 60.days.from_now
)
created_count += 1
puts "✅ Notification admin légale créée"

# Nouvelle prime
if prime
  Notification.create_admin_notification(
    type: :admin_nouvelle_prime,
    title: "🎉 Nouvelle prime pompe à chaleur disponible !",
    message: "Une nouvelle prime pour les pompes à chaleur air-eau est maintenant disponible en région bruxelloise. Montant jusqu'à 4,000€ selon vos revenus. Vérifiez votre éligibilité dès maintenant !",
    category: :primes,
    priority: :normale,
    target_users: User.where(region: "bruxelles"),
    expires_at: 90.days.from_now
  )
  created_count += 1
  puts "✅ Notification admin nouvelle prime créée"
end

# Maintenance
Notification.create_admin_notification(
  type: :admin_maintenance,
  title: "Maintenance programmée - Simulateur de primes",
  message: "🔧 Une maintenance du simulateur de primes est prévue le dimanche 25 août de 2h à 6h du matin. Le service sera temporairement indisponible. Nous nous excusons pour la gêne occasionnée.",
  category: :maintenance,
  priority: :normale,
  expires_at: 30.days.from_now
)
created_count += 1
puts "✅ Notification admin maintenance créée"

# Notification urgente
Notification.create_admin_notification(
  type: :admin_urgent,
  title: "⚠️ URGENT - Modification temporaire des délais",
  message: "En raison d'un afflux important de demandes, les délais de traitement des dossiers de primes sont temporairement étendus à 45 jours ouvrables. Nous mettons tout en œuvre pour traiter votre dossier dans les meilleurs délais.",
  category: :systeme,
  priority: :critique,
  expires_at: 15.days.from_now
)
created_count += 1
puts "✅ Notification admin urgente créée"

puts "\n🎯 Résumé:"
puts "   ✅ #{created_count} notifications d'exemple créées"
puts "   👤 Utilisateur: #{user.email}"
puts "   📊 Total notifications: #{Notification.count}"

puts "\n🔗 Accédez aux notifications via: /notifications"
puts "📱 Testez les fonctionnalités:"
puts "   - Marquer comme lu"
puts "   - Filtrer par type/catégorie"
puts "   - Actions rapides"
