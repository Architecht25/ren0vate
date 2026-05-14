class Admin::ArticlesController < AdminController
  before_action :ensure_admin
  before_action :set_article, only: [:show, :edit, :update, :destroy, :publish, :unpublish]

  def index
    @published = Article.published
    @drafts    = Article.drafts.order(created_at: :desc)
  end

  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)
    if @article.save
      redirect_to admin_articles_path, notice: "Article créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @article.update(article_params)
      redirect_to admin_articles_path, notice: "Article mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to admin_articles_path, notice: "Article supprimé."
  end

  def publish
    @article.update(published_at: Time.current)
    redirect_to admin_articles_path, notice: "\"#{@article.title}\" publié."
  end

  def unpublish
    @article.update(published_at: nil)
    redirect_to admin_articles_path, notice: "\"#{@article.title}\" dépublié."
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(
      :title, :slug, :excerpt, :content, :category,
      :meta_description, :author, :reading_time_minutes
    )
  end
end
