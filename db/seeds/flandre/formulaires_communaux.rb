# Seeds pour les formulaires communaux et monuments & sites - Flandre
puts "🏛️ Création des formulaires Flandre (communaux + monuments & sites)..."

# Trouver ou créer la prime régionale Flandre de référence
flandre_prime = Prime.find_by(region: 'flandre', slug: 'prime_regionale_flandre') ||
                Prime.create!(
                  titre: "Prime régionale Flandre (référence formulaires)",
                  conseil: "Prime de référence pour les formulaires communaux et monuments & sites",
                  region: 'flandre',
                  slug: 'prime_regionale_flandre',
                  type_de_valeur: 'forfait',
                  unite: 'euro'
                )

# 1. FORMULAIRE MONUMENTS & SITES
puts "📋 Création du formulaire Monuments & Sites..."

monuments_form = PrimeDocumentTemplate.find_or_initialize_by(
  prime: flandre_prime,
  type_document: 'formulaire_monuments_sites',
  region: 'flandre'
)

if monuments_form.new_record?
  monuments_form.assign_attributes(
    title: "Demande de prime patrimoine - Onroerend Erfgoed",
    description: "Formulaire officiel pour les demandes de primes de restauration de monuments et sites classés en Flandre. Géré par l'agence Onroerend Erfgoed.",
    is_required: true,
    order_position: 1,
    is_external_form: true,
    external_url: "https://loket.onroerenderfgoed.be/aanvragen/premies/",
    contact_info: {
      website: "https://www.onroerenderfgoed.be",
      email: "info@onroerenderfgoed.be",
      phone: "+32 2 553 16 50"
    }.to_json
  )

  if monuments_form.save
    puts "  ✅ Formulaire Monuments & Sites créé"
  else
    puts "  ❌ Erreur: #{monuments_form.errors.full_messages.join(', ')}"
  end
else
  puts "  ⏭️  Formulaire Monuments & Sites existe déjà"
end

# 2. FORMULAIRES COMMUNAUX - ÉCHANTILLON INITIAL
puts "🏘️ Création des premiers formulaires communaux..."

sample_communes = [
  {
    name: "Antwerpen",
    postal_codes: ["2000", "2018", "2020", "2030"],
    url: "https://www.antwerpen.be/nl/info/52da4497b56e38600d78c1b7/premies-en-leningen-voor-wonen",
    has_form: true
  },
  {
    name: "Gent",
    postal_codes: ["9000", "9030", "9031", "9032"],
    url: "https://stad.gent/nl/wonen-bouwen/subsidies-en-premies",
    has_form: true
  },
  {
    name: "Brugge",
    postal_codes: ["8000", "8200"],
    url: "https://www.brugge.be/wonen-en-bouwen/premies-en-subsidies",
    has_form: true
  },
  {
    name: "Leuven",
    postal_codes: ["3000"],
    url: "https://www.leuven.be/premies-en-subsidies",
    has_form: true
  },
  {
    name: "Hasselt",
    postal_codes: ["3500"],
    url: "https://www.hasselt.be/premies",
    has_form: false # Exemple de commune sans formulaire spécifique
  }
]

created_count = 0
skipped_count = 0

sample_communes.each do |commune_data|
  next unless commune_data[:has_form] # Skip communes sans formulaire

  commune_form = PrimeDocumentTemplate.find_or_initialize_by(
    prime: flandre_prime,
    type_document: 'formulaire_communal',
    commune_name: commune_data[:name],
    region: 'flandre'
  )

  if commune_form.new_record?
    commune_form.assign_attributes(
      title: "Formulaires communaux - #{commune_data[:name]}",
      description: "Formulaires et informations sur les primes communales disponibles à #{commune_data[:name]}. Complémentaires aux primes régionales flamandes.",
      is_required: false,
      order_position: 2,
      is_external_form: true,
      external_url: commune_data[:url],
      postal_codes: commune_data[:postal_codes].to_json,
      contact_info: {
        commune: commune_data[:name],
        website: commune_data[:url],
        note: "Consultez le site pour les conditions spécifiques et montants"
      }.to_json
    )

    if commune_form.save
      created_count += 1
      puts "  ✅ #{commune_data[:name]} - Formulaire communal créé"
    else
      puts "  ❌ #{commune_data[:name]} - Erreur: #{commune_form.errors.full_messages.join(', ')}"
    end
  else
    skipped_count += 1
    puts "  ⏭️  #{commune_data[:name]} - Formulaire communal existe déjà"
  end
end

puts "\n📊 Résumé :"
puts "   Formulaires communaux créés: #{created_count}"
puts "   Formulaires communaux existants: #{skipped_count}"
puts "   Formulaire monuments & sites: 1"

puts "\n🎯 Pour ajouter d'autres communes, utilisez :"
puts "   PrimeDocumentTemplate.create!("
puts "     prime: Prime.find_by(slug: 'prime_regionale_flandre'),"
puts "     type_document: 'formulaire_communal',"
puts "     title: 'Formulaires communaux - [COMMUNE]',"
puts "     commune_name: '[COMMUNE]',"
puts "     postal_codes: '[\"CODE1\", \"CODE2\"]',"
puts "     region: 'flandre',"
puts "     is_external_form: true,"
puts "     external_url: '[URL_COMMUNE]'"
puts "   )"

puts "\n✨ Formulaires Flandre initialisés avec succès !"
