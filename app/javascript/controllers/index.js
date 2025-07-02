import { application } from "../stimulus_application"
import RegionSelectorController from "./region_selector_controller"
import RegionDisplayController from "./region_display_controller"
import UserTypeController from "./user_type_controller"
import TestEligibiliteController from "./test_eligibilite_controller"
import CategorieEstimationController from "./categorie_estimation_controller"

application.register("region-selector", RegionSelectorController)
application.register("region-display", RegionDisplayController)
application.register("user-type", UserTypeController)
application.register("test-eligibilite", TestEligibiliteController)
application.register("categorie-estimation", CategorieEstimationController)
