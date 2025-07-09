import "@hotwired/turbo-rails"
import "bootstrap"

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Import direct des contrôleurs
import UserTypeController from "controllers/user_type_controller"
import TestEligibiliteController from "controllers/test_eligibilite_controller"
import CategorieEstimationController from "controllers/categorie_estimation_controller"
import PrimeCardController from "controllers/prime_card_controller"
import PrimeCalculController from "controllers/prime_calcul_controller"

// Enregistrement des contrôleurs
application.register("user_type", UserTypeController)
application.register("test-eligibilite", TestEligibiliteController)
application.register("categorie-estimation", CategorieEstimationController)
application.register("prime-card", PrimeCardController)
application.register("prime-calcul", PrimeCalculController)

export { application }
