// Controller Stimulus pour la gestion des langues
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selector"]

  connect() {
    this.detectAndSuggestLanguage()
  }

  // Détecter la langue du navigateur et suggérer un changement
  detectAndSuggestLanguage() {
    const userLang = navigator.language || navigator.userLanguage
    const currentLocale = document.documentElement.lang || 'fr'

    // Mapping des langues du navigateur vers nos locales
    const languageMap = {
      'fr': 'fr',
      'fr-FR': 'fr',
      'fr-BE': 'fr',
      'nl': 'nl',
      'nl-BE': 'nl',
      'nl-NL': 'nl',
      'en': 'en',
      'en-US': 'en',
      'en-GB': 'en'
    }

    const suggestedLocale = languageMap[userLang] || languageMap[userLang.split('-')[0]]

    // Si la langue suggérée est différente de l'actuelle et qu'on n'a pas déjà suggéré
    if (suggestedLocale &&
        suggestedLocale !== currentLocale &&
        !sessionStorage.getItem('language_suggestion_dismissed')) {

      this.showLanguageSuggestion(suggestedLocale)
    }
  }

  // Afficher une suggestion de changement de langue
  showLanguageSuggestion(suggestedLocale) {
    const languageNames = {
      'fr': 'Français',
      'nl': 'Nederlands',
      'en': 'English'
    }

    const message = `Votre navigateur semble configuré en ${languageNames[suggestedLocale]}. Souhaitez-vous changer la langue de l'interface ?`

    // Créer une notification toast
    const toast = this.createLanguageToast(message, suggestedLocale)
    document.body.appendChild(toast)

    // Afficher le toast
    const bootstrapToast = new bootstrap.Toast(toast)
    bootstrapToast.show()
  }

  // Créer un toast pour la suggestion de langue
  createLanguageToast(message, suggestedLocale) {
    const toast = document.createElement('div')
    toast.className = 'toast align-items-center text-white bg-primary border-0'
    toast.setAttribute('role', 'alert')
    toast.style.position = 'fixed'
    toast.style.top = '20px'
    toast.style.right = '20px'
    toast.style.zIndex = '9999'

    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">
          <i class="bi bi-translate me-2"></i>
          ${message}
        </div>
        <div class="ms-auto d-flex align-items-center pe-2">
          <button type="button" class="btn btn-sm btn-outline-light me-2"
                  onclick="window.location.href='${window.location.pathname}?locale=${suggestedLocale}'">
            Oui
          </button>
          <button type="button" class="btn-close btn-close-white"
                  data-bs-dismiss="toast"
                  onclick="sessionStorage.setItem('language_suggestion_dismissed', 'true')">
          </button>
        </div>
      </div>
    `

    return toast
  }

  // Changer la langue
  changeLanguage(event) {
    const locale = event.currentTarget.dataset.locale
    const currentUrl = new URL(window.location)
    currentUrl.searchParams.set('locale', locale)
    window.location.href = currentUrl.toString()
  }

  // Sauvegarder la préférence de langue (pour les utilisateurs connectés)
  saveLanguagePreference(locale) {
    if (document.querySelector('meta[name="user-signed-in"]')) {
      fetch('/api/users/language-preference', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ preferred_locale: locale })
      }).catch(error => {
      })
    }
  }
}
