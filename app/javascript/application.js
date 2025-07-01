import "@hotwired/turbo-rails"
import "bootstrap"
import "@popperjs/core"

import { Application } from "@hotwired/stimulus"

// Initialise Stimulus
window.Stimulus = Application.start()

// Charge automatiquement les contrôleurs Stimulus depuis /controllers
import RegionSelectorController from "./controllers/region_selector_controller"
import UserTypeController from "./controllers/user_type_controller"
import RegionDisplayController from "./controllers/region_display_controller"

window.Stimulus.register("region-selector", RegionSelectorController)
window.Stimulus.register("user-type", UserTypeController)
window.Stimulus.register("region-display", RegionDisplayController)

import TestEligibiliteController from "./controllers/test_eligibilite_controller"
window.Stimulus.register("test-eligibilite", TestEligibiliteController)
