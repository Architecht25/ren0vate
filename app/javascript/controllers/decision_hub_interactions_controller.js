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
    this.setupAIInput()
    this.setupObligationCheckboxes()
    this.setupQuickQuestions()
  }

  // Configuration des interactions IA
  setupAIInput() {
    if (this.hasAiSendButtonTarget && this.hasAiInputTarget) {
      this.aiSendButtonTarget.addEventListener('click', (e) => {
        this.sendAIMessage(e)
      })

      this.aiInputTarget.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault()
          this.sendAIMessage(e)
        }
      })
    }
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
    document.querySelectorAll('.quick-questions .btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const question = e.target.textContent
        if (this.hasAiInputTarget) {
          this.aiInputTarget.value = this.getExpandedQuestion(question)
          this.sendAIMessage(e)
        }
      })
    })
  }

  // Envoyer message IA
  sendAIMessage(event) {
    event.preventDefault()

    if (!this.hasAiInputTarget) return

    const message = this.aiInputTarget.value.trim()
    if (message) {
      // Ajouter message utilisateur
      this.addMessageToConversation('user', message)

      // Simuler réponse IA (à remplacer par vraie intégration)
      setTimeout(() => {
        this.addMessageToConversation('ai', this.generateMockAIResponse(message))
      }, 1500)

      this.aiInputTarget.value = ''
    }
  }

  // Ajouter message à la conversation
  addMessageToConversation(sender, message) {
    if (!this.hasConversationAreaTarget) return

    const messageDiv = document.createElement('div')
    messageDiv.className = sender === 'ai' ? 'ai-message' : 'user-message'

    if (sender === 'ai') {
      messageDiv.innerHTML = `
        <div class="message-header">
          <strong>🤖 Assistant IA</strong>
          <small class="text-muted">À l'instant</small>
        </div>
        <div class="message-content">
          <p>${message}</p>
        </div>
      `
    } else {
      messageDiv.innerHTML = `
        <div class="user-message-content" style="background: #007bff; color: white; padding: 1rem; border-radius: 8px; margin-bottom: 1rem; text-align: right;">
          <strong>Vous :</strong> ${message}
        </div>
      `
    }

    this.conversationAreaTarget.appendChild(messageDiv)
    this.conversationAreaTarget.scrollTop = this.conversationAreaTarget.scrollHeight
  }

  // Générer réponse IA mockée
  generateMockAIResponse(userMessage) {
    const responses = {
      'optimiser': 'Excellente question ! Pour optimiser vos primes, je recommande de commencer par la prime isolation toiture (4,200€) car elle a un délai court. Ensuite, vous pourrez combiner avec la pompe à chaleur pour obtenir une majoration de 15%. Cela porterait votre total à environ 13,250€.',
      'timing': 'Le timing optimal pour votre projet serait : 1) Dépôt prime isolation avant fin octobre (bonus hivernal), 2) Prime pompe à chaleur en novembre, 3) Prime façade au printemps. Cette séquence maximise vos aides.',
      'documents': 'Voici les documents essentiels : PEB valide (vous en avez un ?), devis détaillés entrepreneurs agréés, photos avant travaux, déclaration préalable commune. Je peux vous aider à prioriser selon votre situation.',
      'entrepreneurs': 'Pour vos primes, vous devez absolument choisir des entrepreneurs agréés RGE. Je peux vous recommander 3 entrepreneurs certifiés dans votre région avec de bons avis clients.'
    }

    const key = Object.keys(responses).find(k => userMessage.toLowerCase().includes(k))
    return key ? responses[key] : 'Je comprends votre question. Basé sur vos simulations de 12,450€ en Wallonie, je peux vous donner des conseils précis. Pouvez-vous me dire quel aspect vous préoccupe le plus : les délais, les documents requis, ou l\'optimisation des montants ?'
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
