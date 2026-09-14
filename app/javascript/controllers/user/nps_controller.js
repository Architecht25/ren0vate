import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scores", "commentBox", "comment", "submitArea", "thanks"]
  static values  = { url: String, csrf: String }

  selectScore(event) {
    const score = parseInt(event.currentTarget.dataset.score)
    this.selectedScore = score

    // Highlight selected
    this.scoresTarget.querySelectorAll('.nps-score-btn').forEach(btn => {
      btn.classList.remove('btn-primary', 'text-white')
      btn.classList.add('btn-outline-secondary')
    })
    event.currentTarget.classList.remove('btn-outline-secondary')
    event.currentTarget.classList.add('btn-primary', 'text-white')

    // Show comment + submit
    this.commentBoxTarget.classList.remove('d-none')
    this.submitAreaTarget.classList.remove('d-none')
  }

  async submit() {
    if (this.selectedScore === undefined) return

    const body = new FormData()
    body.append('score',   this.selectedScore)
    body.append('comment', this.commentTarget.value)
    body.append('trigger', 'day14')

    try {
      const res = await fetch(this.urlValue, {
        method:  'POST',
        headers: { 'X-CSRF-Token': this.csrfValue, 'Accept': 'application/json' },
        body
      })

      if (res.ok || res.status === 422) {
        this.scoresTarget.classList.add('d-none')
        this.commentBoxTarget.classList.add('d-none')
        this.submitAreaTarget.classList.add('d-none')
        this.thanksTarget.classList.remove('d-none')
      }
    } catch (e) {
      // Silent fail — ne pas bloquer l'utilisateur
    }
  }

  dismiss() {
    // Juste fermer — sera re-proposé dans 7 jours (géré côté serveur)
  }
}
