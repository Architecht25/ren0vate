require "test_helper"

# Test terrain simulé — parcours architecte (protocole_test_utilisateur_pro.md §2).
# Rejoue les 7 tâches du scénario "Architecte" sur un chantier fictif, en ActionDispatch::
# IntegrationTest (Selenium indisponible en local, cf. CLAUDE.md) pour détecter les frictions
# avant une session réelle avec un pro. Même structure que entrepreneur_pro_smoke_test.rb.
class ArchitecteProSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @client = User.create!(
      email: "client.fictif.architecte@example.com", password: "password123",
      nom: "Dupont", role: 0, onboarding_completed_at: 1.day.ago
    )
    @property = @client.properties.create!(
      titre: "Maison Dupont", rue: "Rue de la Rénovation", numero: "12",
      code_postal: "4000", commune: "Liège", region: "wallonie",
      skip_onboarding_validation: true
    )
    @project = Project.create!(
      user: @client, property: @property, nom: "Rénovation toiture Dupont", statut: "en_cours"
    )

    @architecte = User.create!(
      email: "architecte.fictif@example.com", password: "password123",
      nom: "Moreau", role: 0, professional_type: "architect",
      onboarding_completed_at: 1.day.ago
    )
    @membership = ProjectMember.create!(
      project: @project, user: @architecte, role: "architect", status: "pending"
    )
    @membership.accept! # pas juste "pending" — cf. protocole §0

    sign_in @architecte
  end

  # 1. Retrouver l'état d'avancement global du chantier depuis l'accueil de sa vue.
  test "1 - accueil vue pro affiche l'avancement du chantier" do
    get pro_view_project_path(@project, locale: :fr)
    assert_response :success
    assert_match @project.name, @response.body
  end

  # 2. Consulter/déposer un plan et un document de permis d'urbanisme.
  test "2 - upload d'un plan et d'un document de permis d'urbanisme" do
    plan = fixture_file_upload("test_devis.pdf", "application/pdf")
    assert_difference "Document.count", 1 do
      post upload_document_pro_project_path(@project, locale: :fr), params: {
        type_document: "plan", document_file: plan, description: "Plan façade"
      }
    end
    assert_response :redirect
    assert_equal "plan", Document.order(:created_at).last.type_document

    permis = fixture_file_upload("test_facture.pdf", "application/pdf")
    assert_difference "Document.count", 1 do
      post upload_document_pro_project_path(@project, locale: :fr), params: {
        type_document: "permis_urbanisme", document_file: permis
      }
    end
    assert_response :redirect
    assert_equal "permis_urbanisme", Document.order(:created_at).last.type_document
  end

  # 3. Mettre à jour le statut du permis (stepper à_déposer/en_cours/obtenu).
  test "3 - mise à jour du statut du permis d'urbanisme" do
    patch update_permis_pro_project_path(@project, locale: :fr), params: {
      project: { permis_urbanisme_statut: "a_deposer" }
    }
    assert_response :redirect
    assert_equal "a_deposer", @project.reload.permis_urbanisme_statut

    patch update_permis_pro_project_path(@project, locale: :fr), params: {
      project: { permis_urbanisme_statut: "en_cours" }
    }
    @project.reload
    assert_equal "en_cours", @project.permis_urbanisme_statut
    assert_equal 2, @project.permis_urbanisme_historique.size

    patch update_permis_pro_project_path(@project, locale: :fr), params: {
      project: { permis_urbanisme_statut: "obtenu" }
    }
    assert_equal "obtenu", @project.reload.permis_urbanisme_statut
  end

  # 4. Déposer ou consulter le métré.
  test "4 - upload du métré" do
    metre = fixture_file_upload("test_photo.jpg", "image/jpeg")
    assert_difference "Document.count", 1 do
      post upload_document_pro_project_path(@project, locale: :fr), params: {
        type_document: "metre", document_file: metre
      }
    end
    assert_response :redirect
    assert_equal "metre", Document.order(:created_at).last.type_document
  end

  # 5. Valider une phase de chantier (préparation, démolition…).
  test "5 - validation d'une phase de chantier" do
    patch validate_phase_project_path(@project, locale: :fr), params: { phase_key: "phase_demolition" }
    assert_response :redirect
    @project.reload
    assert @project.phases_avancement.dig("phase_demolition", "architect").present?
  end

  # 6. Ouvrir l'assistant IA et poser une question métier réelle.
  test "6 - assistant IA contextualisé répond sur le chantier" do
    post api_contextual_bot_chat_path(locale: :fr), params: {
      message: "Quelles primes pour ce chantier ?",
      current_page: "pro_view",
      mode: "expert",
      property_id: @project.id.to_s,
      pro_role: "architect"
    }, as: :json
    assert_response :success
    body = JSON.parse(@response.body)
    assert body["response"]["content"].present?
  end

  # 7. Créer ou consulter un PV de réception.
  test "7 - création d'un PV de réception" do
    assert_difference "PvReception.count", 1 do
      post project_pv_reception_path(@project, locale: :fr), params: {
        pv_reception: {
          date_reception: Date.current, meteo: "Ensoleillé",
          presents: "M. Dupont, M. Moreau (architecte)"
        }
      }
    end
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  # Rejoue l'ensemble du scénario dans l'ordre, puis revérifie l'accueil : un pro réel
  # enchaîne ces actions sur le même chantier, pas en isolation comme les tests 1-7 ci-dessus.
  test "8 - la vue pro se réaffiche sans erreur une fois le chantier rempli (scénario complet)" do
    post upload_document_pro_project_path(@project, locale: :fr), params: {
      type_document: "plan", document_file: fixture_file_upload("test_devis.pdf", "application/pdf")
    }
    post upload_document_pro_project_path(@project, locale: :fr), params: {
      type_document: "permis_urbanisme", document_file: fixture_file_upload("test_facture.pdf", "application/pdf")
    }
    patch update_permis_pro_project_path(@project, locale: :fr), params: {
      project: { permis_urbanisme_statut: "en_cours" }
    }
    post upload_document_pro_project_path(@project, locale: :fr), params: {
      type_document: "metre", document_file: fixture_file_upload("test_photo.jpg", "image/jpeg")
    }
    patch validate_phase_project_path(@project, locale: :fr), params: { phase_key: "phase_preparation" }
    patch validate_phase_project_path(@project, locale: :fr), params: { phase_key: "phase_demolition" }
    post project_pv_reception_path(@project, locale: :fr), params: {
      pv_reception: { date_reception: Date.current }
    }

    get pro_view_project_path(@project, locale: :fr)
    assert_response :success
  end
end
