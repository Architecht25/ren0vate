// Contrôleur Stimulus pour la sidebar
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "content"]

  connect() {
    // Forcer l'état initial immédiatement sans animation
    this.forceInitialState()
    // Empêcher Bootstrap Collapse d'agir sur la sidebar
    this.preventBootstrapCollapse()
    // Désactiver les animations Bootstrap pour la sidebar
    this.disableBootstrapAnimations()
    this.setupCustomToggle()
    this.initializeSidebar()
    this.setupResponsive()
    // Intercepter les navigations Turbo
    this.setupTurboInterception()
    // Swipe-to-close sur mobile
    this.setupSwipeGesture()
  }

  forceInitialState() {
    // Forcer immédiatement tous les submenus "show" à être affichés sans transition
    const allSubmenus = document.querySelectorAll('.sidebar .nav-submenu')
    allSubmenus.forEach(submenu => {
      if (submenu.classList.contains('show')) {
        submenu.style.display = 'block'
        submenu.style.transition = 'none'
        submenu.style.height = 'auto'
      } else {
        submenu.style.display = 'none'
      }
    })
  }

  setupTurboInterception() {
    // Empêcher toute animation lors des navigations Turbo
    document.addEventListener('turbo:before-render', () => {
      const allSubmenus = document.querySelectorAll('.sidebar .nav-submenu')
      allSubmenus.forEach(submenu => {
        submenu.style.transition = 'none'
      })
    })
  }

  preventBootstrapCollapse() {
    // Supprimer les attributs data-bs-toggle pour empêcher Bootstrap de prendre le contrôle
    const sectionHeaders = document.querySelectorAll('.sidebar .section-header[data-bs-toggle]')
    sectionHeaders.forEach(header => {
      header.removeAttribute('data-bs-toggle')
    })
  }

  disableBootstrapAnimations() {
    // Désactiver toutes les animations collapse dans la sidebar
    const sidebarCollapses = document.querySelectorAll('.sidebar .collapse')
    sidebarCollapses.forEach(collapse => {
      // Forcer l'affichage immédiat sans animation
      if (collapse.classList.contains('show')) {
        collapse.style.display = 'block'
      }
    })
  }

  setupCustomToggle() {
    // Intercepter les clicks sur les headers de section pour gérer le toggle sans animation
    const sectionHeaders = document.querySelectorAll('.sidebar .section-header')
    sectionHeaders.forEach(header => {
      header.addEventListener('click', (e) => {
        e.preventDefault()
        e.stopPropagation()

        const targetId = header.getAttribute('data-bs-target')
        const target = document.querySelector(targetId)

        if (target) {
          const isExpanded = target.classList.contains('show')

          if (isExpanded) {
            target.classList.remove('show')
            target.style.display = 'none'
            header.setAttribute('aria-expanded', 'false')
          } else {
            target.classList.add('show')
            target.style.display = 'block'
            header.setAttribute('aria-expanded', 'true')
          }
        }
      })
    })
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
          // Désactiver l'animation en forçant l'affichage direct
          submenu.classList.add('show')
          submenu.style.display = 'block'
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

    // Sur mobile : fermer toutes les sections sauf celle contenant le lien actif
    if (window.innerWidth < 768) {
      this.collapseInactiveSectionsOnMobile()
    }
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

  collapseInactiveSectionsOnMobile() {
    // Trouve la section contenant le lien actif
    const activeLink = document.querySelector('.sidebar .nav-link.active')
    const activeSubmenu = activeLink?.closest('.nav-submenu')

    // Ferme toutes les sections sauf celle active
    const allSubmenus = document.querySelectorAll('.sidebar .nav-submenu')
    allSubmenus.forEach(submenu => {
      if (submenu !== activeSubmenu) {
        submenu.classList.remove('show')
        submenu.style.display = 'none'
        const header = submenu.previousElementSibling
        if (header) header.setAttribute('aria-expanded', 'false')
      }
    })

    // S'assurer que la section active est ouverte
    if (activeSubmenu) {
      activeSubmenu.classList.add('show')
      activeSubmenu.style.display = 'block'
      const header = activeSubmenu.previousElementSibling
      if (header) header.setAttribute('aria-expanded', 'true')
    }
  }

  setupSwipeGesture() {
    const sidebar = document.getElementById('mainSidebar')
    if (!sidebar) return

    let touchStartX = 0
    let touchStartY = 0
    const SWIPE_THRESHOLD = 60   // px minimum pour déclencher la fermeture
    const SWIPE_MAX_Y = 80        // px max de déplacement vertical toléré

    sidebar.addEventListener('touchstart', (e) => {
      touchStartX = e.touches[0].clientX
      touchStartY = e.touches[0].clientY
    }, { passive: true })

    sidebar.addEventListener('touchend', (e) => {
      if (!sidebar.classList.contains('active')) return

      const deltaX = touchStartX - e.changedTouches[0].clientX
      const deltaY = Math.abs(touchStartY - e.changedTouches[0].clientY)

      // Swipe vers la gauche (fermer) avec déplacement majoritairement horizontal
      if (deltaX > SWIPE_THRESHOLD && deltaY < SWIPE_MAX_Y) {
        this.closeSidebar()
      }
    }, { passive: true })
  }
}
