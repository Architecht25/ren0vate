require "test_helper"

# Smoke tests des pages non couvertes ailleurs (properties, projects, documents,
# quotes, pricing, dashboard, notifications, categories, contract_templates,
# request_progresses, etats_avancement).
# Objectif : vérifier que les pages s'affichent sans 500 (non-régression).
class CorePagesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  setup do
    @user = users(:freemium_user)
    @user.update_column(:onboarding_completed_at, 1.day.ago)
    sign_in @user

    @property = @user.properties.create!(
      titre: "Bien test",
      rue: "Rue de Namur", numero: "1", code_postal: "5000", commune: "Namur",
      region: "wallonie", skip_onboarding_validation: true
    )
    @project = Project.create!(
      user: @user, property: @property, nom: "Projet test", statut: "en_cours"
    )
  end

  # ─── Dashboard ───────────────────────────────────────────────────────────

  test "dashboard accessible" do
    get dashboard_path(locale: :fr)
    assert_response :success
  end

  # ─── Properties ──────────────────────────────────────────────────────────

  test "liste des biens accessible" do
    get properties_path(locale: :fr)
    assert_response :success
  end

  test "nouveau bien accessible" do
    get new_property_path(locale: :fr)
    assert_response :success
  end

  test "fiche d'un bien redirige vers son dashboard" do
    get property_path(@property, locale: :fr)
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  test "édition d'un bien accessible" do
    get edit_property_path(@property, locale: :fr)
    assert_response :success
  end

  test "dashboard d'un bien accessible" do
    get dashboard_property_path(@property, locale: :fr)
    assert_response :success
  end

  test "dashboard documents d'un bien accessible" do
    get documents_dashboard_property_path(@property, locale: :fr)
    assert_response :success
  end

  test "dashboard phases documents d'un bien accessible" do
    get documents_phases_dashboard_property_path(@property, locale: :fr)
    assert_response :success
  end

  test "accès refusé à un bien d'un autre utilisateur" do
    other_user = User.create!(email: "other_prop@example.com", password: "password123", nom: "Other", role: 0)
    other_prop = other_user.properties.create!(
      titre: "Bien Other", rue: "Rue A", numero: "1", code_postal: "5000", commune: "Namur",
      region: "wallonie", skip_onboarding_validation: true
    )

    get property_path(other_prop, locale: :fr)
    assert_response :not_found
  end

  # ─── Projects ────────────────────────────────────────────────────────────

  test "liste des projets accessible" do
    get projects_path(locale: :fr)
    assert_response :success
  end

  test "nouveau projet accessible" do
    get new_project_path(locale: :fr)
    assert_response :success
  end

  test "fiche d'un projet accessible" do
    get project_path(@project, locale: :fr)
    assert_response :success
  end

  test "édition d'un projet accessible" do
    get edit_project_path(@project, locale: :fr)
    assert_response :success
  end

  # ─── Documents ───────────────────────────────────────────────────────────

  test "documents d'un bien accessible" do
    get property_documents_path(@property, locale: :fr)
    assert_response :success
  end

  test "nouveau document d'un bien accessible" do
    get new_property_document_path(@property, locale: :fr)
    assert_response :success
  end

  test "documents d'un projet accessible" do
    get project_documents_path(@project, locale: :fr)
    assert_response :success
  end

  # ─── Quotes (chiffrer mes travaux) ───────────────────────────────────────

  test "quotes d'un bien accessible" do
    get property_quotes_path(@property, locale: :fr)
    assert_response :success
  end

  test "nouveau quote accessible" do
    get new_property_quote_path(@property, locale: :fr)
    assert_response :success
  end

  test "démarrage du parcours quotes redirige vers le bien" do
    get start_quotes_path(locale: :fr)
    assert_response :redirect
    follow_redirect!
    assert_response :success
  end

  # ─── Pricing ─────────────────────────────────────────────────────────────

  test "page pricing accessible" do
    get pricing_path(locale: :fr)
    assert_response :success
  end

  # ─── Notifications ───────────────────────────────────────────────────────

  test "liste des notifications accessible" do
    get notifications_path(locale: :fr)
    assert_response :success
  end

  # ─── Categories ──────────────────────────────────────────────────────────

  test "liste des catégories accessible" do
    get categories_path(locale: :fr)
    assert_response :success
  end

  # ─── Contract templates ──────────────────────────────────────────────────
  # (couvre les deux bugs réels corrigés le 17/09/2026 : helper défini après
  # usage sur index, @templates jamais assigné sur show)

  test "liste des templates de contrats accessible" do
    get contract_templates_path(locale: :fr)
    assert_response :success
  end

  test "détail d'un template de contrat accessible" do
    get contract_template_path("architecte_mission_complete", locale: :fr)
    assert_response :success
  end

  # ─── Etats d'avancement ──────────────────────────────────────────────────

  test "liste des états d'avancement d'un projet accessible" do
    get project_etats_avancement_index_path(@project, locale: :fr)
    assert_response :success
  end

  # ─── Request progresses ──────────────────────────────────────────────────

  test "liste des suivis de demandes accessible" do
    get request_progresses_path(locale: :fr)
    assert_response :success
  end

  # ─── Non connecté ────────────────────────────────────────────────────────

  test "accès refusé au dashboard si non connecté" do
    sign_out @user
    get dashboard_path(locale: :fr)
    assert_response :redirect
  end
end
