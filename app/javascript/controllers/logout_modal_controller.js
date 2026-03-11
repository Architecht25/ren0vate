import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Attendre que Bootstrap soit chargé et vérifier que l'élément modal existe
    if (typeof bootstrap !== 'undefined' && this.hasModalTarget) {
      try {
        this.modal = new bootstrap.Modal(this.modalTarget)
      } catch (error) {
        this.modal = null
      }
    } else if (this.hasModalTarget) {
      // Si Bootstrap n'est pas encore chargé, attendre un peu
      setTimeout(() => {
        if (typeof bootstrap !== 'undefined' && this.hasModalTarget) {
          try {
            this.modal = new bootstrap.Modal(this.modalTarget)
          } catch (error) {
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
      }
    }
  }

  cancel() {
    // Simplement fermer la modal
    if (this.modal) {
      try {
        this.modal.hide()
      } catch (error) {
      }
    }
  }
}
