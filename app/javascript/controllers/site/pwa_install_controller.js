// Contrôleur Stimulus pour le prompt d'installation PWA
// Gère Android (beforeinstallprompt) et iOS (Safari — pas d'événement natif)
import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY    = "pwa-install-dismissed"
const DISMISS_DAYS   = 30   // Ne plus afficher pendant 30 jours après refus
const MIN_VISITS     = 2    // Afficher seulement à partir de la 2ème visite

export default class extends Controller {
  static targets = ["banner", "iosBanner"]

  connect() {
    this.deferredPrompt = null
    this.checkAndShow()
  }

  checkAndShow() {
    if (this.isDismissed()) return
    if (!this.hasReachedMinVisits()) return
    if (this.isAlreadyInstalled()) return

    if (this.isIOS() && this.isIosSafari()) {
      this.showIosBanner()
    } else {
      this.waitForInstallPrompt()
    }
  }

  // ——— Android / Chrome ———————————————————————————————————————

  waitForInstallPrompt() {
    window.addEventListener("beforeinstallprompt", (e) => {
      e.preventDefault()
      this.deferredPrompt = e
      this.showAndroidBanner()
    }, { once: true })

    // Si déjà installé (app lancée depuis écran d'accueil) → pas de bannière
    window.addEventListener("appinstalled", () => {
      this.hideBanner()
      this.deferredPrompt = null
    }, { once: true })
  }

  async triggerInstall() {
    if (!this.deferredPrompt) return

    this.deferredPrompt.prompt()
    const { outcome } = await this.deferredPrompt.userChoice
    this.deferredPrompt = null

    if (outcome === "accepted") {
      this.hideBanner()
    } else {
      this.dismiss()
    }
  }

  // ——— iOS / Safari ————————————————————————————————————————————

  showIosBanner() {
    if (this.hasIosBannerTarget) {
      this.iosBannerTarget.classList.remove("d-none")
    }
  }

  showAndroidBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("d-none")
    }
  }

  hideBanner() {
    if (this.hasBannerTarget) this.bannerTarget.classList.add("d-none")
    if (this.hasIosBannerTarget) this.iosBannerTarget.classList.add("d-none")
  }

  // ——— Actions (data-action dans le HTML) ———————————————————

  install() {
    this.triggerInstall()
  }

  close() {
    this.dismiss()
    this.hideBanner()
  }

  // ——— Helpers ——————————————————————————————————————————————

  isDismissed() {
    const ts = localStorage.getItem(STORAGE_KEY)
    if (!ts) return false
    const daysSince = (Date.now() - parseInt(ts)) / 86400000
    return daysSince < DISMISS_DAYS
  }

  dismiss() {
    localStorage.setItem(STORAGE_KEY, Date.now().toString())
  }

  isAlreadyInstalled() {
    return window.matchMedia("(display-mode: standalone)").matches
      || window.navigator.standalone === true
  }

  hasReachedMinVisits() {
    const visits = parseInt(localStorage.getItem("pwa-visit-count") || "0") + 1
    localStorage.setItem("pwa-visit-count", visits.toString())
    return visits >= MIN_VISITS
  }

  isIOS() {
    return /iPhone|iPad|iPod/.test(navigator.userAgent)
  }

  isIosSafari() {
    // Safari iOS = pas de Chrome ni Firefox
    return /Safari/.test(navigator.userAgent)
      && !/Chrome|CriOS|FxiOS/.test(navigator.userAgent)
  }
}
