import "@hotwired/turbo-rails"
import "./turbo_csp_config"
// import "bootstrap" // Commenté car on utilise Bootstrap via CDN
import "sweetalert2"

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience (logs désactivés pour réduire le bruit)
application.debug = false
window.Stimulus = application

// Import des logiques spécifiques
import "./logic/flandre_calculations"
import "./logic/prime_inputs_handlers"

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
import BruxellesPrimeCardController from "controllers/bruxelles_prime_card_controller"
import BruxellesPrimeCalculController from "controllers/bruxelles_prime_calcul_controller"
import FlandrePrimeCardController from "controllers/flandre_prime_card_controller"
import FlandrePrimeCalculController from "controllers/flandre_prime_calcul_controller"
import BceSearchController from "controllers/bce_search_controller"
import LogoutModalController from "controllers/logout_modal_controller"
import BruxellesAidesEstimationController from "controllers/bruxelles_aides_estimation_controller"
import WorkflowController from "controllers/workflow_controller"
import EnhancedBceSearchController from "controllers/enhanced_bce_search_controller"
import EligibilityCheckerController from "controllers/eligibility_checker_controller"
import AidCalculatorController from "controllers/aid_calculator_controller"
import LanguageController from "controllers/language_controller"
import RenopackWallonieController from "controllers/renopack_wallonie_controller"

application.register("user_type", UserTypeController)
application.register("test-eligibilite", TestEligibiliteController)
application.register("categorie-estimation", CategorieEstimationController)
application.register("prime-card", PrimeCardController)
application.register("prime-calcul", PrimeCalculController)
application.register("peb", PebController)
application.register("petit-patrimoine-bruxelles", PetitPatrimoineBruxellesController)
application.register("wallonie-prime-calcul", WalloniePrimeCalculController)
application.register("wallonie-prime-card", WalloniePrimeCardController)
application.register("bruxelles-prime-card", BruxellesPrimeCardController)
application.register("bruxelles-prime-calcul", BruxellesPrimeCalculController)
application.register("flandre-prime-card", FlandrePrimeCardController)
application.register("flandre-prime-calcul", FlandrePrimeCalculController)
application.register("bce-search", BceSearchController)
application.register("logout-modal", LogoutModalController)
application.register("bruxelles-aides-estimation", BruxellesAidesEstimationController)
application.register("workflow", WorkflowController)
application.register("enhanced-bce-search", EnhancedBceSearchController)
application.register("eligibility-checker", EligibilityCheckerController)
application.register("aid-calculator", AidCalculatorController)
application.register("language", LanguageController)
application.register("renopack-wallonie", RenopackWallonieController)

export { application }
