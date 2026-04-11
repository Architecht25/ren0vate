class ProductComparatorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: %i[index compare recommendation]

  # GET /product_comparators?project_id=X
  # Sélecteur de catégorie (modal ou page dédiée)
  def index
    @service    = ProductComparatorService.new(project: @project)
    @categories = @service.available_categories
  end

  # GET /product_comparators/compare — tableau instantané (sans IA)
  def compare
    category    = params[:category].presence
    subcategory = params[:subcategory].presence
    priorities  = Array(params[:priorities]).presence || %w[performance ecology price]

    return redirect_to product_comparators_path(project_id: @project&.id),
                        alert: 'Catégorie requise' if category.blank?

    @service = ProductComparatorService.new(
      project:    @project,
      priorities: priorities
    )

    # skip_ai: true → réponse immédiate, la reco se charge via /recommendation
    @result      = @service.compare(category: category, subcategory: subcategory, skip_ai: true)
    @category    = category
    @subcategory = subcategory
    @priorities  = priorities

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'comparator_results',
          partial: 'product_comparators/results',
          locals:  { result: @result, project: @project, priorities: @priorities }
        )
      end
    end
  end

  # GET /product_comparators/recommendation — appel IA séparé (lazy)
  def recommendation
    category    = params[:category].presence
    subcategory = params[:subcategory].presence
    priorities  = Array(params[:priorities]).presence || %w[performance ecology price]

    return head :bad_request if category.blank?

    service = ProductComparatorService.new(project: @project, priorities: priorities)
    result  = service.compare(category: category, subcategory: subcategory, skip_ai: false)
    reco    = result[:recommendation]

    render turbo_stream: turbo_stream.replace(
      'comparator_ai_recommendation',
      partial: 'product_comparators/ai_recommendation',
      locals:  { recommendation: reco }
    )
  end

  private

  def set_project
    return unless params[:project_id].present?

    @project = current_user.projects.find_by(id: params[:project_id])
  end
end
