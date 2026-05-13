// Initialise tous les tooltips Bootstrap après chaque navigation Turbo
// et lors du premier chargement de la page.

function initTooltips() {
  const tooltipEls = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  tooltipEls.forEach(el => {
    // Éviter une double-initialisation
    if (!el._bsTooltip) {
      new bootstrap.Tooltip(el, { trigger: 'hover focus' })
    }
  })
}

document.addEventListener('turbo:load', initTooltips)
document.addEventListener('turbo:render', initTooltips)
