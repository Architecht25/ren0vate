import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "previewContainer", "downloadBtn", "previewBtn", "fileName", "fileSize", "fileIcon"]
  static values = {
    previewUrl: String,
    downloadUrl: String,
    debugUrl: String
  }

  connect() {
    this.validateFileInput()
    this.setupExistingFile()
  }

  // Gestion de l'upload de nouveaux fichiers
  previewFile() {
    const file = this.inputTarget.files[0]

    if (file) {
      // Validation de la taille (10MB max)
      const maxSize = 10 * 1024 * 1024
      if (file.size > maxSize) {
        this.showError('La taille du fichier ne peut pas dépasser 10MB. Veuillez choisir un fichier plus petit.')
        this.resetInput()
        return
      }

      // Validation du type de fichier
      const allowedTypes = [
        'application/pdf',
        'image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      ]

      if (!allowedTypes.includes(file.type)) {
        this.showError('Format de fichier non autorisé. Formats acceptés: PDF, images (JPEG, PNG, GIF, WebP), documents Word/Excel.')
        this.resetInput()
        return
      }

      // Afficher les informations du fichier
      this.updateFileInfo(file.name, file.size, file.type)
      this.showLocalPreview(file)
    } else {
      this.hidePreview()
    }
  }

  // Prévisualisation pour fichiers locaux (avant upload)
  showLocalPreview(file) {
    if (file.type.startsWith('image/')) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.showImagePreview(e.target.result)
      }
      reader.readAsDataURL(file)
    } else if (file.type === 'application/pdf') {
      this.showPdfInfo()
    } else {
      this.showDocumentInfo()
    }
    this.showPreview()
  }

  // Prévisualisation pour fichiers existants (déjà uploadés)
  setupExistingFile() {
    // Plus besoin de configurer manuellement les event listeners
    // car ils sont gérés par les data-action dans le HTML
  }

  // Gestion des actions directes (appelées par data-action)
  showRemotePreview() {
    this.showRemotePreviewInternal()
  }

  downloadFile() {
    this.downloadFileInternal()
  }

  // Méthodes internes
  async showRemotePreviewInternal() {
    if (!this.previewUrlValue) {
      this.showError('URL de prévisualisation non disponible')
      return
    }

    try {
      this.showLoading()

      const response = await fetch(this.previewUrlValue, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`Erreur HTTP: ${response.status}`)
      }

      const data = await response.json()

      if (data.error) {
        throw new Error(data.error)
      }

      this.hideLoading()
      this.displayRemotePreview(data)

    } catch (error) {
      this.hideLoading()
      this.showError(`Erreur lors de la prévisualisation: ${error.message}`)

      // Fallback: essayer le debug
      if (this.hasDebugUrlValue) {
        this.debugFile()
      }
    }
  }

  // Affichage de la prévisualisation distante
  displayRemotePreview(data) {
    switch (data.type) {
      case 'image':
        this.showImagePreview(data.url)
        break
      case 'pdf':
        this.showPdfPreview(data.url)
        break
      case 'pdf_with_preview':
        this.showPdfWithPreview(data.preview_url, data.pdf_url)
        break
      default:
        this.showError(data.message || 'Prévisualisation non disponible pour ce type de fichier')
    }
  }

  // Affichage d'une image
  showImagePreview(url) {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = `
        <div class="text-center">
          <img src="${url}" alt="Prévisualisation" class="img-fluid rounded shadow" style="max-height: 400px;">
        </div>
      `
    }
  }

  // Affichage d'un PDF avec prévisualisation image
  showPdfWithPreview(previewUrl, pdfUrl) {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = `
        <div class="text-center">
          <div class="pdf-preview-container border rounded p-3">
            <div class="row">
              <div class="col-md-6">
                <img src="${previewUrl}" alt="Prévisualisation PDF" class="img-fluid rounded shadow mb-3" style="max-height: 300px;">
              </div>
              <div class="col-md-6 d-flex flex-column justify-content-center">
                <i class="bi bi-file-earmark-pdf text-danger" style="font-size: 3rem;"></i>
                <p class="mt-2 mb-3">Document PDF avec prévisualisation</p>
                <div class="d-grid gap-2">
                  <a href="${pdfUrl}" target="_blank" class="btn btn-primary">
                    <i class="bi bi-eye me-2"></i>Ouvrir le PDF
                  </a>
                  <a href="${pdfUrl}" download class="btn btn-outline-secondary">
                    <i class="bi bi-download me-2"></i>Télécharger
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      `
    }
  }

  // Affichage d'un PDF
  showPdfPreview(url) {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = `
        <div class="text-center">
          <div class="pdf-preview-container border rounded p-3">
            <i class="bi bi-file-earmark-pdf text-danger" style="font-size: 3rem;"></i>
            <p class="mt-2 mb-3">Document PDF prêt à visualiser</p>
            <div class="d-grid gap-2 d-md-flex justify-content-md-center">
              <a href="${url}" target="_blank" class="btn btn-primary">
                <i class="bi bi-eye me-2"></i>Ouvrir le PDF
              </a>
              <a href="${url}" download class="btn btn-outline-secondary">
                <i class="bi bi-download me-2"></i>Télécharger
              </a>
            </div>
          </div>
        </div>
      `
    }
  }

  // Info pour PDF local
  showPdfInfo() {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = `
        <div class="text-center">
          <div class="pdf-info-container border rounded p-3 bg-light">
            <i class="bi bi-file-earmark-pdf text-danger" style="font-size: 3rem;"></i>
            <p class="mt-2 mb-0">Document PDF sélectionné</p>
            <small class="text-muted">La prévisualisation sera disponible après l'upload</small>
          </div>
        </div>
      `
    }
  }

  // Info pour documents génériques
  showDocumentInfo() {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = `
        <div class="text-center">
          <div class="document-info-container border rounded p-3 bg-light">
            <i class="bi bi-file-earmark text-primary" style="font-size: 3rem;"></i>
            <p class="mt-2 mb-0">Document sélectionné</p>
            <small class="text-muted">Prêt pour l'upload</small>
          </div>
        </div>
      `
    }
  }

  // Téléchargement de fichier
  async downloadFileInternal() {
    if (!this.downloadUrlValue) {
      this.showError('URL de téléchargement non disponible')
      return
    }

    try {
      // Ouvrir le lien de téléchargement dans un nouvel onglet
      window.open(this.downloadUrlValue, '_blank')
    } catch (error) {
      this.showError(`Erreur lors du téléchargement: ${error.message}`)
    }
  }

  // Debug du fichier
  async debugFile() {
    if (!this.debugUrlValue) return

    try {
      const response = await fetch(this.debugUrlValue)
      const data = await response.json()
      console.log('Debug info:', data)

      if (data.error) {
        this.showError(`Debug: ${data.error}`)
      } else {
        this.showInfo(`Fichier: ${data.filename}, Taille: ${data.byte_size} bytes, Type: ${data.content_type}`)
      }
    } catch (error) {
      console.error('Debug failed:', error)
    }
  }

  // Mise à jour des informations du fichier
  updateFileInfo(fileName, fileSize, fileType) {
    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = fileName
    }

    if (this.hasFileSizeTarget) {
      this.fileSizeTarget.textContent = this.formatFileSize(fileSize)
    }

    if (this.hasFileIconTarget) {
      this.fileIconTarget.className = this.getFileIcon(fileType)
    }
  }

  // Formatage de la taille de fichier
  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  // Icône en fonction du type de fichier
  getFileIcon(fileType) {
    const baseClass = 'bi '
    switch (true) {
      case fileType.startsWith('image/'):
        return baseClass + 'bi-file-earmark-image text-success'
      case fileType === 'application/pdf':
        return baseClass + 'bi-file-earmark-pdf text-danger'
      case fileType.includes('word'):
        return baseClass + 'bi-file-earmark-word text-primary'
      case fileType.includes('excel') || fileType.includes('sheet'):
        return baseClass + 'bi-file-earmark-excel text-success'
      default:
        return baseClass + 'bi-file-earmark text-muted'
    }
  }

  // Gestion des états de l'interface
  showPreview() {
    if (this.hasPreviewContainerTarget) {
      this.previewContainerTarget.style.display = 'block'
    }
  }

  hidePreview() {
    if (this.hasPreviewContainerTarget) {
      this.previewContainerTarget.style.display = 'none'
    }
  }

  showLoading() {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = `
        <div class="text-center p-4">
          <div class="spinner-border text-primary" role="status">
            <span class="visually-hidden">Chargement...</span>
          </div>
          <p class="mt-2 mb-0">Chargement de la prévisualisation...</p>
        </div>
      `
    }
    this.showPreview()
  }

  hideLoading() {
    // Le contenu sera remplacé par la prévisualisation
  }

  // Gestion des erreurs et messages
  showError(message) {
    console.error('Document Preview Error:', message)
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = `
        <div class="alert alert-danger" role="alert">
          <i class="bi bi-exclamation-triangle me-2"></i>
          ${message}
        </div>
      `
    }
    this.showPreview()
  }

  showInfo(message) {
    if (this.hasPreviewTarget) {
      this.previewTarget.innerHTML = `
        <div class="alert alert-info" role="alert">
          <i class="bi bi-info-circle me-2"></i>
          ${message}
        </div>
      `
    }
    this.showPreview()
  }

  resetInput() {
    this.inputTarget.value = ''
    this.hidePreview()
  }

  validateFileInput() {
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener('change', () => {
        this.previewFile()
      })
    }
  }
}
