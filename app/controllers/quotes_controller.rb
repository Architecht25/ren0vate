class QuotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property, except: [:start, :select_property]
  before_action :set_quote, only: [:show, :destroy, :print, :send_to_pro]

  # GET /quotes/start
  # Point d'entree depuis la sidebar: ouvre le createur de devis.
  # - 0 bien: redirige vers creation de bien
  # - 1 bien: ouvre directement le devis
  # - 2+ biens: demande de choisir explicitement le bien
  def start
    if params[:property_id].present?
      property = current_user.properties.find_by(id: params[:property_id])
      return redirect_to new_property_quote_path(property) if property

      return redirect_to select_property_quotes_path, alert: "Bien introuvable."
    end

    properties = current_user.properties.order(updated_at: :desc)

    if properties.none?
      redirect_to properties_path, alert: "Créez d'abord un bien pour utiliser l'estimateur de devis."
    elsif properties.one?
      redirect_to new_property_quote_path(properties.first)
    else
      redirect_to select_property_quotes_path
    end
  end

  # GET /quotes/select_property
  def select_property
    @properties = current_user.properties.order(updated_at: :desc)

    if @properties.none?
      redirect_to properties_path, alert: "Créez d'abord un bien pour utiliser l'estimateur de devis."
    elsif @properties.one?
      redirect_to new_property_quote_path(@properties.first)
    end
  end

  # GET /properties/:property_id/quotes
  def index
    @quotes = @property.quotes.recent
  end

  # GET /properties/:property_id/quotes/new
  def new
    @work_types_by_category = WorkType.by_category
    @projects = @property.projects.order(updated_at: :desc).limit(5)
  end

  # GET /properties/:property_id/quotes/estimate
  def estimate
    project = if params[:project_id].present?
      @property.projects.find_by(id: params[:project_id])
    else
      @property.projects.order(updated_at: :desc).first
    end

    description = [project&.type_travaux, params[:description]].compact.join(" ")
    result = BudgetEstimatorService.new(@property, type_travaux: description).call
    render json: result
  end

  # POST /properties/:property_id/quotes
  def create
    items_params = build_items_from_params
    if items_params.empty?
      flash[:alert] = "Veuillez sélectionner au moins un type de travaux avec une quantité."
      @work_types_by_category = WorkType.by_category
      render :new, status: :unprocessable_entity and return
    end

    calculator = Quotes::Calculator.new(items_params)
    result = calculator.calculate

    @quote = @property.quotes.new(
      user: current_user,
      total_min: result[:total_min],
      total_max: result[:total_max],
      total_avg: result[:total_avg],
      duration_min_days: result[:duration_min_days],
      duration_max_days: result[:duration_max_days],
      duration_avg_days: result[:duration_avg_days],
      status: 'draft'
    )

    Quote.transaction do
      @quote.save!
      result[:items].each do |item_data|
        @quote.quote_items.create!(
          work_type_key: item_data[:work_type_key],
          unit: item_data[:unit],
          quantity: item_data[:quantity],
          unit_price_min: item_data[:unit_price_min],
          unit_price_max: item_data[:unit_price_max],
          unit_price_avg: item_data[:unit_price_avg],
          total_min: item_data[:total_min],
          total_max: item_data[:total_max],
          total_avg: item_data[:total_avg]
        )
      end
    end

    redirect_to property_quote_path(@property, @quote), notice: "Devis estimatif créé avec succès."
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Erreur création devis: #{e.message}"
    flash[:alert] = "Une erreur est survenue lors de la création du devis."
    @work_types_by_category = WorkType.by_category
    render :new, status: :unprocessable_entity
  end

  # GET /properties/:property_id/quotes/:id
  def show; end

  # GET /properties/:property_id/quotes/:id/print
  def print
    render layout: 'print'
  end

  # POST /properties/:property_id/quotes/:id/send_to_pro
  def send_to_pro
    recipient_email = params[:recipient_email].to_s.strip
    message         = params[:message].to_s.strip.truncate(1000)

    unless recipient_email.match?(/\A[^@\s]+@[^@\s]+\z/)
      return redirect_to property_quote_path(@property, @quote),
             alert: "Adresse email invalide."
    end

    QuoteMailer.share_with_pro(
      @quote, @property,
      recipient_email,
      current_user.full_name,
      message.presence
    ).deliver_later

    redirect_to property_quote_path(@property, @quote),
                notice: "Devis envoyé à #{recipient_email} avec succès."
  end

  # DELETE /properties/:property_id/quotes/:id
  def destroy
    @quote.destroy
    redirect_to property_quotes_path(@property), notice: "Devis supprimé."
  end

  private

  def set_property
    @property = current_user.properties.find(params[:property_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to properties_path, alert: "Bien introuvable."
  end

  def set_quote
    @quote = @property.quotes.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to property_quotes_path(@property), alert: "Devis introuvable."
  end

  def build_items_from_params
    return [] unless params[:items].present?

    # to_unsafe_h: les items sont explicitement mappés vers work_type_key+quantity, pas de mass assignment AR
    params[:items].to_unsafe_h.filter_map do |key, data|
      next unless data[:selected] == '1' && data[:quantity].present?

      qty = data[:quantity].to_f
      next unless qty > 0

      { work_type_key: key, quantity: qty }
    end
  end

end
