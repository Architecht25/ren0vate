// Contrôleur Stimulus pour la sidebar
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "content"]

  connect() {
    this.initializeSidebar()
    this.setupResponsive()
  }

  initializeSidebar() {
    // Marquer le lien actif
    this.highlightActiveLink()

    // Ouvrir automatiquement la section contenant le lien actif
    this.expandActiveSection()
  }

  setupResponsive() {
    // Gérer le redimensionnement de la fenêtre
    window.addEventListener('resize', () => {
      if (window.innerWidth >= 768) {
        this.closeSidebar()
      }
    })
  }

  highlightActiveLink() {
    const currentPath = window.location.pathname
    const links = document.querySelectorAll('.sidebar .nav-link')

    links.forEach(link => {
      const href = link.getAttribute('href')
      if (href && currentPath.includes(href) && href !== '/') {
        link.classList.add('active')
      }
    })
  }

  expandActiveSection() {
    const activeLink = document.querySelector('.sidebar .nav-link.active')
    if (activeLink) {
      const submenu = activeLink.closest('.nav-submenu')
      if (submenu && !submenu.classList.contains('show')) {
        const header = submenu.previousElementSibling
        if (header) {
          const bsCollapse = new bootstrap.Collapse(submenu, { toggle: true })
          header.setAttribute('aria-expanded', 'true')
        }
      }
    }
  }

  openSidebar() {
    const sidebar = document.getElementById('mainSidebar')
    const overlay = document.getElementById('sidebarOverlay')

    sidebar?.classList.add('active')
    overlay?.classList.add('active')
    document.body.style.overflow = 'hidden'
  }

  closeSidebar() {
    const sidebar = document.getElementById('mainSidebar')
    const overlay = document.getElementById('sidebarOverlay')

    sidebar?.classList.remove('active')
    overlay?.classList.remove('active')
    document.body.style.overflow = ''
  }

  toggleSidebar() {
    const sidebar = document.getElementById('mainSidebar')
    if (sidebar?.classList.contains('active')) {
      this.closeSidebar()
    } else {
      this.openSidebar()
    }
  }
}
