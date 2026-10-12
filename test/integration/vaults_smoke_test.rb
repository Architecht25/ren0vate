require "test_helper"

class VaultsSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:one)

    @plan = @project.project_documents.create!(title: "Plan as-built", document_type: "plan", visibility: "all", uploaded_by: @owner)
    @plan.versions.create!(created_by: @owner, file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test_devis.pdf"), "application/pdf"))

    @private_garantie = @project.project_documents.create!(title: "Garantie privée", document_type: "certificat_garantie", visibility: "private", uploaded_by: @owner)
    @private_garantie.versions.create!(created_by: @owner, file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test_devis.pdf"), "application/pdf"))

    # Hors liste VAULT_DOCUMENT_TYPES — ne doit jamais apparaître dans le coffre-fort.
    @devis = @project.project_documents.create!(title: "Devis", document_type: "devis", visibility: "all", uploaded_by: @owner)

    # Document V1 (base documentaire historique, distincte de ProjectDocument)
    # — le coffre-fort doit aussi l'agréger, voir #vault_documents.
    @legacy_attestation = Document.new(
      project: @project, user: @owner, type_document: "attestation_conformite", status: "approved"
    )
    @legacy_attestation.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_devis.pdf")),
      filename: "attestation-electrique.pdf", content_type: "application/pdf"
    )
    @legacy_attestation.save!
  end

  test "la page s'affiche avec les documents éligibles du propriétaire, V1 et V2 confondus" do
    sign_in @owner
    get project_vault_path(@project, locale: :fr)
    assert_response :success
    assert_select "a", text: "Plan as-built"
    assert_select "a", text: "Garantie privée"
    assert_select "a", text: "Devis", count: 0
    assert_select "a", text: "attestation-electrique.pdf"
  end

  test "l'export ZIP ne contient que les documents que l'entrepreneur a le droit de voir" do
    roofer = User.create!(email: "roofer_vault@example.com", password: "password123", nom: "Couvreur")
    roofer.update_column(:onboarding_completed_at, 1.day.ago)
    @project.project_members.create!(user: roofer, role: "entrepreneur", status: "active")
    sign_in roofer

    get project_vault_export_path(@project, locale: :fr)
    assert_response :success

    zip_entries = Zip::File.open_buffer(response.body).map(&:name)
    assert zip_entries.any? { |name| name.include?("plan-as-built") }
    assert zip_entries.none? { |name| name.include?("garantie-privee") }
    # Document V1 : aucune notion de membre/pro dans ce modèle historique,
    # seul le propriétaire du chantier y a accès (voir #vault_documents).
    assert zip_entries.none? { |name| name.include?("attestation-electrique") }
  end

  test "un document V1 n'apparaît dans le coffre-fort que pour le propriétaire, pas pour un pro" do
    roofer = User.create!(email: "roofer_vault_v1@example.com", password: "password123", nom: "Couvreur")
    roofer.update_column(:onboarding_completed_at, 1.day.ago)
    @project.project_members.create!(user: roofer, role: "entrepreneur", status: "active")
    sign_in roofer

    get project_vault_path(@project, locale: :fr)
    assert_response :success
    assert_select "a", text: "attestation-electrique.pdf", count: 0
  end

  test "l'export ZIP inclut le PV de réception généré dans l'app (bug trouvé lors du test E2E du 12/10/2026)" do
    @project.create_pv_reception!(date_reception: Date.current, presents: "Tout le monde", nom_owner: @owner.full_name, reserves_snapshot: "[]")
    sign_in @owner

    get project_vault_export_path(@project, locale: :fr)
    assert_response :success

    zip_entries = Zip::File.open_buffer(response.body).map(&:name)
    assert zip_entries.include?("pv-reception.pdf")
  end

  test "l'export ZIP inclut le PV de réception externe scanné" do
    pv = PvReception.new(project: @project, source: "externe", date_reception: Date.current)
    pv.pv_externe_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_devis.pdf")),
      filename: "pv-signe.pdf", content_type: "application/pdf"
    )
    pv.save!
    sign_in @owner

    get project_vault_export_path(@project, locale: :fr)
    assert_response :success

    zip_entries = Zip::File.open_buffer(response.body).map(&:name)
    assert zip_entries.include?("pv-reception.pdf")
  end
end
