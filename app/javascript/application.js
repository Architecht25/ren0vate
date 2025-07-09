import "@hotwired/turbo-rails"
import "bootstrap"

import { Application } from "@hotwired/stimulus"

// initialise Stimulus
window.Stimulus = Application.start()
console.log('🔥 Stimulus application démarrée')

// Import manuel des contrôleurs
import UserTypeController from "controllers/user_type_controller"
import TestEligibiliteController from "controllers/test_eligibilite_controller"
import CategorieEstimationController from "controllers/categorie_estimation_controller"
import PrimeCardController from "controllers/prime_card_controller"
import PrimeCalculController from "controllers/prime_calcul_controller"

// Enregistrement des contrôleurs
window.Stimulus.register("user_type", UserTypeController)
window.Stimulus.register("test-eligibilite", TestEligibiliteController)
window.Stimulus.register("categorie-estimation", CategorieEstimationController)
window.Stimulus.register("prime-card", PrimeCardController)
window.Stimulus.register("prime-calcul", PrimeCalculController)
console.log('✅ Tous les contrôleurs enregistrés')
