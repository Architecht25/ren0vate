import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    // Attendre que Bootstrap soit chargé
    if (typeof bootstrap !== 'undefined') {
      this.modal = new bootstrap.Modal(this.modalTarget)
    } else {
      // Si Bootstrap n'est pas encore chargé, attendre un peu
      setTimeout(() => {
        this.modal = new bootstrap.Modal(this.modalTarget)
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
      this.modal.show()
    }
  }

  confirm() {
    // Soumettre le formulaire de déconnexion
    if (this.form) {
      this.form.submit()
    }
    if (this.modal) {
      this.modal.hide()
    }
  }

  cancel() {
    // Simplement fermer la modal
    if (this.modal) {
      this.modal.hide()
    }
  }
}
