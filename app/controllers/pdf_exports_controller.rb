class PdfExportsController < ApplicationController
  include PdfExportsHelper

  # Rendre les helpers disponibles dans les vues
  helper_method :format_question_label, :format_answer_value, :format_price, :format_region_name

  # Désactiver la protection CSRF pour les requêtes PDF
  skip_before_action :verify_authenticity_token
  # Autoriser l'accès sans authentification pour l'export PDF
  skip_before_action :authenticate_user!

  def export_eligibilite
    @export_data = parse_export_data(params[:data])
    @region = params[:region]
    @export_type = 'eligibilite'

    respond_to do |format|
      format.pdf do
        # Solution temporaire : HTML optimisé pour impression PDF
        html_content = render_to_string(
          template: 'pdf_exports/eligibilite_export',
          layout: 'pdf_layout',
          formats: [:html]
        )

        pdf_result = PdfGenerationService.generate_from_html(
          html_content,
          filename: generate_filename
        )

        render html: pdf_result[:content].html_safe
      end
    end
  end

  def export_primes
    @export_data = parse_export_data(params[:data])
    @region = params[:region]
    @export_type = 'primes'

    respond_to do |format|
      format.pdf do
        # Solution temporaire : HTML optimisé pour impression PDF
        html_content = render_to_string(
          template: 'pdf_exports/primes_export',
          layout: 'pdf_layout',
          formats: [:html]
        )

        pdf_result = PdfGenerationService.generate_from_html(
          html_content,
          filename: generate_filename
        )

        render html: pdf_result[:content].html_safe
      end
    end
  end

  def export_complet
    @eligibilite_data = parse_export_data(params[:eligibilite_data])
    @primes_data = parse_export_data(params[:primes_data])
    @region = params[:region]
    @export_type = 'complet'

    respond_to do |format|
      format.pdf do
        # Solution temporaire : HTML optimisé pour impression PDF
        html_content = render_to_string(
          template: 'pdf_exports/complet_export',
          layout: 'pdf_layout',
          formats: [:html]
        )

        pdf_result = PdfGenerationService.generate_from_html(
          html_content,
          filename: generate_filename
        )

        render html: pdf_result[:content].html_safe
      end
    end
  end

  private

  def parse_export_data(data_param)
    return {} if data_param.blank?

    # Parse JSON data sent from frontend
    JSON.parse(data_param)
  rescue JSON::ParserError
    {}
  end

  def generate_filename
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    "ren0vate_#{@export_type}_#{@region}_#{timestamp}"
  end


end
