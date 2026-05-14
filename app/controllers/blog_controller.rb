class BlogController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @articles = Article.published
    @articles = @articles.by_category(params[:category]) if params[:category].present?
    @categories = Article::CATEGORIES
    @current_category = params[:category]
  end

  def show
    @article = Article.published.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to blog_index_path, alert: "Article introuvable."
  end
end
