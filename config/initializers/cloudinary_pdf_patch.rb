# Force les PDFs à utiliser resource_type 'raw' sur Cloudinary.
#
# Par défaut, le gem Cloudinary classe application/pdf comme 'image', ce qui
# oblige Cloudinary à faire une transformation PDF→image pour servir le fichier.
# Cette transformation n'est pas disponible sur tous les plans, et génère des
# URLs image/upload/<key>.pdf qui retournent 404.
#
# En forçant 'raw', les PDFs sont stockés et servis directement comme fichiers
# bruts : raw/upload/production/<key>.pdf → téléchargement direct sans transformation.
#
# Les images (JPEG, PNG, WebP…) restent en 'image' — comportement inchangé.

if defined?(ActiveStorage::Service::CloudinaryService)
  class ActiveStorage::Service::CloudinaryService
    private

    def content_type_to_resource_type(content_type)
      return "image" if content_type.nil?

      type, _subtype = content_type.split("/")
      case type
      when "video", "audio" then "video"
      when "image"          then "image"
      else                       "raw"   # PDF, Word, Excel, etc.
      end
    end
  end
end
