// Controller Stimulus pour les interactions locales du Decision Hub
// Complémentaire au decision_hub_controller.js principal

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "aiInput",
    "aiSendButton",
    "conversationArea",
    "preparationScore",
    "preparationProgressBar",
    "preparationStatus"
  ]

  connect() {
    console.log("Decision Hub Interactions controller connected")
    console.log("AI Input target found:", this.hasAiInputTarget)
    console.log("AI Send Button target found:", this.hasAiSendButtonTarget)
    console.log("Conversation Area target found:", this.hasConversationAreaTarget)
    this.setupAIInput()
    this.setupObligationCheckboxes()
    this.setupQuickQuestions()
    this.setupContextualAIButtons()
  }

  // Configuration des interactions IA
  setupAIInput() {
    console.log("Setting up AI input...")
    console.log("Has AI Send Button Target:", this.hasAiSendButtonTarget)
    console.log("Has AI Input Target:", this.hasAiInputTarget)

    if (this.hasAiSendButtonTarget && this.hasAiInputTarget) {
      console.log("Adding event listeners to AI input/button...")
      this.aiSendButtonTarget.addEventListener('click', (e) => {
        console.log("AI Send button clicked!")
        this.sendAIMessage(e)
      })

      this.aiInputTarget.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          console.log("Enter pressed in AI input!")
          e.preventDefault()
          this.sendAIMessage(e)
        }
      })
    } else {
      console.log("AI targets not found!")
      console.log("aiSendButtonTarget:", this.aiSendButtonTarget)
      console.log("aiInputTarget:", this.aiInputTarget)
    }
  }

  // Configuration des boutons IA contextuels
  setupContextualAIButtons() {
    document.querySelectorAll('[data-bs-toggle="modal"][data-bs-target="#aiConsultationModal"]').forEach(button => {
      button.addEventListener('click', (e) => {
        const context = e.target.closest('[data-context]')?.dataset.context || 'general'
        const quickQuestion = e.target.closest('[data-quick-question]')?.dataset.quickQuestion

        // Pre-remplir l'input si une question rapide est définie
        if (quickQuestion && this.hasAiInputTarget) {
          // Attendre que le modal soit ouvert avant de remplir l'input
          setTimeout(() => {
            this.aiInputTarget.value = quickQuestion
            this.aiInputTarget.focus()
          }, 500)
        }

        // Stocker le contexte pour l'utiliser dans l'API call
        this.currentContext = context
      })
    })
  }

  // Configuration des checkboxes d'obligations
  setupObligationCheckboxes() {
    const checkboxes = document.querySelectorAll('.checklist input[type="checkbox"]')
    checkboxes.forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        this.updatePreparationScore()
      })
    })
  }

  // Configuration des questions rapides IA
  setupQuickQuestions() {
    console.log("Setting up quick questions...")
    const quickQuestionBtns = document.querySelectorAll('.quick-questions .btn')
    console.log("Found", quickQuestionBtns.length, "quick question buttons")

    quickQuestionBtns.forEach((btn, index) => {
      console.log(`Button ${index}:`, btn.textContent.trim())
      btn.addEventListener('click', (e) => {
        console.log("Quick question button clicked:", e.target.textContent.trim())
        const question = e.target.dataset.question || e.target.textContent
        const context = e.target.dataset.context || 'general'

        console.log("Question:", question, "Context:", context)

        if (this.hasAiInputTarget) {
          // Pour la sidebar index, remplir directement et envoyer
          if (e.target.closest('.ai-sidebar')) {
            console.log("In sidebar, setting input value and sending...")
            this.aiInputTarget.value = question
            this.currentContext = context
            this.sendAIMessage(e)
          } else {
            // Pour les modaux, utiliser le comportement original
            this.aiInputTarget.value = this.getExpandedQuestion(question)
            this.sendAIMessage(e)
          }
        } else {
          console.log("AI Input target not found for quick questions!")
        }
      })
    })
  }

  // Envoyer message IA
  async sendAIMessage(event) {
    event.preventDefault()

    if (!this.hasAiInputTarget) return

    const message = this.aiInputTarget.value.trim()
    if (!message) return

    // Désactiver l'interface pendant l'envoi
    this.setLoadingState(true)

    try {
      // Ajouter message utilisateur à la conversation
      this.addMessageToConversation('user', message)
      this.aiInputTarget.value = ''

      // Préparer les données pour l'API
      const requestData = {
        ai_consultation: {
          message: message,
          conversation_history: this.getConversationHistory(),
          context: this.buildContext()
        }
      }

      // Récupérer le token CSRF
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
      console.log("CSRF Token:", csrfToken)
      console.log("Request data:", requestData)

      // Appel à l'API IA
      const response = await fetch('/api/ai_consultations', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify(requestData)
      })

      console.log("Response status:", response.status)
      console.log("Response headers:", response.headers.get('content-type'))

      console.log("Response status:", response.status)
      console.log("Response headers:", response.headers.get('content-type'))

      const data = await response.json()
      console.log("Response data:", data)

      if (data.success) {
        // Ajouter la réponse IA à la conversation
        this.addMessageToConversation('ai', data.response)
      } else {
        // Afficher l'erreur ou la réponse de fallback
        const errorMessage = data.fallback_response || data.error || "Désolé, je rencontre des difficultés techniques."
        this.addMessageToConversation('ai', errorMessage)
        console.error('AI API Error:', data.error)
      }

    } catch (error) {
      console.error('Network Error:', error)
      this.addMessageToConversation('ai', "Je rencontre des problèmes de connexion. Veuillez réessayer dans quelques instants.")
    } finally {
      // Réactiver l'interface
      this.setLoadingState(false)
    }
  }

  // Formater le message IA pour une meilleure lisibilité
  formatAIMessage(message) {
    // Convertir les sauts de ligne doubles en paragraphes
    let formatted = message.replace(/\n\n/g, '</p><p>')

    // Remplacer les sauts de ligne simples par <br>
    formatted = formatted.replace(/\n/g, '<br>')

    // Formater les listes avec puces
    formatted = formatted.replace(/•\s*(.*?)(?=<br>|$)/g, '<li>$1</li>')
    formatted = formatted.replace(/(<li>.*?<\/li>)+/g, '<ul class="list-unstyled ms-3">$&</ul>')

    // Formater les titres avec émojis et étoiles
    formatted = formatted.replace(/\*\*(.*?)\*\*\s*:/g, '<div class="section-title mt-3 mb-2"><span class="fw-bold text-success">$1</span></div>')

    // Formater les éléments numérotés (1️⃣, 2️⃣, etc.)
    formatted = formatted.replace(/([1-9]️⃣)\s*(.*?)(?=<br>|$)/g, '<div class="numbered-item d-flex align-items-start mb-2"><span class="me-2">$1</span><span>$2</span></div>')

    // Formater les points avec émojis au début de ligne
    formatted = formatted.replace(/(🔹|🎯|💰|📋|⚠️|✅|🚨|💡|📊|🔧|⏰)\s*(.*?)(?=<br>|$)/g, '<div class="emoji-item d-flex align-items-start mb-2"><span class="me-2 text-primary">$1</span><span>$2</span></div>')

    // Formater le texte en gras restant
    formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<strong class="text-primary">$1</strong>')

    // Nettoyer et encapsuler dans des paragraphes
    if (!formatted.startsWith('<')) {
      formatted = '<p>' + formatted + '</p>'
    }

    return formatted
  }

  // Ajouter message à la conversation
  addMessageToConversation(sender, message) {
    if (!this.hasConversationAreaTarget) return

    const messageDiv = document.createElement('div')
    const isInSidebar = this.conversationAreaTarget.closest('.ai-sidebar')

    if (isInSidebar) {
      // Style pour la sidebar index
      messageDiv.className = sender === 'ai' ? 'ai-message mb-3' : 'user-message mb-3'

      if (sender === 'ai') {
        const formattedMessage = this.formatAIMessage(message)
        messageDiv.innerHTML = `
          <div class="d-flex align-items-start">
            <div class="ai-avatar bg-success rounded-circle d-flex align-items-center justify-content-center me-2" style="width: 32px; height: 32px; flex-shrink: 0;">
              <i class="bi bi-robot text-white small"></i>
            </div>
            <div class="message-content bg-light rounded-3 p-3 flex-grow-1">
              <div class="message-text">${formattedMessage}</div>
              <small class="text-muted">À l'instant</small>
            </div>
          </div>
        `
      } else {
        messageDiv.innerHTML = `
          <div class="d-flex align-items-start justify-content-end">
            <div class="message-content bg-primary text-white rounded-3 p-3" style="max-width: 80%;">
              <div class="message-text">${message}</div>
              <small class="opacity-75">Vous</small>
            </div>
            <div class="user-avatar bg-secondary rounded-circle d-flex align-items-center justify-content-center ms-2" style="width: 32px; height: 32px; flex-shrink: 0;">
              <i class="bi bi-person text-white small"></i>
            </div>
          </div>
        `
      }
    } else {
      // Style original pour les modaux
      messageDiv.className = sender === 'ai' ? 'ai-message' : 'user-message'

      if (sender === 'ai') {
        const formattedMessage = this.formatAIMessage(message)
        messageDiv.innerHTML = `
          <div class="message-header">
            <strong>🤖 Assistant IA</strong>
            <small class="text-muted">À l'instant</small>
          </div>
          <div class="message-content">
            ${formattedMessage}
          </div>
        `
      } else {
        messageDiv.innerHTML = `
          <div class="user-message-content" style="background: #007bff; color: white; padding: 1rem; border-radius: 8px; margin-bottom: 1rem; text-align: right;">
            <strong>Vous :</strong> ${message}
          </div>
        `
      }
    }

    this.conversationAreaTarget.appendChild(messageDiv)
    this.conversationAreaTarget.scrollTop = this.conversationAreaTarget.scrollHeight
  }

  // Gestion de l'état de chargement
  setLoadingState(isLoading) {
    if (this.hasAiSendButtonTarget) {
      this.aiSendButtonTarget.disabled = isLoading
      this.aiSendButtonTarget.innerHTML = isLoading ?
        '<i class="fas fa-spinner fa-spin"></i> Réflexion...' :
        '<i class="fas fa-paper-plane"></i> Envoyer'
    }

    if (this.hasAiInputTarget) {
      this.aiInputTarget.disabled = isLoading
      this.aiInputTarget.placeholder = isLoading ?
        "L'IA réfléchit..." :
        "Posez votre question sur la rénovation..."
    }

    // Ajouter indicateur visuel de chargement
    if (isLoading) {
      this.showTypingIndicator()
    } else {
      this.hideTypingIndicator()
    }
  }

  // Indicateur de frappe IA
  showTypingIndicator() {
    if (!this.hasConversationAreaTarget) return

    const typingDiv = document.createElement('div')
    typingDiv.id = 'ai-typing-indicator'
    const isInSidebar = this.conversationAreaTarget.closest('.ai-sidebar')

    if (isInSidebar) {
      typingDiv.className = 'ai-message mb-3 typing-indicator'
      typingDiv.innerHTML = `
        <div class="d-flex align-items-start">
          <div class="ai-avatar bg-success rounded-circle d-flex align-items-center justify-content-center me-2" style="width: 32px; height: 32px; flex-shrink: 0;">
            <i class="bi bi-robot text-white small"></i>
          </div>
          <div class="message-content bg-light rounded-3 p-3 flex-grow-1">
            <div class="message-text">
              <div class="typing-dots">
                <span></span><span></span><span></span>
              </div>
            </div>
            <small class="text-muted">écrit...</small>
          </div>
        </div>
      `
    } else {
      typingDiv.className = 'ai-message typing-indicator'
      typingDiv.innerHTML = `
        <div class="message-header">
          <strong>🤖 Assistant IA</strong>
          <small class="text-muted">écrit...</small>
        </div>
        <div class="message-content">
          <div class="typing-dots">
            <span></span><span></span><span></span>
          </div>
        </div>
      `
    }

    this.conversationAreaTarget.appendChild(typingDiv)
    this.conversationAreaTarget.scrollTop = this.conversationAreaTarget.scrollHeight
  }

  hideTypingIndicator() {
    const indicator = document.getElementById('ai-typing-indicator')
    if (indicator) {
      indicator.remove()
    }
  }

  // Construire l'historique de conversation pour l'API
  getConversationHistory() {
    if (!this.hasConversationAreaTarget) return []

    const messages = []
    const messageElements = this.conversationAreaTarget.querySelectorAll('.ai-message, .user-message')

    messageElements.forEach(element => {
      if (element.classList.contains('typing-indicator')) return

      const isAI = element.classList.contains('ai-message')
      const content = element.querySelector('.message-content, .user-message-content')

      if (content) {
        messages.push({
          role: isAI ? 'assistant' : 'user',
          content: content.textContent.trim().replace(/^(🤖 Assistant IA|Vous :)\s*/, '')
        })
      }
    })

    return messages.slice(-10) // Garder seulement les 10 derniers messages
  }

  // Construire le contexte pour l'IA
  buildContext() {
    const context = {
      panel_context: this.currentContext || 'general'
    }

    // Extraire des informations du DOM si disponibles
    const locationElement = document.querySelector('[data-user-location]')
    if (locationElement) {
      context.location = locationElement.dataset.userLocation
    }

    const budgetElement = document.querySelector('[data-total-budget]')
    if (budgetElement) {
      context.budget = parseInt(budgetElement.dataset.totalBudget)
    }

    const primesElement = document.querySelector('[data-total-primes]')
    if (primesElement) {
      context.total_primes = parseInt(primesElement.dataset.totalPrimes)
    } else {
      // Valeurs par défaut extraites des panneaux visibles
      context.total_primes = 12450
      context.property_type = 'maison individuelle'
      context.location = 'Wallonie'
    }

    // Extraire les priorités des éléments cochés
    const checkedPriorities = []
    document.querySelectorAll('.checklist input[type="checkbox"]:checked').forEach(checkbox => {
      const label = checkbox.closest('label')
      if (label) {
        checkedPriorities.push(label.textContent.trim())
      }
    })
    context.priorities = checkedPriorities

    // Ajouter des informations contextuelles spécifiques au panneau
    switch (this.currentContext) {
      case 'synthesis':
        context.focus = 'optimisation des primes et montants'
        context.current_primes = ['Isolation Toiture (4,200€)', 'Pompe à Chaleur (3,800€)', 'Prime Façade (2,500€)']
        break
      case 'obligations':
        context.focus = 'obligations légales et documents requis'
        context.compliance_status = '73%'
        break
      case 'technical':
        context.focus = 'conformité technique et spécifications'
        context.compliance_status = '68%'
        break
      case 'timeline':
        context.focus = 'planning optimal et timing'
        context.project_duration = '6-8 semaines'
        break
      default:
        context.focus = 'conseil général sur la rénovation'
    }

    return context
  }

  // Étendre les questions courtes
  getExpandedQuestion(shortQuestion) {
    const expansions = {
      'Optimiser les combinaisons': 'Comment puis-je optimiser les combinaisons de primes pour maximiser le montant total ?',
      'Timing optimal': 'Quel est le timing optimal pour déposer mes demandes de primes ?',
      'Documents requis': 'Quels sont tous les documents requis pour mes primes ?',
      'Entrepreneurs agréés': 'Comment trouver des entrepreneurs agréés pour mes travaux ?'
    }
    return expansions[shortQuestion] || shortQuestion
  }

  // Mettre à jour le score de préparation
  updatePreparationScore() {
    const checkboxes = document.querySelectorAll('.checklist input[type="checkbox"]')
    const checked = Array.from(checkboxes).filter(cb => cb.checked).length
    const total = checkboxes.length
    const percentage = Math.round((checked / total) * 100)

    // Mettre à jour l'affichage du score
    const scoreValue = document.querySelector('.score-value')
    const progressBar = document.querySelector('.preparation-score .progress-bar')

    if (scoreValue) scoreValue.textContent = percentage + '%'
    if (progressBar) {
      progressBar.style.width = percentage + '%'
      progressBar.className = `progress-bar ${percentage < 50 ? 'bg-danger' : percentage < 80 ? 'bg-warning' : 'bg-success'}`
    }

    // Mettre à jour le statut
    const remaining = total - checked
    const statusText = document.querySelector('.preparation-score small')
    if (statusText) {
      if (remaining === 0) {
        statusText.textContent = '🎉 Parfait ! Vous êtes prêt pour le dépôt'
        statusText.className = 'text-success'
      } else {
        statusText.textContent = `Encore ${remaining} étape${remaining > 1 ? 's' : ''} pour être prêt au dépôt`
        statusText.className = 'text-muted'
      }
    }
  }
}
