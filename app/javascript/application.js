import "@hotwired/turbo-rails"
// import "bootstrap" // Commenté car on utilise Bootstrap via CDN
import "sweetalert2"

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = true
window.Stimulus = application

// Import et register tous les contrôleurs manuellement et simplement
import UserTypeController from "controllers/user_type_controller"
import TestEligibiliteController from "controllers/test_eligibilite_controller"
import CategorieEstimationController from "controllers/categorie_estimation_controller"
import PrimeCardController from "controllers/prime_card_controller"
import PrimeCalculController from "controllers/prime_calcul_controller"
import PebController from "controllers/peb_controller"
import PetitPatrimoineBruxellesController from "controllers/petit_patrimoine_bruxelles_controller"
import WalloniePrimeCalculController from "controllers/wallonie_prime_calcul_controller"
import WalloniePrimeCardController from "controllers/wallonie_prime_card_controller"

application.register("user_type", UserTypeController)
application.register("test-eligibilite", TestEligibiliteController)
application.register("categorie-estimation", CategorieEstimationController)
application.register("prime-card", PrimeCardController)
application.register("prime-calcul", PrimeCalculController)
application.register("peb", PebController)
application.register("petit-patrimoine-bruxelles", PetitPatrimoineBruxellesController)
application.register("wallonie-prime-calcul", WalloniePrimeCalculController)
application.register("wallonie-prime-card", WalloniePrimeCardController)

export { application }
