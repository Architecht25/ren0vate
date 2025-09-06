# Patch pour résoudre le problème de locale dans les URLs Active Storage
module ActiveStorageUrlPatch
  extend ActiveSupport::Concern

  # Override pour les URLs de blobs sans paramètre locale
  def blob_url(blob, options = {})
    # Retirer temporairement la locale des options par défaut pour Active Storage
    original_default_url_options = ActionController::Base.default_url_options.dup
    ActionController::Base.default_url_options.delete(:locale)

    begin
      super(blob, options)
    ensure
      # Restaurer les options par défaut
      ActionController::Base.default_url_options.merge!(original_default_url_options)
    end
  end
end

# Appliquer le patch au contrôleur Active Storage
if defined?(ActiveStorage::Blobs::RedirectController)
  ActiveStorage::Blobs::RedirectController.include(ActiveStorageUrlPatch)
end
