import "@hotwired/turbo-rails"
import "bootstrap"

import { Application } from "@hotwired/stimulus"

// initialise Stimulus
window.Stimulus = Application.start()
console.log('🔥 Stimulus application démarrée')

// Import manuel des contrôleurs
import UserTypeController from "controllers/user_type_controller"
import TestEligibiliteController from "controllers/test_eligibilite_controller"

// Enregistrement des contrôleurs
window.Stimulus.register("user_type", UserTypeController)
window.Stimulus.register("test_eligibilite", TestEligibiliteController)
console.log('✅ Contrôleurs enregistrés')
