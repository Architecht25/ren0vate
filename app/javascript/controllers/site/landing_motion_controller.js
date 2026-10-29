import { Controller } from "@hotwired/stimulus"
import { animate, inView, stagger } from "motion"

// Anime la landing V2 : reveal au scroll (avec stagger sur les groupes),
// compteurs et barres de progression animés, nav qui se densifie au scroll.
// Dégradation sûre : rien n'est caché par défaut en HTML/CSS, donc un échec
// de chargement du module "motion" laisse simplement la page statique mais complète.
export default class extends Controller {
  connect() {
    this.cleanups = []
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches

    this.setupNavScroll()

    if (this.reducedMotion) return

    this.setupReveals()
    this.setupCounters()
    this.setupBars()
  }

  disconnect() {
    this.cleanups.forEach((cleanup) => cleanup && cleanup())
    if (this.navScrollHandler) window.removeEventListener("scroll", this.navScrollHandler)
  }

  setupNavScroll() {
    const nav = this.element.querySelector(".ren-landing-nav")
    if (!nav) return

    this.navScrollHandler = () => nav.classList.toggle("is-scrolled", window.scrollY > 24)
    window.addEventListener("scroll", this.navScrollHandler, { passive: true })
    this.navScrollHandler()
  }

  setupReveals() {
    const easeOutExpo = [0.16, 1, 0.3, 1]

    this.element.querySelectorAll("[data-reveal-group]").forEach((group) => {
      const items = Array.from(group.querySelectorAll("[data-reveal]"))
      if (!items.length) return

      items.forEach((item) => this.primeForReveal(item))

      const stop = inView(group, () => {
        animate(items, { opacity: [0, 1], y: [40, 0], scale: [0.95, 1] }, { duration: 0.7, delay: stagger(0.12), ease: easeOutExpo })
        stop()
      }, { amount: 0.15 })
      this.cleanups.push(stop)
    })

    const grouped = this.element.querySelectorAll("[data-reveal-group] [data-reveal]")
    const standalone = Array.from(this.element.querySelectorAll("[data-reveal]")).filter((el) => !Array.from(grouped).includes(el))

    standalone.forEach((el) => {
      this.primeForReveal(el)

      const stop = inView(el, () => {
        animate(el, { opacity: [0, 1], y: [40, 0], scale: [0.95, 1] }, { duration: 0.7, ease: easeOutExpo })
        stop()
      }, { amount: 0.25 })
      this.cleanups.push(stop)
    })
  }

  primeForReveal(el) {
    el.style.opacity = 0
    el.style.transform = "translateY(40px) scale(0.95)"
  }

  setupCounters() {
    this.element.querySelectorAll("[data-count-target]").forEach((el) => {
      const target = parseFloat(el.dataset.countTarget)
      if (Number.isNaN(target)) return

      const prefix = el.dataset.countPrefix || ""
      const suffix = el.dataset.countSuffix || ""
      const decimals = el.dataset.countDecimals ? parseInt(el.dataset.countDecimals, 10) : 0

      el.textContent = this.formatCount(0, prefix, suffix, decimals)

      const stop = inView(el, () => {
        animate(0, target, {
          duration: 1.1,
          ease: "easeOut",
          onUpdate: (latest) => {
            el.textContent = this.formatCount(latest, prefix, suffix, decimals)
          },
        })
        stop()
      }, { amount: 0.6 })
      this.cleanups.push(stop)
    })
  }

  formatCount(value, prefix, suffix, decimals) {
    const formatted = value.toLocaleString("fr-BE", { maximumFractionDigits: decimals, minimumFractionDigits: decimals })
    return `${prefix}${formatted}${suffix}`
  }

  setupBars() {
    this.element.querySelectorAll("[data-bar-target-width]").forEach((el) => {
      const target = el.dataset.barTargetWidth
      el.style.width = "0%"

      const stop = inView(el, () => {
        animate(el, { width: ["0%", target] }, { duration: 0.8, ease: "easeOut" })
        stop()
      }, { amount: 0.4 })
      this.cleanups.push(stop)
    })
  }
}
