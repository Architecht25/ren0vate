import "@hotwired/turbo-rails"
import "@popperjs/core"
import "bootstrap"

import { Application } from "@hotwired/stimulus"

// Initialise Stimulus
window.Stimulus = Application.start()

// Contrôleurs Stimulus enregistrés manuellement
import RegionSelectorController from "./controllers/region_selector_controller"
import RegionDisplayController from "./controllers/region_display_controller"
import UserTypeController from "./controllers/user_type_controller"
import TestEligibiliteController from "./controllers/test_eligibilite_controller"
import CategorieEstimationController from "./controllers/categorie_estimation_controller"

// Enregistrement des contrôleurs
window.Stimulus.register("region-selector", RegionSelectorController)
window.Stimulus.register("region-display", RegionDisplayController)
window.Stimulus.register("user-type", UserTypeController)
window.Stimulus.register("test-eligibilite", TestEligibiliteController)
window.Stimulus.register("categorie-estimation", CategorieEstimationController)
