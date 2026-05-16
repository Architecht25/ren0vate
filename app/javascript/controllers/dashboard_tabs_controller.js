import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const saved = localStorage.getItem("property-dashboard-tab") || "mon-bien"
    this.switchTo(saved)
  }

  switch(event) {
    const tab = event.currentTarget.dataset.tab
    localStorage.setItem("property-dashboard-tab", tab)
    this.switchTo(tab)
  }

  switchTo(tab) {
    this.tabTargets.forEach(btn => {
      const active = btn.dataset.tab === tab
      btn.classList.toggle("btn-primary-custom", active)
      btn.classList.toggle("text-white", active)
      btn.classList.toggle("btn-outline-secondary", !active)
    })
    this.panelTargets.forEach(panel => {
      panel.style.display = panel.dataset.tab === tab ? "" : "none"
    })
  }
}
