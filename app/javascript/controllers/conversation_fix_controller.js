import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["conversationArea", "messageContent"]

  connect() {
    console.log("ConversationFix controller connecté")
    this.fixConversationLayout()

    // Observer pour les nouveaux messages
    if (this.hasConversationAreaTarget) {
      this.observer = new MutationObserver(() => {
        this.fixConversationLayout()
      })

      this.observer.observe(this.conversationAreaTarget, {
        childList: true,
        subtree: true
      })
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  fixConversationLayout() {
    console.log("Correction du layout de conversation")

    // Force les styles sur la zone de conversation
    if (this.hasConversationAreaTarget) {
      const area = this.conversationAreaTarget
      area.style.maxHeight = "350px"
      area.style.height = "350px"
      area.style.overflowY = "auto"
      area.style.overflowX = "hidden"
      area.style.width = "100%"
      area.style.maxWidth = "100%"
      area.style.boxSizing = "border-box"
      area.style.border = "2px solid #007bff"
      area.style.backgroundColor = "#f8f9fa"
      area.style.borderRadius = "8px"
      area.style.padding = "0.75rem"
    }

    // Force les styles sur tous les messages
    this.messageContentTargets.forEach(content => {
      content.style.width = "100%"
      content.style.maxWidth = "100%"
      content.style.wordWrap = "break-word"
      content.style.overflowWrap = "break-word"
      content.style.boxSizing = "border-box"

      // Force sur tous les éléments enfants
      const allElements = content.querySelectorAll("*")
      allElements.forEach(el => {
        el.style.maxWidth = "100%"
        el.style.wordWrap = "break-word"
        el.style.overflowWrap = "break-word"
        el.style.boxSizing = "border-box"
      })
    })

    console.log("Layout fixé pour", this.messageContentTargets.length, "messages")
  }
}
