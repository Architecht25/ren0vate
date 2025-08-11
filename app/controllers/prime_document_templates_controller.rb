class PrimeDocumentTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_template, only: [:show, :download]

  # GET /prime_document_templates
  def index
    @templates = PrimeDocumentTemplate.includes(:prime)
                   .by_order

    # Filtrage par prime si spécifié
    if params[:prime_id].present?
      @prime = Prime.find(params[:prime_id])
      @templates = @templates.for_prime(@prime)
    end

    # Filtrage par type si spécifié
    if params[:type_document].present?
      @templates = @templates.by_type(params[:type_document])
    end
  end

  # GET /prime_document_templates/:id
  def show
    @prime = @template.prime
  end

  # GET /prime_document_templates/:id/download
  def download
    unless @template.file_available?
      redirect_back fallback_location: root_path, alert: "Document non disponible"
      return
    end

    if @template.document_file.attached?
      # Téléchargement via Active Storage
      redirect_to @template.document_file.url, allow_other_host: true
    elsif @template.file_url.present?
      # Téléchargement via URL externe
      redirect_to @template.file_url, allow_other_host: true
    end
  end

  # GET /simulations/:simulation_id/download_documents
  def download_simulation_documents
    @simulation = current_user.simulations.find(params[:simulation_id])

    # Récupérer les primes de la simulation (à adapter selon votre logique)
    @selected_primes = get_simulation_primes(@simulation)

    if @selected_primes.empty?
      redirect_back fallback_location: simulation_path(@simulation),
                    alert: "Aucune prime sélectionnée"
      return
    end

    @templates = PrimeDocumentTemplate.joins(:prime)
                   .where(prime: @selected_primes)
                   .required_docs
                   .by_order

    if @templates.empty?
      redirect_back fallback_location: simulation_path(@simulation),
                    alert: "Aucun document disponible pour ces primes"
      return
    end

    # Si un seul document, téléchargement direct
    if @templates.count == 1
      redirect_to download_prime_document_template_path(@templates.first)
      return
    end

    # Sinon, créer un ZIP
    zip_service = DocumentZipService.new(@templates)
    zip_file = zip_service.generate

    send_file zip_file,
              filename: "documents_primes_simulation_#{@simulation.id}.zip",
              type: 'application/zip',
              disposition: 'attachment'
  end

  # GET /primes/:prime_id/download_documents
  def download_prime_documents
    @prime = Prime.find(params[:prime_id])
    @templates = @prime.document_templates.required_docs.by_order

    if @templates.empty?
      redirect_back fallback_location: root_path,
                    alert: "Aucun document disponible pour cette prime"
      return
    end

    # Si un seul document, téléchargement direct
    if @templates.count == 1
      redirect_to download_prime_document_template_path(@templates.first)
      return
    end

    # Sinon, créer un ZIP
    zip_service = DocumentZipService.new(@templates)
    zip_file = zip_service.generate

    send_file zip_file,
              filename: "documents_#{@prime.slug}.zip",
              type: 'application/zip',
              disposition: 'attachment'
  end

  private

  def set_template
    @template = PrimeDocumentTemplate.find(params[:id])
  end

  def get_simulation_primes(simulation)
    # À adapter selon votre logique de simulation
    # Exemple basique :
    if simulation.respond_to?(:selected_primes)
      simulation.selected_primes
    else
      # Logique alternative pour récupérer les primes de la simulation
      Prime.where(region: simulation.region) # Exemple
    end
  end
end
