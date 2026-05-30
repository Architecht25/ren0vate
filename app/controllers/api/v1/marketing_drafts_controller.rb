class Api::V1::MarketingDraftsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_agent!

  def create
    week_of = params[:week_of].presence || abort_with("week_of manquant")

    week = MarketingWeek.find_or_initialize_by(week_of: week_of)

    # Crée ou met à jour l'article brouillon
    if (article_params = params[:article]).present?
      article = week.article || Article.new
      article.assign_attributes(
        title:    article_params[:title].presence  || "Brouillon — #{week_of}",
        excerpt:  article_params[:excerpt].presence || "",
        content:  article_params[:content].presence || "",
        category: article_params[:category].presence || "conseils",
        author:   "Agent Marketing"
      )
      article.save!
      week.article = article
    end

    # Posts sociaux — le post peut contenir un séparateur "---\nBRIEF VISUEL : …"
    week.assign_attributes(
      linkedin_post:          params[:linkedin_post],
      instagram_post:         extract_post(params[:instagram_post]),
      instagram_visual_brief: extract_brief(params[:instagram_post]),
      facebook_post:          extract_post(params[:facebook_post]),
      facebook_visual_brief:  extract_brief(params[:facebook_post]),
      generated_at:           Time.current,
      status:                 'draft'
    )

    if week.save
      render json: { ok: true, week_of: week_of, article_id: week.article_id }, status: :created
    else
      render json: { ok: false, errors: week.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def authenticate_agent!
    token = request.headers['Authorization']&.sub(/\ABearer /, '')
    unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, ENV.fetch('AGENT_API_KEY', ''))
      render json: { error: 'Non autorisé' }, status: :unauthorized
    end
  end

  # Sépare le texte du post du brief visuel (séparateur "---")
  def extract_post(raw)
    return nil if raw.blank?
    raw.split(/\n---\n/).first&.strip
  end

  def extract_brief(raw)
    return nil if raw.blank?
    parts = raw.split(/\n---\n/)
    return nil if parts.size < 2
    parts.last.sub(/\ABRIEF VISUEL\s*:\s*/i, '').strip
  end

  def abort_with(msg)
    render json: { error: msg }, status: :bad_request
    nil
  end
end
