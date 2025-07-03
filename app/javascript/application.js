import "@hotwired/turbo-rails"
import "bootstrap"
import * as bootstrap from "bootstrap"

import { Application } from "@hotwired/stimulus"

// initialise Stimulus
window.Stimulus = Application.start()

// import manuel de chaque contrôleur via Importmap
import RegionSelectorController    from "controllers/region_selector_controller"
import RegionDisplayController     from "controllers/region_display_controller"
import UserTypeController          from "controllers/user_type_controller"
import TestEligibiliteController   from "controllers/test_eligibilite_controller"
import CategorieEstimationController from "controllers/categorie_estimation_controller"

// et on les enregistre
window.Stimulus.register("region-selector",      RegionSelectorController)
window.Stimulus.register("region-display",       RegionDisplayController)
window.Stimulus.register("user-type",            UserTypeController)
window.Stimulus.register("test-eligibilite",     TestEligibiliteController)
window.Stimulus.register("categorie-estimation", CategorieEstimationController)
