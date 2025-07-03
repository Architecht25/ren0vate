puts "🔢 Création des catégories..."

Category.find_or_create_by!(
  code: "categorie_4",
  description: "Revenus très faibles",
  seuil_seul: 24230,
  seuil_seul_avec_charge: 36340,
  couple_sans_charge: 36340,
  increment_par_personne: 4320,
  autre_bien_interdit: true,
  location_sociale_autorisee: true,
  eligible_pour_verbouwlening: true
)

Category.find_or_create_by!(
  code: "categorie_3",
  description: "Revenus faibles",
  seuil_seul: 42340,
  seuil_seul_avec_charge: 59270,
  couple_sans_charge: 59270,
  increment_par_personne: 4320,
  autre_bien_interdit: true,
  location_sociale_autorisee: false,
  eligible_pour_verbouwlening: true
)

Category.find_or_create_by!(
  code: "categorie_2",
  description: "Revenus moyens",
  seuil_seul: 53880,
  seuil_seul_avec_charge: 76980,
  couple_sans_charge: 76980,
  increment_par_personne: 4320,
  autre_bien_interdit: true,
  location_sociale_autorisee: true,
  eligible_pour_verbouwlening: true
)

Category.find_or_create_by!(
  code: "categorie_1",
  description: "Revenus élevés",
  seuil_seul: 500000,
  seuil_seul_avec_charge: 500000,
  couple_sans_charge: 500000,
  increment_par_personne: 4320,
  autre_bien_interdit: false,
  location_sociale_autorisee: false,
  eligible_pour_verbouwlening: false
)
