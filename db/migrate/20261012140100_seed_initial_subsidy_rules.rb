# V2 — Lot 3 : première version des règles de primes, insérée en donnée
# (pas en seed, cf. feedback_seed_data_not_autorun_on_deploy — le Procfile
# release ne lance que db:migrate, jamais db:seed). Toute réforme future
# est une NOUVELLE migration de données qui ferme l'ancienne version
# (valid_to) et insère la nouvelle (valid_from) — jamais une modification
# en place d'une ligne existante.
#
# IMPORTANT — portée volontairement partielle (voir docs/PLAN_V2.md Lot 3
# et docs/QUESTIONS_OUVERTES.md) :
# - Les CONDITIONS d'éligibilité Wallonie et Flandre sont fidèlement
#   reprises de Regions::Wallonie::WallonieEligibilityService et
#   Regions::Flandre::FlandreEligibilityService (V1) telles que lues dans
#   l'audit — mais ce ne sont qu'UNE règle par région (démonstration du
#   mécanisme), pas le catalogue complet des primes existantes.
# - Les MONTANTS (amount_formula) sont des PLACEHOLDERS — le taux/plafond
#   réel n'a pas été vérifié avec le barème officiel. Ne jamais citer ces
#   montants à un client avant confirmation (voir Q14 dans
#   docs/QUESTIONS_OUVERTES.md).
# - Bruxelles n'a volontairement AUCUNE règle générale de rénovation
#   active : Regions::Bruxelles::BruxellesEligibilityService (V1) confirme
#   qu'aucune prime générale n'est ouverte depuis la suppression de
#   Renolution (fin 2024) — l'absence de règle est donc le comportement
#   correct, pas un oubli (voir CLAUDE.md "primes Renolution supprimées").
#
# PIÈGE DÉCOUVERT EN ÉCRIVANT CE LOT : `db:schema:load`/`db:test:prepare`
# (utilisés par la CI, voir .github/workflows/ci.yml, et par tout nouveau
# clone/environnement qui ne fait pas un `db:migrate` complet depuis zéro)
# reconstruisent la base depuis db/schema.rb SANS exécuter le code Ruby
# `up` des migrations — donc sans les INSERT ci-dessous, même si
# `schema_migrations` marque cette migration comme appliquée. Seul
# `db:migrate` (utilisé en production via le Procfile release) exécute
# réellement ce seed. Les tests de référence par région
# (test/integration/subsidy_simulations_smoke_test.rb) recréent donc ces
# mêmes règles dans leur `setup`, par prudence — à garder synchronisé si
# cette migration change.
class SeedInitialSubsidyRules < ActiveRecord::Migration[8.1]
  def up
    SubsidyRule.create!(
      region: "wallonie",
      key: "primes_renovation_generale",
      label: "Primes rénovation (régime cash, Wallonie)",
      valid_from: Date.new(2026, 1, 1),
      conditions: [
        { "field" => "property.region", "operator" => "eq", "value" => "wallonie" },
        { "field" => "property.habitation_percentage", "operator" => "gte", "value" => 50 },
        { "field" => "household.is_owner", "operator" => "eq", "value" => true },
        { "field" => "property.is_main_residence", "operator" => "eq", "value" => true },
        { "field" => "property.age_years", "operator" => "gte", "value" => 15 }
      ],
      amount_formula: { "type" => "percentage", "base_field" => "travaux.montant_ttc", "rate" => 25, "max" => 2500 }
    )

    SubsidyRule.create!(
      region: "flandre",
      key: "mijn_verbouwpremie",
      label: "Mijn VerbouwPremie (Flandre)",
      valid_from: Date.new(2026, 3, 1), # réforme flamande du 01/03/2026 (usage résidentiel exclusif)
      conditions: [
        { "field" => "property.habitation_percentage", "operator" => "eq", "value" => 100 },
        { "field" => "household.ownership_percentage", "operator" => "gte", "value" => 1 },
        { "field" => "property.year_built", "operator" => "lt", "value" => 2006 }
      ],
      amount_formula: { "type" => "percentage", "base_field" => "travaux.montant_ttc", "rate" => 20, "max" => 3000 }
    )
  end

  def down
    SubsidyRule.where(region: "wallonie", key: "primes_renovation_generale").destroy_all
    SubsidyRule.where(region: "flandre", key: "mijn_verbouwpremie").destroy_all
  end
end
