import { Application } from "@hotwired/stimulus"

export const application = Application.start()

import RegionSelectorController from "./controllers/region_selector_controller"
import RegionDisplayController from "./controllers/region_display_controller"
import UserTypeController from "./controllers/user_type_controller"
import TestEligibiliteController from "./controllers/test_eligibilite_controller"
import CategorieEstimationController from "./controllers/categorie_estimation_controller"

application.register("region-selector", RegionSelectorController)
application.register("region-display", RegionDisplayController)
application.register("user-type", UserTypeController)
application.register("test-eligibilite", TestEligibiliteController)
application.register("categorie-estimation", CategorieEstimationController)
