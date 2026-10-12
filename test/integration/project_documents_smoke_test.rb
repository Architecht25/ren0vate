require "test_helper"

# Smoke tests de la base documentaire versionnée V2 (Lot 1).
# Objectif : vérifier que les pages s'affichent sans 500 (non-régression),
# et que le dépôt d'un document crée bien une version avec fichier attaché.
class ProjectDocumentsSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:one)
    sign_in @owner
  end

  test "index s'affiche sans erreur" do
    get project_project_documents_path(@project, locale: :fr)
    assert_response :success
  end

  test "new s'affiche sans erreur" do
    get new_project_project_document_path(@project, locale: :fr)
    assert_response :success
  end

  test "créer un document avec un fichier fonctionne de bout en bout" do
    assert_difference -> { ProjectDocument.count } => 1, -> { ProjectDocumentVersion.count } => 1 do
      post project_project_documents_path(@project, locale: :fr), params: {
        project_document: {
          title: "Devis toiture",
          document_type: "devis",
          visibility: "all",
          versions_attributes: { "0" => { file: fixture_file_upload("test_devis.pdf", "application/pdf") } }
        }
      }
    end

    document = ProjectDocument.last
    assert_redirected_to project_document_path(document, locale: :fr)
    assert document.current_version.present?
    assert document.current_version.file.attached?
  end

  test "show s'affiche sans erreur pour le propriétaire" do
    document = @project.project_documents.create!(title: "Plan", document_type: "plan", uploaded_by: @owner)

    get project_document_path(document, locale: :fr)
    assert_response :success
  end

  test "supprimer un document ayant une version ne lève pas de violation de clé étrangère" do
    document = @project.project_documents.create!(
      title: "À supprimer", document_type: "plan", uploaded_by: @owner,
      versions_attributes: [{ created_by: @owner, file: fixture_file_upload("test_devis.pdf", "application/pdf") }]
    )
    assert document.current_version.present?

    delete project_document_path(document, locale: :fr)

    assert_redirected_to project_project_documents_path(@project, locale: :fr)
    assert_nil ProjectDocument.find_by(id: document.id)
    assert_nil ProjectDocumentVersion.find_by(id: document.current_version_id)
  end

  test "un utilisateur hors chantier ne peut pas voir un document privé" do
    document = @project.project_documents.create!(title: "Confidentiel", document_type: "autre", visibility: "private", uploaded_by: @owner)
    outsider = User.create!(email: "outsider_smoke@example.com", password: "password123", nom: "Outsider")
    sign_out @owner
    sign_in outsider

    get project_document_path(document, locale: :fr)
    assert_redirected_to root_path(locale: :fr)
  end
end
