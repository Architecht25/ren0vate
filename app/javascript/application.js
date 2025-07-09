import "@hotwired/turbo-rails"
import "bootstrap"

import { Application } from "@hotwired/stimulus"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// initialise Stimulus
window.Stimulus = Application.start()
console.log('🔥 Stimulus application démarrée')

// Auto-chargement des contrôleurs
eagerLoadControllersFrom("controllers", window.Stimulus)
console.log('✅ Auto-chargement des contrôleurs effectué')
