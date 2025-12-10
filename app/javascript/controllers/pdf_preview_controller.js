import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "loading", "image", "fallback"]
  static values = { documentId: Number }

  connect() {
    console.log('PDF Preview Controller connecté pour document:', this.documentIdValue)

    // Si pas de loading target, l'aperçu est déjà en cache - ne rien faire
    if (!this.hasLoadingTarget) {
      console.log('Pas de loading target - aperçu déjà en cache')
      return
    }

    // Générer l'aperçu de manière asynchrone seulement si nécessaire
    this.generatePdfPreview()
  }

  async generatePdfPreview() {
    try {
      console.log('Génération aperçu PDF pour document:', this.documentIdValue)

      const response = await fetch(`/api/pdf_preview/${this.documentIdValue}/generate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      })

      const result = await response.json()
      console.log('Résultat API:', result)

      if (result.success && result.preview_url) {
        // Recharger la page pour afficher l'aperçu en cache
        window.location.reload()
      } else {
        console.error('Erreur génération aperçu:', result)
        this.showFallback('Impossible de générer l\'aperçu')
      }
    } catch (error) {
      console.error('Erreur génération aperçu PDF:', error)
      this.showFallback('Erreur de chargement')
    }
  }

  showFallback(message) {
    if (this.hasLoadingTarget) {
      this.loadingTarget.innerHTML = `
        <div class="text-center">
          <i class="bi bi-file-earmark-pdf text-danger" style="font-size: 2.5rem;"></i>
          <div class="small text-muted mt-2">${message}</div>
        </div>
      `
    }
  }
}
