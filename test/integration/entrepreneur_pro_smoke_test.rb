require "test_helper"

# Test terrain simulé — parcours entrepreneur (protocole_test_utilisateur_pro.md §2).
# Rejoue les 7 tâches du scénario "Entrepreneur" sur un chantier fictif, en ActionDispatch::
# IntegrationTest (Selenium indisponible en local, cf. CLAUDE.md) pour détecter les frictions
# avant une session réelle avec un pro.
class EntrepreneurProSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @client = User.create!(
      email: "client.fictif.entrepreneur@example.com", password: "password123",
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

    @entrepreneur = User.create!(
      email: "entrepreneur.fictif@example.com", password: "password123",
      nom: "Lemaire", role: 0, professional_type: "entrepreneur",
      onboarding_completed_at: 1.day.ago
    )
    @membership = ProjectMember.create!(
      project: @project, user: @entrepreneur, role: "entrepreneur", status: "pending"
    )
    @membership.accept! # pas juste "pending" — cf. protocole §0

    sign_in @entrepreneur
  end

  # 1. Retrouver l'état d'avancement global du chantier depuis l'accueil de sa vue.
  test "1 - accueil vue pro affiche l'avancement du chantier" do
    get pro_view_project_path(@project, locale: :fr)
    assert_response :success
    assert_match @project.name, @response.body
  end

  # 2. Envoyer un devis (upload PDF + montant).
  test "2 - upload d'un devis PDF avec montant" do
    pdf = fixture_file_upload("test_devis.pdf", "application/pdf")
    assert_difference "Facture.count", 1 do
      post upload_facture_pro_project_path(@project, locale: :fr), params: {
        facture_pdf: pdf, type_facture: "devis", montant_ttc: "8500.50"
      }
    end
    assert_response :redirect
    facture = Facture.order(:created_at).last
    assert_equal "devis", facture.type_facture
    assert_equal 8500.50, facture.montant.to_f
  end

  # 3. Ajouter une photo de chantier liée à une phase.
  test "3 - upload d'une photo de chantier liée à une phase" do
    photo = fixture_file_upload("test_photo.jpg", "image/jpeg")
    assert_difference "Document.count", 1 do
      post upload_photo_pro_project_path(@project, locale: :fr), params: {
        photo_file: photo, phase_photo: "phase_installation"
      }
    end
    assert_response :redirect
    document = Document.order(:created_at).last
    assert_equal "phase_installation", document.phase_chantier
  end

  # 4. Ajouter une facture/acompte/solde.
  test "4 - upload d'un acompte" do
    pdf = fixture_file_upload("test_facture.pdf", "application/pdf")
    assert_difference "Facture.count", 1 do
      post upload_facture_pro_project_path(@project, locale: :fr), params: {
        facture_pdf: pdf, type_facture: "acompte", montant_ttc: "3000"
      }
    end
    assert_response :redirect
    facture = Facture.order(:created_at).last
    assert_equal "acompte", facture.type_facture
  end

  # 5. Créer un état d'avancement.
  test "5 - création d'un état d'avancement manuel" do
    assert_difference "EtatAvancement.count", 1 do
      post project_etats_avancement_index_path(@project, locale: :fr), params: {
        etat_avancement: {
          source_type: "manuel",
          date_emission: Date.current,
          commentaire_entrepreneur: "Avancement du mois"
        }
      }
    end
    assert_response :redirect
    etat = EtatAvancement.order(:created_at).last
    assert_equal "brouillon", etat.statut
    follow_redirect!
    assert_response :success
  end

  # 6. Valider une phase de chantier.
  test "6 - validation d'une phase de chantier" do
    patch validate_phase_project_path(@project, locale: :fr), params: { phase_key: "phase_preparation" }
    assert_response :redirect
    @project.reload
    assert @project.phases_avancement.dig("phase_preparation", "entrepreneur").present?
  end

  # 7. Ouvrir l'assistant IA et poser une question métier réelle.
  test "7 - assistant IA contextualisé répond sur le chantier" do
    post api_contextual_bot_chat_path(locale: :fr), params: {
      message: "Quels sont les délais légaux de paiement en Belgique ?",
      current_page: "pro_view",
      mode: "expert",
      property_id: @project.id.to_s,
      pro_role: "entrepreneur"
    }, as: :json
    assert_response :success
    body = JSON.parse(@response.body)
    assert body["response"]["content"].present?
  end

  # Rejoue l'ensemble du scénario dans l'ordre, puis revérifie l'accueil : un pro réel
  # enchaîne ces actions sur le même chantier, pas en isolation comme les tests 1-7 ci-dessus.
  test "8 - la vue pro se réaffiche sans erreur une fois le chantier rempli (scénario complet)" do
    post upload_facture_pro_project_path(@project, locale: :fr), params: {
      facture_pdf: fixture_file_upload("test_devis.pdf", "application/pdf"),
      type_facture: "devis", montant_ttc: "8500.50"
    }
    post upload_photo_pro_project_path(@project, locale: :fr), params: {
      photo_file: fixture_file_upload("test_photo.jpg", "image/jpeg"), phase_photo: "phase_installation"
    }
    post upload_facture_pro_project_path(@project, locale: :fr), params: {
      facture_pdf: fixture_file_upload("test_facture.pdf", "application/pdf"),
      type_facture: "acompte", montant_ttc: "3000"
    }
    post project_etats_avancement_index_path(@project, locale: :fr), params: {
      etat_avancement: { source_type: "manuel", date_emission: Date.current }
    }
    patch validate_phase_project_path(@project, locale: :fr), params: { phase_key: "phase_preparation" }
    patch validate_phase_project_path(@project, locale: :fr), params: { phase_key: "phase_installation" }

    get pro_view_project_path(@project, locale: :fr)
    assert_response :success
  end
end
