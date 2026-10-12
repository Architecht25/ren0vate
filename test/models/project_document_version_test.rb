require "test_helper"

class ProjectDocumentVersionTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @document = @project.project_documents.create!(
      title: "Devis toiture", document_type: "devis", uploaded_by: @owner
    )
  end

  def attach_version!(filename: "test_devis.pdf")
    @document.versions.create!(
      created_by: @owner,
      file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/#{filename}"), "application/pdf")
    )
  end

  test "la première version porte le numéro 1 et devient la version courante" do
    version = attach_version!
    assert_equal 1, version.version_number
    assert_equal version.id, @document.reload.current_version_id
  end

  test "une nouvelle version incrémente le numéro et devient la version courante" do
    first = attach_version!
    second = attach_version!(filename: "test_facture.pdf")

    assert_equal 1, first.version_number
    assert_equal 2, second.version_number
    assert_equal second.id, @document.reload.current_version_id
  end

  test "le SHA-256 et les métadonnées du fichier sont calculés après création" do
    version = attach_version!
    version.reload

    assert version.sha256.present?
    assert_equal 64, version.sha256.length
    assert_equal "test_devis.pdf", version.file_name
    assert_equal "application/pdf", version.content_type
  end

  test "une version sans fichier n'est pas valide" do
    version = @document.versions.build(created_by: @owner)
    assert_not version.valid?
  end
end
