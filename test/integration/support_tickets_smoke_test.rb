require "test_helper"

# Smoke test : la création de ticket de support doit être ouverte à tous les
# utilisateurs (freemium inclus), pas seulement aux abonnés payants — voir
# suppression de require_paid_plan! du 20/09/2026, pour centraliser toutes
# les demandes d'aide dans la file admin/support_tickets.
class SupportTicketsSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  setup do
    @user = users(:freemium_user)
    sign_in @user
  end

  test "un utilisateur freemium peut accéder à la liste de ses tickets" do
    get support_tickets_path(locale: :fr)
    assert_response :success
  end

  test "un utilisateur freemium peut accéder au formulaire de nouveau ticket" do
    get new_support_ticket_path(locale: :fr)
    assert_response :success
  end

  test "un utilisateur freemium peut créer un ticket de support" do
    assert_difference "SupportTicket.count", 1 do
      post support_tickets_path(locale: :fr), params: {
        support_ticket: {
          subject: "Question sur ma simulation", category: "general", priority: "normal",
          initial_message: "J'ai une question sur le calcul de ma prime."
        }
      }
    end
    assert_redirected_to support_ticket_path(SupportTicket.last, locale: :fr)
  end
end
