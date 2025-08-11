require 'zip'

class DocumentZipService
  def initialize(templates)
    @templates = templates
    @temp_dir = Rails.root.join('tmp', 'zip_downloads')
    ensure_temp_directory
  end

  def generate
    zip_filename = "documents_#{Time.current.to_i}.zip"
    zip_path = @temp_dir.join(zip_filename)

    Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
      @templates.each_with_index do |template, index|
        add_file_to_zip(zipfile, template, index)
      end
    end

    zip_path
  end

  private

  def ensure_temp_directory
    FileUtils.mkdir_p(@temp_dir) unless Dir.exist?(@temp_dir)
  end

  def add_file_to_zip(zipfile, template, index)
    begin
      if template.document_file.attached?
        # Télécharger depuis Active Storage/Cloudinary
        temp_file = download_active_storage_file(template)
        filename = sanitize_filename("#{template.prime.slug}_#{template.file_name}")
        zipfile.add(filename, temp_file.path)
      elsif template.file_url.present?
        # Télécharger depuis URL
        temp_file = download_from_url(template)
        filename = sanitize_filename("#{template.prime.slug}_#{template.file_name}")
        zipfile.add(filename, temp_file.path)
      end
    rescue => e
      Rails.logger.error "Erreur lors de l'ajout du fichier #{template.title}: #{e.message}"
      # Créer un fichier d'erreur dans le ZIP
      error_content = "Erreur lors du téléchargement du document: #{template.title}\n"
      error_content += "Prime: #{template.prime.titre}\n"
      error_content += "Erreur: #{e.message}"

      zipfile.get_output_stream("ERREUR_#{template.prime.slug}.txt") do |os|
        os.write error_content
      end
    end
  end

  def download_active_storage_file(template)
    temp_file = Tempfile.new([template.prime.slug, '.pdf'])
    temp_file.binmode

    # Télécharger le fichier depuis Cloudinary/Active Storage
    template.document_file.open do |file|
      temp_file.write(file.read)
    end

    temp_file.close
    temp_file
  end

  def download_from_url(template)
    require 'open-uri'

    temp_file = Tempfile.new([template.prime.slug, '.pdf'])
    temp_file.binmode

    URI.open(template.file_url) do |file|
      temp_file.write(file.read)
    end

    temp_file.close
    temp_file
  end

  def sanitize_filename(filename)
    # Remplacer les caractères spéciaux
    filename.gsub(/[^\w\-_\.]/, '_').squeeze('_')
  end
end
