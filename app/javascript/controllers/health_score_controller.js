import { Controller } from "@hotwired/stimulus"

// IA #3 — Score Santé Projet /10
// Charge le score via GET /projects/:id/score_sante et anime l'affichage
export default class extends Controller {
  static targets = [
    "loadingState", "errorState", "resultState",
    "scoreValue", "scoreCircle", "scoreGrade", "scoreLabel", "scoreDate",
    "indicators", "recommendations", "computedAt",
    "refreshBtn", "refreshIcon"
  ]

  static values = { url: String }

  connect() {
    this.load()
  }

  refresh() {
    this.showLoading()
    this.load()
  }

  async load() {
    try {
      this.showLoading()
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" }
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const data = await response.json()
      this.render(data)
    } catch (err) {
      console.error("HealthScore error:", err)
      this.showError()
    }
  }

  render(data) {
    // Score principal
    const total = parseFloat(data.total) || 0
    this.scoreValueTarget.textContent = total.toFixed(1)
    this.scoreGradeTarget.textContent = data.grade || ""
    this.scoreLabelTarget.textContent = data.label || ""
    this.computedAtTarget.textContent = this.formatDate(data.computed_at)

    // Couleur selon grade
    const color = this.colorForScore(total)
    this.scoreValueTarget.style.color = color

    // Arc SVG (dashoffset)
    const circumference = 97.4
    const offset = circumference - (total / 10) * circumference
    const circle = this.scoreCircleTarget
    circle.style.stroke = color
    circle.style.strokeDashoffset = offset

    // Indicateurs
    this.renderIndicators(data.indicators || [])

    // Recommandations
    this.renderRecommendations(data.recommendations || [])

    // Transition
    this.loadingStateTarget.classList.add("d-none")
    this.errorStateTarget.classList.add("d-none")
    this.resultStateTarget.classList.remove("d-none")

    // Animation refresh icon
    this.refreshIconTarget.classList.remove("spin")
    this.refreshBtnTarget.disabled = false
  }

  renderIndicators(indicators) {
    const container = this.indicatorsTarget
    container.innerHTML = indicators.map(ind => {
      const pct   = Math.round((ind.score / ind.max) * 100)
      const color = ind.color || "#6b7280"
      const icon  = ind.icon || "bi-circle"
      const neutral = ind.neutral ? " (données insuffisantes)" : ""

      return `
        <div class="mb-3">
          <div class="d-flex justify-content-between align-items-center mb-1">
            <div class="d-flex align-items-center gap-2">
              <i class="bi ${icon}" style="color:${color}; font-size:0.85rem;"></i>
              <span style="font-size:0.82rem; font-weight:500;">${this.escapeHtml(ind.name)}</span>
            </div>
            <span style="font-size:0.8rem; color:${color}; font-weight:600;">${parseFloat(ind.score).toFixed(1)}/${ind.max}</span>
          </div>
          <div class="progress rounded-pill" style="height:6px; background:#e2e8f0;">
            <div class="progress-bar rounded-pill" role="progressbar"
                 style="width:${pct}%; background:${color}; transition:width 0.8s ease;"
                 aria-valuenow="${pct}" aria-valuemin="0" aria-valuemax="100">
            </div>
          </div>
          <div class="text-muted mt-1" style="font-size:0.72rem;">${this.escapeHtml(ind.detail)}${neutral}</div>
        </div>
      `
    }).join("")
  }

  renderRecommendations(recs) {
    const list = this.recommendationsTarget
    list.innerHTML = recs.map(rec => `
      <li class="d-flex align-items-start gap-2" style="font-size:0.83rem;">
        <span style="line-height:1.5;">${this.escapeHtml(rec)}</span>
      </li>
    `).join("")
  }

  showLoading() {
    this.loadingStateTarget.classList.remove("d-none")
    this.errorStateTarget.classList.add("d-none")
    this.resultStateTarget.classList.add("d-none")
    this.refreshIconTarget.classList.add("spin")
    this.refreshBtnTarget.disabled = true
  }

  showError() {
    this.loadingStateTarget.classList.add("d-none")
    this.errorStateTarget.classList.remove("d-none")
    this.resultStateTarget.classList.add("d-none")
    this.refreshIconTarget.classList.remove("spin")
    this.refreshBtnTarget.disabled = false
  }

  colorForScore(score) {
    if (score >= 8)  return "#16a34a"  // vert
    if (score >= 6)  return "#d97706"  // jaune
    return "#dc2626"                    // rouge
  }

  formatDate(iso) {
    if (!iso) return "—"
    const d = new Date(iso)
    return d.toLocaleDateString("fr-BE", { day: "2-digit", month: "2-digit", year: "numeric",
                                            hour: "2-digit", minute: "2-digit" })
  }

  escapeHtml(str) {
    const el = document.createElement("div")
    el.appendChild(document.createTextNode(String(str || "")))
    return el.innerHTML
  }
}
