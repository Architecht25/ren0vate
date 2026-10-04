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

class SupportTicketsAdminNotificationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  setup do
    @user  = users(:freemium_user)
    @admin = users(:individual_user)
    @admin.update_columns(role: User.roles[:admin])
    sign_in @user
  end

  def create_ticket(priority: "normal")
    post support_tickets_path(locale: :fr), params: {
      support_ticket: {
        subject: "Bug sur le simulateur", category: "technique", priority: priority,
        initial_message: "Le simulateur plante à l'étape 2."
      }
    }
  end

  test "la création d'un ticket crée une notification in-app pour chaque admin" do
    assert_difference -> { Notification.admin_nouveau_ticket.where(user: @admin).count }, 1 do
      create_ticket
    end
    notification = Notification.admin_nouveau_ticket.find_by!(user: @admin)
    assert_equal "haute", notification.priority
    assert_match SupportTicket.last.id.to_s, notification.title
  end

  test "un ticket urgent crée une notification critique" do
    create_ticket(priority: "urgent")
    assert_equal "critique", Notification.admin_nouveau_ticket.find_by!(user: @admin).priority
  end

  test "la notification de ticket ne déclenche pas d'email supplémentaire" do
    ActionMailer::Base.deliveries.clear
    perform_enqueued_jobs { create_ticket }

    notification_mails = ActionMailer::Base.deliveries.select { |m| m.subject.to_s.start_with?("[Ren0vate] Nouveau ticket") }
    assert_empty notification_mails
    assert_equal 1, ActionMailer::Base.deliveries.count { |m| m.subject.to_s.include?("Nouveau ticket") }
  end
end

class SupportTicketsProUserSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  %w[architect entrepreneur intermediary].each do |pro_type|
    test "un pro (#{pro_type}) peut créer un ticket de support" do
      user = users(:freemium_user)
      user.update_columns(professional_type: pro_type)
      sign_in user

      get support_tickets_path(locale: :fr)
      assert_response :success

      assert_difference "SupportTicket.count", 1 do
        post support_tickets_path(locale: :fr), params: {
          support_ticket: {
            subject: "Question sur un client", category: "general", priority: "normal",
            initial_message: "Comment inviter un client sur un projet ?"
          }
        }
      end
      assert_equal user, SupportTicket.last.user
    end
  end
end
