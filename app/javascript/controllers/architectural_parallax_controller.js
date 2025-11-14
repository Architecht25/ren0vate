import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hero"]

  connect() {
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener('scroll', this.handleScroll, { passive: true })
  }

  disconnect() {
    window.removeEventListener('scroll', this.handleScroll)
  }

  handleScroll() {
    const scrolled = window.pageYOffset
    const heroElement = this.heroTarget

    if (scrolled > 50) {
      heroElement.classList.add('scrolled')
    } else {
      heroElement.classList.remove('scrolled')
    }

    // Parallax léger sur l'image de fond
    const parallaxValue = scrolled * 0.3
    heroElement.style.transform = `translateY(${parallaxValue}px)`
  }
}
