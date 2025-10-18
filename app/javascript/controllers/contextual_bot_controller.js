import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "sendButton", "suggestions", "modeIndicator", "toggleMode"]
  static values = {
    currentPage: String,
    mode: { type: String, default: "guide" }
  }

  connect() {
    console.log("ContextualBot controller connecté")
    this.initializeBot()
    this.setupEventListeners()

    // Gérer l'ouverture/fermeture du bot
    this.handleBotToggle()
  }

  initializeBot() {
    this.addWelcomeMessage()
    this.updateSuggestions()
    this.updateModeIndicator()
  }

  setupEventListeners() {
    // Détection automatique de la page
    this.detectCurrentPage()

    // Enter pour envoyer
    if (this.hasInputTarget) {
      this.inputTarget.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault()
          this.sendMessage()
        }
      })

      // Débloquer les événements sur l'input
      this.inputTarget.addEventListener('focus', () => {
        console.log('Input focus!')
      })

      this.inputTarget.addEventListener('input', () => {
        console.log('Input change:', this.inputTarget.value)
      })
    }
  }

  detectCurrentPage() {
    const path = window.location.pathname
    const currentPage = this.extractPageFromPath(path)
    this.currentPageValue = currentPage
    console.log("Page détectée:", currentPage)
  }

  extractPageFromPath(path) {
    if (path.includes('/profil')) return 'profil'
    if (path.includes('/bien')) return 'bien'
    if (path.includes('/chantier')) return 'chantier'
    if (path.includes('/simulation')) return 'simulation'
    if (path.includes('/documents')) return 'documents'
    if (path.includes('/decision_hub')) return 'decision_hub'
    return 'home'
  }

  addWelcomeMessage() {
    const welcomeMessage = this.createBotMessage(
      this.getWelcomeMessage(),
      'guide'
    )

    if (this.hasMessagesTarget) {
      this.messagesTarget.appendChild(welcomeMessage)
      this.scrollToBottom()
    }
  }

  getWelcomeMessage() {
    const pageMessages = {
      'profil': '👋 **Je suis votre guide pour la section Profil !**\n\nJe vais vous aider à remplir correctement vos informations pour maximiser vos primes.',
      'bien': '🏠 **Guide pour la description de votre bien**\n\nJe vous accompagne dans la saisie des caractéristiques techniques de votre propriété.',
      'chantier': '⚡ **Assistant travaux énergétiques**\n\nLaissez-moi vous guider dans la planification de vos travaux et le choix de vos entrepreneurs.',
      'simulation': '📊 **Analyse de votre simulation**\n\nJe vous aide à comprendre et optimiser vos résultats de primes.',
      'documents': '📄 **Préparation documentaire**\n\nJe vous guide dans la collecte et l\'organisation de vos documents.',
      'decision_hub': '🎯 **Hub de décision**\n\nPour des conseils personnalisés sur votre simulation, utilisez l\'IA Expert ci-dessus !',
      'home': '🚀 **Bienvenue sur Ren0vate !**\n\nJe suis votre assistant contextuel. Je m\'adapte à chaque page pour vous guider.'
    }

    return pageMessages[this.currentPageValue] || pageMessages['home']
  }

  async sendMessage(event) {
    if (event) event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) return

    // Afficher le message utilisateur
    this.addUserMessage(message)
    this.inputTarget.value = ''

    // Désactiver le bouton d'envoi
    this.sendButtonTarget.disabled = true

    try {
      const response = await this.callBotAPI(message)
      this.addBotMessage(response)
      this.updateSuggestions(response.suggestions)
    } catch (error) {
      console.error('Erreur bot:', error)
      this.addErrorMessage()
    } finally {
      this.sendButtonTarget.disabled = false
    }
  }

  async callBotAPI(message) {
    const response = await fetch('/api/contextual_bot/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        message: message,
        current_page: this.currentPageValue,
        mode: this.modeValue
      })
    })

    if (!response.ok) {
      throw new Error('Erreur API')
    }

    return await response.json()
  }

  addUserMessage(message) {
    const messageElement = this.createUserMessage(message)
    this.messagesTarget.appendChild(messageElement)
    this.scrollToBottom()
  }

  addBotMessage(response) {
    const messageElement = this.createBotMessage(response.response.content, response.mode)
    this.messagesTarget.appendChild(messageElement)
    this.scrollToBottom()
  }

  addErrorMessage() {
    const errorMessage = this.createBotMessage(
      "😅 Désolé, je rencontre un problème technique. Réessayez dans quelques instants !",
      this.modeValue
    )
    this.messagesTarget.appendChild(errorMessage)
    this.scrollToBottom()
  }

  createUserMessage(content) {
    const div = document.createElement('div')
    div.className = 'message user-message mb-2'
    div.innerHTML = `
      <div class="d-flex justify-content-end">
        <div class="message-bubble bg-primary text-white rounded-3 p-2 max-width-70">
          ${this.formatMessage(content)}
          <small class="d-block text-end mt-1 opacity-75">${this.getCurrentTime()}</small>
        </div>
      </div>
    `
    return div
  }

  createBotMessage(content, mode) {
    const modeIcon = mode === 'expert' ? '🧠' : '🎮'
    const modeColor = mode === 'expert' ? 'info' : 'success'

    const div = document.createElement('div')
    div.className = 'message bot-message mb-2'
    div.innerHTML = `
      <div class="d-flex">
        <div class="bot-avatar bg-${modeColor} rounded-circle d-flex align-items-center justify-content-center me-2"
             style="width: 32px; height: 32px; flex-shrink: 0;">
          ${modeIcon}
        </div>
        <div class="message-bubble bg-light border rounded-3 p-3 flex-grow-1">
          ${this.formatMessage(content)}
          <small class="d-block mt-2 text-muted">${this.getCurrentTime()}</small>
        </div>
      </div>
    `
    return div
  }

  formatMessage(content) {
    // Convertir le markdown simple en HTML
    return content
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/g, '<em>$1</em>')
      .replace(/\n/g, '<br>')
      .replace(/•/g, '&bull;')
  }

  getCurrentTime() {
    return new Date().toLocaleTimeString('fr-BE', {
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }

  toggleMode() {
    this.modeValue = this.modeValue === 'guide' ? 'expert' : 'guide'
    this.updateModeIndicator()
    this.updateSuggestions()

    // Message de changement de mode
    const modeMessage = this.modeValue === 'expert'
      ? "🧠 **Mode Expert activé**\n\nPosez-moi n'importe quelle question sur les primes énergétiques !"
      : "🎮 **Mode Guide activé**\n\nJe vous aide avec cette page spécifiquement."

    const messageElement = this.createBotMessage(modeMessage, this.modeValue)
    this.messagesTarget.appendChild(messageElement)
    this.scrollToBottom()
  }

  updateModeIndicator() {
    if (this.hasModeIndicatorTarget) {
      const isExpert = this.modeValue === 'expert'
      this.modeIndicatorTarget.innerHTML = isExpert
        ? '<i class="bi bi-brain me-1"></i>Expert'
        : '<i class="bi bi-compass me-1"></i>Guide'
      this.modeIndicatorTarget.className = `badge ${isExpert ? 'bg-info' : 'bg-success'}`
    }

    if (this.hasToggleModeTarget) {
      const isExpert = this.modeValue === 'expert'
      this.toggleModeTarget.innerHTML = isExpert
        ? '<i class="bi bi-compass me-1"></i>Mode Guide'
        : '<i class="bi bi-brain me-1"></i>Mode Expert'
      this.toggleModeTarget.className = `btn btn-outline-${isExpert ? 'success' : 'info'} btn-sm`
    }
  }

  // Cache des suggestions pour performances optimales
  suggestionCache = new Map()

  async updateSuggestions(suggestions = null) {
    if (!this.hasSuggestionsTarget) return

    if (!suggestions) {
      const cacheKey = `${this.currentPageValue}_${this.modeValue}`

      // Vérifier le cache d'abord
      if (this.suggestionCache.has(cacheKey)) {
        this.renderSuggestions(this.suggestionCache.get(cacheKey))
        return
      }

      // Obtenir les suggestions pour la page/mode actuels
      try {
        const controller = new AbortController()
        const timeoutId = setTimeout(() => controller.abort(), 3000) // Timeout 3s

        const response = await fetch('/api/contextual_bot/suggestions', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
          },
          body: JSON.stringify({
            current_page: this.currentPageValue,
            mode: this.modeValue
          }),
          signal: controller.signal
        })

        clearTimeout(timeoutId)

        if (response.ok) {
          const data = await response.json()
          suggestions = data.suggestions

          // Mettre en cache pour 3 minutes
          this.suggestionCache.set(cacheKey, suggestions)
          setTimeout(() => this.suggestionCache.delete(cacheKey), 3 * 60 * 1000)
        }
      } catch (error) {
        if (error.name !== 'AbortError') {
          console.error('Erreur suggestions:', error)
        }
        // Suggestions de fallback ultra-rapides
        suggestions = ['💡 Comment puis-je vous aider ?', '🔍 Posez votre question']
      }
    }

    if (suggestions && suggestions.length > 0) {
      this.renderSuggestions(suggestions)
    }
  }

  renderSuggestions(suggestions) {
    this.suggestionsTarget.innerHTML = ''

    suggestions.forEach(suggestion => {
      const button = document.createElement('button')
      button.className = 'btn btn-outline-secondary btn-sm me-2 mb-2'
      button.textContent = suggestion
      button.addEventListener('click', () => {
        this.inputTarget.value = suggestion.replace(/^[🎯💡📊🏠⚡💰👷📅📄🔍📋✅🏛️🔄🧠🎮]+\s*/, '')
        this.sendMessage()
      })

      this.suggestionsTarget.appendChild(button)
    })
  }

  selectSuggestion(event) {
    const suggestion = event.target.textContent
    const cleanSuggestion = suggestion.replace(/^[🎯💡📊🏠⚡💰👷📅📄🔍📋✅🏛️🔄🧠🎮]+\s*/, '')
    this.inputTarget.value = cleanSuggestion
    this.sendMessage()
  }

  handleBotToggle() {
    // Quand le chat s'ouvre, focus sur l'input
    const chatContainer = document.getElementById('bot-chat-container')
    if (chatContainer) {
      chatContainer.addEventListener('shown.bs.collapse', () => {
        if (this.hasInputTarget) {
          setTimeout(() => {
            this.inputTarget.focus()
          }, 100)
        }
      })
    }
  }
}
