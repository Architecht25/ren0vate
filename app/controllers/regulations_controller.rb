class RegulationsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Si aucune région n'est spécifiée, rediriger vers la sélection de région
    if params[:region].blank?
      redirect_to region_selection_regulations_path
      return
    end

    @page_title = "Exigences Réglementaires - #{params[:region].humanize}"
    @active_tab = params[:tab] || 'overview'
    @region = params[:region]
  end

  def region_selection
    @page_title = "Sélection de région - Exigences Réglementaires"
  end

  def ventilation_guide
    @page_title = "Guide Ventilation - Mijn VerbouwPremie"
    @region = params[:region] || 'flandre' # Par défaut sur flandre si pas spécifié
  end

  def ventilation_calculator
    @page_title = "Calculateur Ventilation"
    @region = params[:region] || 'flandre' # Par défaut sur flandre si pas spécifié
    @room_type = params[:room_type]
    @room_area = params[:room_area].to_f if params[:room_area]
    @window_width = params[:window_width].to_f if params[:window_width]

    if @room_area && @window_width && @room_type
      calculate_ventilation_requirements
    end
  end

  private

  def calculate_ventilation_requirements
    case @room_type
    when 'woonkamer'
      @base_requirement = @room_area * 3.6
      @minimum_requirement = 75
      @maximum_limit = 150
    when 'slaapkamer', 'studeerkamer', 'speelkamer', 'hobbyruimte'
      @base_requirement = @room_area * 3.6
      @minimum_requirement = 25
      @maximum_limit = 72
    end

    @window_limitation = @window_width * 45
    @final_requirement = [@base_requirement, @minimum_requirement].max
    @final_requirement = [@final_requirement, @maximum_limit].min if @maximum_limit
    @final_requirement = [@final_requirement, @window_limitation].min
  end
end
