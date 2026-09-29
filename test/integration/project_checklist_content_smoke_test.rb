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

  test "une seconde visite de l'onglet ne crée pas une seconde checklist contrat" do
    get project_path(@project, locale: :fr, tab: :preparation)
    assert_no_difference "ProjectChecklist.count" do
      get project_path(@project, locale: :fr, tab: :preparation)
    end
  end

  test "la checklist contrat n'apparaît pas dans le sélecteur d'inspection de la page réception" do
    get reception_chantier_project_path(@project, locale: :fr)
    assert_response :success
    assert_no_match(/Vérification du contrat d'entrepreneur/, response.body)
  end

  test "démarrer manuellement une inspection sur le template contrat est refusé" do
    post project_project_checklists_path(@project, locale: :fr),
         params: { checklist_template_id: @contrat_template.id }
    assert_response :not_found
  end

  test "cocher un item contrat, même depuis la carte inline, mène à la vue plein écran (notes)" do
    get project_path(@project, locale: :fr, tab: :preparation)
    project_checklist = @project.project_checklists.find_by(checklist_template: @contrat_template)
    item = project_checklist.project_checklist_items.first

    patch project_checklist_item_path(item, locale: :fr),
          params: { checked: "true" },
          headers: { "HTTP_REFERER" => project_path(@project, locale: :fr, tab: :preparation) }

    assert_redirected_to project_project_checklist_path(@project, project_checklist, locale: :fr)
  end

  test "le lien retour de la page plein écran contrat pointe vers la page projet, pas réception chantier" do
    get project_path(@project, locale: :fr, tab: :preparation)
    project_checklist = @project.project_checklists.find_by(checklist_template: @contrat_template)

    get project_project_checklist_path(@project, project_checklist, locale: :fr)
    assert_response :success
    assert_select "a[href=?]", project_path(@project, locale: :fr, tab: :preparation), minimum: 1
    assert_select "a[href=?]", reception_chantier_project_path(@project, locale: :fr, anchor: "checklists"), count: 0
  end

  test "la carte contrat ne plante pas si la checklist n'a aucun item" do
    empty_template = ChecklistTemplate.create!(name: "Contrat vide", phase: "contrat", position: 1)
    @project.project_checklists.create!(checklist_template: empty_template)
    ChecklistTemplate.where(phase: "contrat").where.not(id: empty_template.id).destroy_all

    get project_path(@project, locale: :fr, tab: :preparation)
    assert_response :success
  end
end
