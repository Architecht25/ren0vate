# Pages officielles surveillées pour détecter un changement de réglementation
# primes/prêts avant qu'il ne se voie dans une simulation erronée.
# Voir RegulatoryWatchJob (mensuel) et RegulatoryWatchService.

RegulatorySource.find_or_initialize_by(url: "https://www.wallonie.be/fr/actualites/renovation-energetique-les-grandes-lignes-du-futur-regime-de-soutien-sont-connues").tap do |s|
  s.label = "Wallonie — Nouveau régime de soutien à la rénovation (prêt bonifié)"
  s.region = "wallonie"
  s.notes = "app/services/regions/wallonie/pret_reduction/{tranche,calculator,eligibility}_service.rb, " \
            "app/services/regions/wallonie/household_income_calculator.rb, " \
            "app/services/regions/wallonie/wallonie_regime_router.rb"
  s.active = true
  s.save!
end

RegulatorySource.find_or_initialize_by(url: "https://www.swcs.be/solutions/renover").tap do |s|
  s.label = "SWCS — Prêts rénovation (Écopack/Rénopack/Rénoprêt)"
  s.region = "wallonie"
  s.notes = "Process de dépôt/instruction/déblocage — app/models/pret_wallonie_dossier.rb, " \
            "app/controllers/pret_wallonie_dossiers_controller.rb"
  s.active = true
  s.save!
end

RegulatorySource.find_or_initialize_by(url: "https://www.vlaanderen.be/bouwen-wonen-en-energie/bouwen-en-verbouwen/premies-voor-renovatie/mijn-verbouwpremie").tap do |s|
  s.label = "Flandre — Mijn VerbouwPremie"
  s.region = "flandre"
  s.notes = "db/seeds/flandre/primes.rb (eligible_categories, valeurs_par_categorie), " \
            "app/services/regions/flandre/flandre_category_service.rb"
  s.active = true
  s.save!
end

# Bruxelles : pas de source officielle stable à ce jour — les primes Renolution
# sont supprimées (eligible: false) et le Plan social climat n'est pas publié
# (pas attendu avant 2027 selon nos dernières infos). À ajouter dès qu'une page
# officielle référence les modalités du retour partiel ciblé revenus faibles.
