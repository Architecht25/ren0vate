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
import "./password_toggle"

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
import PdfPreviewController from "controllers/pdf_preview_controller"
import WalloniePrimeCalculController from "controllers/wallonie_prime_calcul_controller"
import WalloniePrimeCardController from "controllers/wallonie_prime_card_controller"
import WallonieSimulationController from "controllers/wallonie_simulation_controller"
import WallonieSimulationCardController from "controllers/wallonie_simulation_card_controller"
import FlandrePrimeCardController from "controllers/flandre_prime_card_controller"
import FlandrePrimeCalculController from "controllers/flandre_prime_calcul_controller"
import FlandreSimulationController from "controllers/flandre_simulation_controller"
import FlandreSimulationCardController from "controllers/flandre_simulation_card_controller"
import FlandreWizardController from "controllers/flandre_wizard_controller"
import WallonieWizardController from "controllers/wallonie_wizard_controller"
import LogoutModalController from "controllers/logout_modal_controller"
import LanguageController from "controllers/language_controller"
import RenopackWallonieController from "controllers/renopack_wallonie_controller"
import RequestFormController from "controllers/request_form_controller"
import RequestAutosaveController from "controllers/request_autosave_controller"
import ImagePreviewController from "controllers/image_preview_controller"
import DocumentPreviewController from "controllers/document_preview_controller"
import PricingController from "controllers/pricing_controller"
import DecisionHubController from "controllers/decision_hub_controller"
import DecisionHubInteractionsController from "controllers/decision_hub_interactions_controller"
import EntrepreneurVerificationController from "controllers/entrepreneur_verification_controller"
import PrimeSelectionController from "controllers/prime_selection_controller"
import PrimesCommunalesController from "controllers/primes_communales_controller"
import PrimesCommunalesBruxellesController from "controllers/primes_communales_bruxelles_controller"
import PrimesCommunalesWallonieController from "controllers/primes_communales_wallonie_controller"
import MapboxController from "controllers/mapbox_controller"
import AmianteController from "controllers/amiante_controller"
import EntrepreneursManagementController from "controllers/entrepreneurs_management_controller"
import RoiCalculatorController from "controllers/roi_calculator_controller"
import LoanSimulatorController from "controllers/loan_simulator_controller"
import PwaInstallController from "controllers/pwa_install_controller"
import SidebarController from "controllers/sidebar_controller"
import HealthScoreController from "controllers/health_score_controller"
import ArchitecturalParallaxController from "controllers/architectural_parallax_controller"
import ConversationFixController from "controllers/conversation_fix_controller"
import CookieConsentController from "controllers/cookie_consent_controller"

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
application.register("pdf-preview", PdfPreviewController)
application.register("wallonie-prime-calcul", WalloniePrimeCalculController)
application.register("wallonie-prime-card", WalloniePrimeCardController)
application.register("wallonie-simulation", WallonieSimulationController)
application.register("wallonie-simulation-card", WallonieSimulationCardController)
application.register("flandre-prime-card", FlandrePrimeCardController)
application.register("flandre-prime-calcul", FlandrePrimeCalculController)
application.register("flandre-simulation", FlandreSimulationController)
application.register("flandre-simulation-card", FlandreSimulationCardController)
application.register("flandre-wizard", FlandreWizardController)
application.register("wallonie-wizard", WallonieWizardController)
application.register("logout-modal", LogoutModalController)
application.register("language", LanguageController)
application.register("renopack-wallonie", RenopackWallonieController)
application.register("request-form", RequestFormController)
application.register("request-autosave", RequestAutosaveController)
application.register("image-preview", ImagePreviewController)
application.register("document-preview", DocumentPreviewController)
application.register("pricing", PricingController)
application.register("decision-hub", DecisionHubController)
application.register("decision-hub-interactions", DecisionHubInteractionsController)
application.register("entrepreneur-verification", EntrepreneurVerificationController)
application.register("prime-selection", PrimeSelectionController)
application.register("primes-communales", PrimesCommunalesController)
application.register("primes-communales-bruxelles", PrimesCommunalesBruxellesController)
application.register("primes-communales-wallonie", PrimesCommunalesWallonieController)
application.register("mapbox", MapboxController)

application.register("amiante", AmianteController)
application.register("entrepreneurs-management", EntrepreneursManagementController)
application.register("roi-calculator", RoiCalculatorController)
application.register("loan-simulator", LoanSimulatorController)
application.register("pwa-install", PwaInstallController)
application.register("sidebar", SidebarController)
application.register("health-score", HealthScoreController)
application.register("architectural-parallax", ArchitecturalParallaxController)
application.register("conversation-fix", ConversationFixController)
application.register("cookie-consent", CookieConsentController)

export { application }
