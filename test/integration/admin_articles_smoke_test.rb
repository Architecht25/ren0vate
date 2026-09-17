require "test_helper"

# Smoke tests de la gestion admin du blog.
# Couvre la régression du 18/09/2026 : before_action :set_article référençait
# :show dans only: alors que l'action n'existe pas sur le controller — Rails 7.1
# (raise_on_missing_callback_actions) faisait planter TOUTE requête vers ce
# controller (AbstractController::ActionNotFound), jamais visible au boot.
class AdminArticlesSmokeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  fixtures :users

  setup do
    admin_email = ENV.fetch("ADMIN_2FA_BYPASS_EMAIL", "robin@primes-services.be")
    @admin = User.create!(email: admin_email, password: "password123", nom: "Admin", role: :admin)
    @user  = users(:freemium_user)
    @article = Article.create!(
      title: "Article test", slug: "article-test", excerpt: "Extrait",
      content: "Contenu", category: "conseils"
    )
  end

  test "liste des articles accessible à un admin" do
    sign_in @admin
    get admin_articles_path(locale: :fr)
    assert_response :success
  end

  test "nouvel article accessible à un admin" do
    sign_in @admin
    get new_admin_article_path(locale: :fr)
    assert_response :success
  end

  test "édition d'un article accessible à un admin" do
    sign_in @admin
    get edit_admin_article_path(@article, locale: :fr)
    assert_response :success
  end

  test "publication d'un article" do
    sign_in @admin
    post publish_admin_article_path(@article, locale: :fr)
    assert_redirected_to admin_articles_path(locale: :fr)
    assert @article.reload.published_at.present?
  end

  test "dépublication d'un article" do
    @article.update!(published_at: Time.current)
    sign_in @admin
    post unpublish_admin_article_path(@article, locale: :fr)
    assert_redirected_to admin_articles_path(locale: :fr)
    assert_nil @article.reload.published_at
  end

  test "refusée à un utilisateur non admin" do
    sign_in @user
    get admin_articles_path(locale: :fr)
    assert_redirected_to root_path(locale: :fr)
  end
end
