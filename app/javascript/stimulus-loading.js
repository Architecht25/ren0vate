// Load all controllers within this directory
// Controller files must be named *_controller.js

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = true
window.Stimulus = application

// Import all controllers manually and register them
import CategorieEstimationController from "controllers/categorie_estimation_controller"
import LocalstorageMonitorController from "controllers/localstorage_monitor_controller"
import PrimeCalculController from "controllers/prime_calcul_controller"
import PrimeCardController from "controllers/prime_card_controller"
import TestEligibiliteController from "controllers/test_eligibilite_controller"
import UserTypeController from "controllers/user_type_controller"

// Register all controllers
application.register("categorie-estimation", CategorieEstimationController)
application.register("localstorage-monitor", LocalstorageMonitorController)
application.register("prime-calcul", PrimeCalculController)
application.register("prime-card", PrimeCardController)
application.register("test-eligibilite", TestEligibiliteController)
application.register("user_type", UserTypeController)

console.log('✅ Tous les contrôleurs Stimulus ont été chargés et enregistrés')

export { application }
