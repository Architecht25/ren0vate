require "test_helper"

class MessageThreadsSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @owner.update_column(:onboarding_completed_at, 1.day.ago)
    @project = projects(:one)
    sign_in @owner
  end

  test "index, new et show s'affichent sans erreur" do
    get project_message_threads_path(@project, locale: :fr)
    assert_response :success

    get new_project_message_thread_path(@project, locale: :fr)
    assert_response :success

    thread = @project.message_threads.create!(title: "Test")
    get message_thread_path(thread, locale: :fr)
    assert_response :success
  end

  test "créer un fil puis y poster un message" do
    post project_message_threads_path(@project, locale: :fr), params: { message_thread: { title: "Question générale" } }
    thread = MessageThread.last
    assert_redirected_to message_thread_path(thread, locale: :fr)

    assert_difference -> { Message.count } => 1 do
      post message_thread_messages_path(thread, locale: :fr), params: { message: { body: "Bonjour" } }
    end
    assert_equal @owner, Message.last.author
  end

  test "un tiers hors chantier ne peut pas consulter le fil ni y répondre" do
    thread = @project.message_threads.create!(title: "Confidentiel")
    outsider = User.create!(email: "outsider_thread@example.com", password: "password123", nom: "Outsider")
    outsider.update_column(:onboarding_completed_at, 1.day.ago)
    sign_out @owner
    sign_in outsider

    get message_thread_path(thread, locale: :fr)
    assert_redirected_to root_path(locale: :fr)

    post message_thread_messages_path(thread, locale: :fr), params: { message: { body: "Intrusion" } }
    assert_redirected_to root_path(locale: :fr)
  end
end
