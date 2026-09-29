require "test_helper"

# Smoke test : checklist "Vérification du contrat d'entrepreneur" (onglet Budget, devis
# et contrats) et enrichissement du template "Réception provisoire".
class ProjectChecklistContentSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update_column(:onboarding_completed_at, 1.day.ago)
    sign_in @user

    @property = @user.properties.create!(
      titre: "Bien test", rue: "Rue de Namur", numero: "1", code_postal: "5000", commune: "Namur",
      region: "wallonie", skip_onboarding_validation: true
    )
    @project = Project.create!(user: @user, property: @property, nom: "Projet test", statut: "en_cours")

    @contrat_template = ChecklistTemplate.find_or_create_by!(name: "Vérification du contrat d'entrepreneur", phase: "contrat") do |t|
      t.position = 0
    end
    ChecklistItem.find_or_create_by!(checklist_template: @contrat_template, description: "Numéro BCE de l'entrepreneur vérifié et actif") do |i|
      i.required = true
      i.position = 1
    end
  end

  test "onglet préparation affiche la checklist contrat sans erreur" do
    get project_path(@project, locale: :fr, tab: :preparation)
    assert_response :success
    assert_select "h5", text: /Vérification du contrat d'entrepreneur/
  end

  test "la checklist contrat est créée automatiquement pour le projet" do
    assert_difference "ProjectChecklist.count", 1 do
      get project_path(@project, locale: :fr, tab: :preparation)
    end
    assert @project.project_checklists.exists?(checklist_template: @contrat_template)
  end

  test "coche un item de la checklist contrat" do
    get project_path(@project, locale: :fr, tab: :preparation)
    project_checklist = @project.project_checklists.find_by(checklist_template: @contrat_template)
    item = project_checklist.project_checklist_items.first

    patch project_checklist_item_path(item, locale: :fr), params: { checked: "true" }
    assert_response :redirect

    assert item.reload.checked?
  end
end
