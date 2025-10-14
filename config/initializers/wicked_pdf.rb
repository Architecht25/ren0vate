# Configuration pour WickedPDF
WickedPdf.configure do |c|
  # Utiliser le binaire système sur Heroku, sinon chercher la gem en développement
  if ENV['WKHTMLTOPDF_PATH']
    c.exe_path = ENV['WKHTMLTOPDF_PATH']
  else
    begin
      c.exe_path = Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')
    rescue Gem::GemNotFoundException
      # Fallback vers les chemins système courants
      c.exe_path = '/usr/local/bin/wkhtmltopdf'
    end
  end

  # Options par défaut pour la génération PDF
  c.default_options = {
    page_size: 'A4',
    margin: {
      top: 15,
      bottom: 15,
      left: 15,
      right: 15
    },
    encoding: 'UTF-8',
    disable_smart_shrinking: true,
    print_media_type: true,
    lowquality: false,
    zoom: 1,
    dpi: 300
  }
end

# Configuration Rails pour inclure WickedPDF
Rails.application.config.middleware.use WickedPdf::Middleware
