require "test_helper"

class ProjectDocumentTranslateSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects, :subscriptions

  test "l'endpoint translate répond en JSON sans planter sans clé API" do
    owner = users(:individual_user)
    owner.update_column(:onboarding_completed_at, 1.day.ago)
    project = projects(:two)
    document = project.project_documents.create!(title: "Devis", document_type: "devis", uploaded_by: owner)
    document.versions.create!(created_by: owner, file: Rack::Test::UploadedFile.new(Rails.root.join("test/fixtures/files/test_devis.pdf"), "application/pdf"))

    sign_in owner
    get translate_project_document_path(document, locale: :fr), params: { target_locale: "nl" }

    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("translation")
  end
end
