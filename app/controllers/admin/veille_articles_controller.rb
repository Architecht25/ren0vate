class Admin::VeilleArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_article, only: %i[show edit update destroy toggle_active]

  def index
    @articles = VeilleArticle.recent.all
    @stats = {
      total:  VeilleArticle.count,
      active: VeilleArticle.active.count
    }
  end

  def show
  end

  def new
    @article = VeilleArticle.new(source_date: Date.today, region: "belgique", active: true)
  end

  def edit
  end

  def create
    @article = VeilleArticle.new(article_params)
    if @article.save
      redirect_to admin_veille_articles_path, notice: "Article ajouté à la veille."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @article.update(article_params)
      redirect_to admin_veille_articles_path, notice: "Article mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy
    redirect_to admin_veille_articles_path, notice: "Article supprimé."
  end

  def toggle_active
    @article.update!(active: !@article.active)
    redirect_back fallback_location: admin_veille_articles_path
  end

  private

  def set_article
    @article = VeilleArticle.find(params[:id])
  end

  def ensure_admin
    redirect_to root_path, alert: "Accès réservé aux administrateurs." unless current_user.admin?
  end

  def article_params
    params.require(:veille_article).permit(
      :titre, :source, :source_date, :region, :contenu, :admin_notes, :active, themes_list: []
    ).tap do |p|
      p[:themes] = p.delete(:themes_list)&.reject(&:blank?)&.join(", ") if p.key?(:themes_list)
    end
  end
end
