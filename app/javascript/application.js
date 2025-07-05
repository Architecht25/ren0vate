import "@hotwired/turbo-rails"
import "bootstrap"
import * as bootstrap from "bootstrap"

import { Application } from "@hotwired/stimulus"

// initialise Stimulus
window.Stimulus = Application.start()

// import manuel de chaque contrôleur via Importmap
import RegionSelectorController from "controllers/region_selector_controller"
import RegionDisplayController from "controllers/region_display_controller"
import UserTypeController from "controllers/user_type_controller"
import TestEligibiliteController from "controllers/test_eligibilite_controller"

import CategorieCalculController from "controllers/categorie_calcul_controller"
import CategorieEstimationController from "controllers/categorie_estimation_controller"

import PrimeCardController from "controllers/prime_card_controller";
import PrimeCalculController from "controllers/prime_calcul_controller"

import LocalstorageMonitorController from "controllers/localstorage_monitor_controller";
import TestController from "controllers/test_controller";

// et on les enregistre
window.Stimulus.register("region-selector", RegionSelectorController)
window.Stimulus.register("region-display", RegionDisplayController)
window.Stimulus.register("user-type", UserTypeController)
window.Stimulus.register("test-eligibilite", TestEligibiliteController)

window.Stimulus.register("categorie-calcul", CategorieCalculController)
window.Stimulus.register("categorie-estimation", CategorieEstimationController)

window.Stimulus.register("prime-card", PrimeCardController);
window.Stimulus.register("prime-calcul", PrimeCalculController)

window.Stimulus.register("localstorage-monitor", LocalstorageMonitorController);
window.Stimulus.register("test", TestController);
