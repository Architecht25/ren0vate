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
import TestEligibiliteBruxellesController from "controllers/test_eligibilite_bruxelles_controller"
import TestEligibiliteFlandreController from "controllers/test_eligibilite_flandre_controller"
import TestEligibiliteWallonieController from "controllers/test_eligibilite_wallonie_controller"
import CategorieEstimationController from "controllers/categorie_estimation_controller"
import PrimeCardController from "controllers/prime_card_controller"
import PrimeCalculController from "controllers/prime_calcul_controller"
import PebController from "controllers/peb_controller"
import PetitPatrimoineBruxellesController from "controllers/petit_patrimoine_bruxelles_controller"
import WalloniePrimeCalculController from "controllers/wallonie_prime_calcul_controller"
import WalloniePrimeCardController from "controllers/wallonie_prime_card_controller"
import WallonieSimulationController from "controllers/wallonie_simulation_controller"
import WallonieSimulationCardController from "controllers/wallonie_simulation_card_controller"
import BruxellesPrimeCardController from "controllers/bruxelles_prime_card_controller"
import BruxellesPrimeCalculController from "controllers/bruxelles_prime_calcul_controller"
import BruxellesSimulationController from "controllers/bruxelles_simulation_controller"
import BruxellesSimulationCardController from "controllers/bruxelles_simulation_card_controller"
import FlandrePrimeCardController from "controllers/flandre_prime_card_controller"
import FlandrePrimeCalculController from "controllers/flandre_prime_calcul_controller"
import FlandreSimulationController from "controllers/flandre_simulation_controller"
import FlandreSimulationCardController from "controllers/flandre_simulation_card_controller"
import BceSearchController from "controllers/bce_search_controller"
import LogoutModalController from "controllers/logout_modal_controller"
import BruxellesAidesEstimationController from "controllers/bruxelles_aides_estimation_controller"
import WorkflowController from "controllers/workflow_controller"
import EnhancedBceSearchController from "controllers/enhanced_bce_search_controller"
import EligibilityCheckerController from "controllers/eligibility_checker_controller"
import AidCalculatorController from "controllers/aid_calculator_controller"
import LanguageController from "controllers/language_controller"
import RenopackWallonieController from "controllers/renopack_wallonie_controller"
import RequestFormController from "controllers/request_form_controller"
import RequestAutosaveController from "controllers/request_autosave_controller"
import BruxellesEntrepriseCalculController from "controllers/bruxelles_entreprise_calcul_controller"
import BruxellesEntrepriseCardController from "controllers/bruxelles_entreprise_card_controller"
import BruxellesEntrepriseCartesController from "controllers/bruxelles_entreprise_cartes_controller"
import ImagePreviewController from "controllers/image_preview_controller"
import DocumentPreviewController from "controllers/document_preview_controller"
import AddressCopyController from "controllers/address_copy_controller"
import TooltipController from "controllers/tooltip_controller"
import PricingController from "controllers/pricing_controller"
import DecisionHubController from "controllers/decision_hub_controller"
import ConsultationVerificationController from "controllers/consultation_verification_controller"
import PrimeSelectionController from "controllers/prime_selection_controller"
import PrimesCommunalesController from "controllers/primes_communales_controller"
import PrimesCommunalesBruxellesController from "controllers/primes_communales_bruxelles_controller"
import PrimesCommunalesWallonieController from "controllers/primes_communales_wallonie_controller"

application.register("user_type", UserTypeController)
application.register("test-eligibilite", TestEligibiliteController)
application.register("test-eligibilite-bruxelles", TestEligibiliteBruxellesController)
application.register("test-eligibilite-flandre", TestEligibiliteFlandreController)
application.register("test-eligibilite-wallonie", TestEligibiliteWallonieController)
application.register("categorie-estimation", CategorieEstimationController)
application.register("prime-card", PrimeCardController)
application.register("prime-calcul", PrimeCalculController)
application.register("peb", PebController)
application.register("petit-patrimoine-bruxelles", PetitPatrimoineBruxellesController)
application.register("wallonie-prime-calcul", WalloniePrimeCalculController)
application.register("wallonie-prime-card", WalloniePrimeCardController)
application.register("wallonie-simulation", WallonieSimulationController)
application.register("wallonie-simulation-card", WallonieSimulationCardController)
application.register("bruxelles-prime-card", BruxellesPrimeCardController)
application.register("bruxelles-prime-calcul", BruxellesPrimeCalculController)
application.register("bruxelles-simulation", BruxellesSimulationController)
application.register("bruxelles-simulation-card", BruxellesSimulationCardController)
application.register("flandre-prime-card", FlandrePrimeCardController)
application.register("flandre-prime-calcul", FlandrePrimeCalculController)
application.register("flandre-simulation", FlandreSimulationController)
application.register("flandre-simulation-card", FlandreSimulationCardController)
application.register("bce-search", BceSearchController)
application.register("logout-modal", LogoutModalController)
application.register("bruxelles-aides-estimation", BruxellesAidesEstimationController)
application.register("workflow", WorkflowController)
application.register("enhanced-bce-search", EnhancedBceSearchController)
application.register("eligibility-checker", EligibilityCheckerController)
application.register("aid-calculator", AidCalculatorController)
application.register("language", LanguageController)
application.register("renopack-wallonie", RenopackWallonieController)
application.register("request-form", RequestFormController)
application.register("request-autosave", RequestAutosaveController)
application.register("bruxelles-entreprise-calcul", BruxellesEntrepriseCalculController)
application.register("bruxelles-entreprise-card", BruxellesEntrepriseCardController)
application.register("bruxelles-entreprise-cartes", BruxellesEntrepriseCartesController)
application.register("image-preview", ImagePreviewController)
application.register("document-preview", DocumentPreviewController)
application.register("address-copy", AddressCopyController)
application.register("tooltip", TooltipController)
application.register("pricing", PricingController)
application.register("decision-hub", DecisionHubController)
application.register("consultation-verification", ConsultationVerificationController)
application.register("prime-selection", PrimeSelectionController)
application.register("primes-communales", PrimesCommunalesController)
application.register("primes-communales-bruxelles", PrimesCommunalesBruxellesController)
application.register("primes-communales-wallonie", PrimesCommunalesWallonieController)

export { application }
