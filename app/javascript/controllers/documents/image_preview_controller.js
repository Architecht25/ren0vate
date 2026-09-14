import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "previewImg"]

  connect() {
    this.validateFileInput()
  }

  previewImage() {
    const file = this.inputTarget.files[0]

    if (file) {
      // Validation de la taille (5MB max)
      const maxSize = 5 * 1024 * 1024
      if (file.size > maxSize) {
        alert('La taille du fichier ne peut pas dépasser 5MB. Veuillez choisir une image plus petite.')
        this.inputTarget.value = ''
        this.hidePreview()
        return
      }

      // Validation du type de fichier
      const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif']
      if (!allowedTypes.includes(file.type)) {
        alert('Seuls les fichiers JPG, PNG et GIF sont autorisés.')
        this.inputTarget.value = ''
        this.hidePreview()
        return
      }

      // Afficher la prévisualisation
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewImgTarget.src = e.target.result
        this.showPreview()
      }
      reader.readAsDataURL(file)
    } else {
      this.hidePreview()
    }
  }

  showPreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.style.display = 'block'
    }
  }

  hidePreview() {
    if (this.hasPreviewTarget) {
      this.previewTarget.style.display = 'none'
    }
  }

  validateFileInput() {
    // Ajouter des écouteurs d'événements pour la validation
    this.inputTarget.addEventListener('change', () => {
      this.previewImage()
    })
  }
}
