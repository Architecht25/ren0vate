# ActiveStorageFileAdapter
#
# Fait passer un fichier ActiveStorage déjà attaché (téléchargé dans un Tempfile
# via `blob.open`) pour un fichier "upload" classique (ActionDispatch::Http::
# UploadedFile) — c'est l'interface attendue par OcrService et ses sous-classes
# (content_type, size, read, rewind, tempfile).
#
# Nécessaire pour les jobs en arrière-plan (ex: AuditEnergExtractionJob) : le
# fichier uploadé par l'utilisateur (params[:file]) ne survit pas à la requête
# HTTP, seul le blob attaché au Document reste accessible depuis le job.
#
# Usage :
#   document.file.blob.open do |tempfile|
#     file = ActiveStorageFileAdapter.new(tempfile, document.file.content_type)
#     AuditEnergClaudeService.new(file).extraire_donnees_audit
#   end

class ActiveStorageFileAdapter
  attr_reader :content_type

  def initialize(tempfile, content_type)
    @tempfile = tempfile
    @content_type = content_type
  end

  def tempfile
    @tempfile
  end

  def size
    @tempfile.size
  end

  def read(*args)
    @tempfile.read(*args)
  end

  def rewind
    @tempfile.rewind
  end

  def original_filename
    File.basename(@tempfile.path)
  end
end
