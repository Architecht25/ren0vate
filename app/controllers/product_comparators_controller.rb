class ProductComparatorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: %i[index compare]

  # GET /product_comparators?project_id=X
  # Sélecteur de catégorie (modal ou page dédiée)
  def index
    @service    = ProductComparatorService.new(project: @project)
    @categories = @service.available_categories
  end

  # GET /product_comparators/compare?category=insulation&subcategory=toiture&project_id=X&priorities[]=performance
  # Résultats de comparaison (Turbo Frame friendly)
  def compare
    category    = params[:category].presence
    subcategory = params[:subcategory].presence
    priorities  = Array(params[:priorities]).presence || %w[performance ecology price]

    return redirect_to product_comparators_path(project_id: @project&.id),
                        alert: t('product_comparators.category_required') if category.blank?

    @service = ProductComparatorService.new(
      project:    @project,
      priorities: priorities
    )

    @result     = @service.compare(category: category, subcategory: subcategory)
    @category   = category
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

  private

  def set_project
    return unless params[:project_id].present?

    @project = current_user.projects.find_by(id: params[:project_id])
  end
end
