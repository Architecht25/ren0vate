// Stimulus controller for decision hub dynamic functionality
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "simulationSelector",
    "selectionPrimesSection",
    "resumeSection",
    "documentsSection",
    "planningSection",
    "technicalSection",
    "facturesSection",
    "conseilsFacturesSection",
    "auditLogementWallonieSection",
    "certificatPebFlandreSection",
    "conseilsAcpSection",
    "conseilsExemplariteSection",
    "verificationConsultanceSection",
    "verificationEntrepreneurSection",
    "conseilsEntrepreneursSection",
    "aidesTransitionSection",
    "aidesInvestissementsSection",
    "aidesRhFormationSection",
    "aidesExpertisesSection",
    "aiMessages",
    "aiInput",
    "aiSendButton",
    "currentSimulationId"
  ]

  static values = {
    loadSimulationUrl: String,
    aiConsultationUrl: String,
    currentSimulationId: Number
  }

  connect() {
    this.isLoading = false
    this.aiContext = []

    // Load initial simulation if present
    if (this.currentSimulationIdValue) {
      this.loadSimulationData(this.currentSimulationIdValue)
    }

    // Setup AI input handlers
    this.setupAIInput()
  }

  // Section tab switching
  switchSection(event) {
    event.preventDefault()
    const section = event.currentTarget.dataset.section

    if (!section) return


    // Remove active class from all tabs
    this.element.querySelectorAll('.step-tab').forEach(tab => {
      tab.classList.remove('active')
    })

    // Add active class to clicked tab
    event.currentTarget.classList.add('active')

    // Hide all sections
    this.element.querySelectorAll('.section-content').forEach(content => {
      content.style.display = 'none'
    })

    // Show selected section
    const sectionContent = this.element.querySelector(`.section-content[data-section="${section}"]`)
    if (sectionContent) {
      sectionContent.style.display = 'block'
    }

    // Update URL without reloading
    const url = new URL(window.location)
    url.searchParams.set('section', section)
    window.history.pushState({}, '', url)
  }

  // Simulation selection change
  simulationChanged(event) {
    const simulationId = event.target.value

    if (simulationId && simulationId !== "") {
      // Recharger la page avec la simulation sélectionnée
      const currentUrl = new URL(window.location.href)
      currentUrl.searchParams.set('simulation_id', simulationId)
      window.location.href = currentUrl.toString()
    }
  }

  // Load simulation data via AJAX
  async loadSimulationData(simulationId) {
    if (this.isLoading) return

    this.isLoading = true
    this.showLoadingState()

    try {
      const url = this.loadSimulationUrlValue.replace('SIMULATION_ID', simulationId)
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content")
        }
      })

      if (response.ok) {
        const responseData = await response.json()
        if (responseData.success && responseData.data) {
          this.updateSections(responseData.data)
          this.updateAIContext(responseData.data.ai_context || {})
        } else {
          this.showError(responseData.error || "Erreur lors du chargement")
        }
      } else {
        this.showError("Erreur lors du chargement des données")
      }
    } catch (error) {
      this.showError("Erreur de connexion")
    } finally {
      this.isLoading = false
      this.hideLoadingState()
    }
  }

  // Dispose Bootstrap instances inside a section before replacing innerHTML
  disposeBootstrapInstances(element) {
    if (!element || typeof bootstrap === 'undefined') return
    element.querySelectorAll('.modal').forEach(el => {
      bootstrap.Modal.getInstance(el)?.dispose()
    })
    element.querySelectorAll('.collapse').forEach(el => {
      bootstrap.Collapse.getInstance(el)?.dispose()
    })
  }

  // Update all sections with new data
  updateSections(sectionsData) {
    if (this.hasResumeSectionTarget) {
      this.disposeBootstrapInstances(this.resumeSectionTarget)
      this.resumeSectionTarget.innerHTML = sectionsData.resume || ""
    }

    if (this.hasDocumentsSectionTarget) {
      this.disposeBootstrapInstances(this.documentsSectionTarget)
      this.documentsSectionTarget.innerHTML = sectionsData.documents || ""
    }

    if (this.hasPlanningSectionTarget) {
      this.disposeBootstrapInstances(this.planningSectionTarget)
      this.planningSectionTarget.innerHTML = sectionsData.planning || ""
    }

    if (this.hasTechnicalSectionTarget) {
      this.disposeBootstrapInstances(this.technicalSectionTarget)
      this.technicalSectionTarget.innerHTML = sectionsData.technical || ""
    }

    // Re-bind quick question buttons
    this.bindQuickQuestionButtons()
  }

  // Clear all sections
  clearSections() {
    const emptyMessage = '<div class="text-center py-4"><i class="bi bi-info-circle text-muted fs-1"></i><p class="mt-2 text-muted">Sélectionnez une simulation pour voir les détails</p></div>'

    if (this.hasResumeSectionTarget) {
      this.disposeBootstrapInstances(this.resumeSectionTarget)
      this.resumeSectionTarget.innerHTML = emptyMessage
    }
    if (this.hasDocumentsSectionTarget) {
      this.disposeBootstrapInstances(this.documentsSectionTarget)
      this.documentsSectionTarget.innerHTML = emptyMessage
    }
    if (this.hasPlanningSectionTarget) {
      this.disposeBootstrapInstances(this.planningSectionTarget)
      this.planningSectionTarget.innerHTML = emptyMessage
    }
    if (this.hasTechnicalSectionTarget) {
      this.disposeBootstrapInstances(this.technicalSectionTarget)
      this.technicalSectionTarget.innerHTML = emptyMessage
    }
  }

  // Show loading state
  showLoadingState() {
    const loadingMessage = '<div class="text-center py-4"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Chargement...</span></div><p class="mt-2 text-muted">Chargement des données...</p></div>'

    if (this.hasResumeSectionTarget) {
      this.disposeBootstrapInstances(this.resumeSectionTarget)
      this.resumeSectionTarget.innerHTML = loadingMessage
    }
    if (this.hasDocumentsSectionTarget) {
      this.disposeBootstrapInstances(this.documentsSectionTarget)
      this.documentsSectionTarget.innerHTML = loadingMessage
    }
    if (this.hasPlanningSectionTarget) {
      this.disposeBootstrapInstances(this.planningSectionTarget)
      this.planningSectionTarget.innerHTML = loadingMessage
    }
    if (this.hasTechnicalSectionTarget) {
      this.disposeBootstrapInstances(this.technicalSectionTarget)
      this.technicalSectionTarget.innerHTML = loadingMessage
    }
  }

  // Hide loading state
  hideLoadingState() {
    // Loading state is replaced by actual content in updateSections
  }

  // Setup AI input functionality
  setupAIInput() {
    if (this.hasAiInputTarget) {
      this.aiInputTarget.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault()
          this.sendAIMessage()
        }
      })
    }
  }

  // Send AI message
  async sendAIMessage() {
    const message = this.aiInputTarget.value.trim()
    if (!message || this.isLoading) return

    // Add user message to chat
    this.addAIMessage("user", message)
    this.aiInputTarget.value = ""

    // Show AI typing indicator
    this.showAITyping()

    try {
      const response = await fetch(this.aiConsultationUrlValue, {
        method: 'POST',
        body: JSON.stringify({
          question: message,
          simulation_id: this.currentSimulationIdValue,
          context: this.aiContext
        }),
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content")
        }
      })

      if (response.ok) {
        const data = await response.json()
        this.hideAITyping()
        this.addAIMessage("assistant", data.response)

        // Update context if provided
        if (data.updated_context) {
          this.updateAIContext(data.updated_context)
        }
      } else {
        this.hideAITyping()
        this.addAIMessage("system", "Désolé, une erreur s'est produite. Veuillez réessayer.")
      }
    } catch (error) {
      this.hideAITyping()
      this.addAIMessage("system", "Erreur de connexion. Veuillez vérifier votre connexion internet.")
    }
  }

  // Handle quick question buttons
  quickQuestion(event) {
    const question = event.currentTarget.dataset.question
    if (question) {
      this.aiInputTarget.value = question
      this.sendAIMessage()
    }
  }

  // Bind quick question buttons after content update
  bindQuickQuestionButtons() {
    const quickButtons = document.querySelectorAll('.quick-question')
    quickButtons.forEach(button => {
      button.addEventListener('click', (e) => this.quickQuestion(e))
    })
  }

  // Add message to AI chat
  addAIMessage(sender, content) {
    if (!this.hasAiMessagesTarget) return

    const messageElement = document.createElement('div')
    messageElement.className = `mb-3 ${sender === 'user' ? 'text-end' : ''}`

    const timestamp = new Date().toLocaleTimeString('fr-FR', {
      hour: '2-digit',
      minute: '2-digit'
    })

    let messageClass = 'bg-light'
    let icon = 'bi-person'

    if (sender === 'user') {
      messageClass = 'bg-primary text-white'
      icon = 'bi-person-fill'
    } else if (sender === 'assistant') {
      messageClass = 'bg-info text-white'
      icon = 'bi-robot'
    } else if (sender === 'system') {
      messageClass = 'bg-warning text-dark'
      icon = 'bi-info-circle'
    }

    messageElement.innerHTML = `
      <div class="d-inline-block p-3 rounded ${messageClass}" style="max-width: 85%;">
        <div class="d-flex align-items-start">
          <i class="bi ${icon} me-2 mt-1"></i>
          <div class="flex-grow-1">
            <div class="mb-1">${content}</div>
            <small class="opacity-75">${timestamp}</small>
          </div>
        </div>
      </div>
    `

    this.aiMessagesTarget.appendChild(messageElement)
    this.aiMessagesTarget.scrollTop = this.aiMessagesTarget.scrollHeight
  }

  // Show AI typing indicator
  showAITyping() {
    if (!this.hasAiMessagesTarget) return

    const typingElement = document.createElement('div')
    typingElement.id = 'ai-typing-indicator'
    typingElement.className = 'mb-3'
    typingElement.innerHTML = `
      <div class="d-inline-block p-3 rounded bg-light">
        <div class="d-flex align-items-center">
          <i class="bi bi-robot me-2"></i>
          <div class="typing-dots">
            <span class="dot"></span>
            <span class="dot"></span>
            <span class="dot"></span>
          </div>
        </div>
      </div>
    `

    this.aiMessagesTarget.appendChild(typingElement)
    this.aiMessagesTarget.scrollTop = this.aiMessagesTarget.scrollHeight
  }

  // Hide AI typing indicator
  hideAITyping() {
    const typingIndicator = document.getElementById('ai-typing-indicator')
    if (typingIndicator) {
      typingIndicator.remove()
    }
  }

  // Update AI context
  updateAIContext(newContext) {
    this.aiContext = newContext || []
  }

  // Show error message
  showError(message) {
    this.addAIMessage("system", `❌ ${message}`)
  }
}
