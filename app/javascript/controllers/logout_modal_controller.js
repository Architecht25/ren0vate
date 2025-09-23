import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Attendre que Bootstrap soit chargé et vérifier que l'élément modal existe
    if (typeof bootstrap !== 'undefined' && this.modalTarget) {
      try {
        this.modal = new bootstrap.Modal(this.modalTarget)
      } catch (error) {
        console.warn('Erreur lors de l\'initialisation de la modal:', error)
        this.modal = null
      }
    } else {
      // Si Bootstrap n'est pas encore chargé, attendre un peu
      setTimeout(() => {
        if (typeof bootstrap !== 'undefined' && this.modalTarget) {
          try {
            this.modal = new bootstrap.Modal(this.modalTarget)
          } catch (error) {
            console.warn('Erreur lors de l\'initialisation de la modal (retry):', error)
            this.modal = null
          }
        }
      }, 100)
    }
  }

  show(event) {
    // Empêcher la soumission immédiate du formulaire
    event.preventDefault()

    // Stocker le formulaire pour l'utiliser plus tard
    this.form = event.target.closest('form')

    // Afficher la modal
    if (this.modal) {
      try {
        this.modal.show()
      } catch (error) {
        console.warn('Erreur lors de l\'affichage de la modal:', error)
        // Fallback: soumettre directement le formulaire si la modal ne fonctionne pas
        if (this.form) {
          this.form.submit()
        }
      }
    } else {
      // Fallback: soumettre directement le formulaire si pas de modal
      if (this.form) {
        this.form.submit()
      }
    }
  }

  confirm() {
    // Soumettre le formulaire de déconnexion
    if (this.form) {
      this.form.submit()
    }
    if (this.modal) {
      try {
        this.modal.hide()
      } catch (error) {
        console.warn('Erreur lors de la fermeture de la modal:', error)
      }
    }
  }

  cancel() {
    // Simplement fermer la modal
    if (this.modal) {
      try {
        this.modal.hide()
      } catch (error) {
        console.warn('Erreur lors de l\'annulation de la modal:', error)
      }
    }
  }
}
