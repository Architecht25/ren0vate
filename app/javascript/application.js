import "@hotwired/turbo-rails"
import "bootstrap"

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = true
window.Stimulus = application

// Import et register tous les contrôleurs manuellement et simplement
import LocalstorageMonitorController from "controllers/localstorage_monitor_controller"
import UserTypeController from "controllers/user_type_controller"
import TestEligibiliteController from "controllers/test_eligibilite_controller"
import CategorieEstimationController from "controllers/categorie_estimation_controller"
import CategorieCalculController from "controllers/categorie_calcul_controller"
import PrimeCardController from "controllers/prime_card_controller"
import PrimeCalculController from "controllers/prime_calcul_controller"
import RegionDisplayController from "controllers/region_display_controller"
import RegionSelectorController from "controllers/region_selector_controller"

application.register("localstorage-monitor", LocalstorageMonitorController)
application.register("user-type", UserTypeController)
application.register("test-eligibilite", TestEligibiliteController)
application.register("categorie-estimation", CategorieEstimationController)
application.register("categorie-calcul", CategorieCalculController)
application.register("prime-card", PrimeCardController)
application.register("prime-calcul", PrimeCalculController)
application.register("region-display", RegionDisplayController)
application.register("region-selector", RegionSelectorController)

export { application }
