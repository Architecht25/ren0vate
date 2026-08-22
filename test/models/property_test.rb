require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  fixtures :users

  setup do
    @user = users(:freemium_user)
  end

  # Régression prod 22/08/2026 : `determine_phase_category` interrogeait
  # `projects.finalite`, colonne supprimée par la migration
  # RemoveEntrepriseColumnsFromPropertiesAndProjects (fonctionnalité "Entreprises
  # Bruxelles" abandonnée) — provoquait un PG::UndefinedColumn (500) sur
  # /projects/:id/documents pour toute propriété "entreprise".
  test "determine_phase_category ne crashe pas pour une propriété entreprise" do
    property = @user.properties.create!(
      titre: "Bien Entreprise", rue: "Rue Test", numero: "1", code_postal: "1000",
      commune: "Bruxelles", region: "bruxelles", type: "entreprise", skip_onboarding_validation: true
    )

    assert_equal "chantier", property.determine_phase_category
    assert_nothing_raised { property.phases_with_status }
  end

  test "determine_phase_category renvoie chantier pour une propriété classique" do
    property = @user.properties.create!(
      titre: "Maison", rue: "Rue Test", numero: "1", code_postal: "5000",
      commune: "Namur", region: "wallonie", skip_onboarding_validation: true
    )

    assert_equal "chantier", property.determine_phase_category
  end
end
