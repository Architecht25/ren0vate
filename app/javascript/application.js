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
import "./logic/tooltips"
import "./password_toggle"

// Import et register tous les contrôleurs manuellement et simplement
import UserTypeController from "controllers/user/user_type_controller"
import TestEligibiliteController from "controllers/subsidies/test_eligibilite_controller"
import TestEligibiliteBruxellesController from "controllers/bruxelles/test_eligibilite_bruxelles_controller"
import TestEligibiliteFlandreController from "controllers/flandre/test_eligibilite_flandre_controller"
import TestEligibiliteWallonieController from "controllers/wallonie/test_eligibilite_wallonie_controller"
import CategorieEstimationController from "controllers/subsidies/categorie_estimation_controller"
import PrimeCardController from "controllers/subsidies/prime_card_controller"
import PrimeCalculController from "controllers/subsidies/prime_calcul_controller"
import PebController from "controllers/flandre/peb_controller"
import PetitPatrimoineBruxellesController from "controllers/bruxelles/petit_patrimoine_bruxelles_controller"
import PdfPreviewController from "controllers/documents/pdf_preview_controller"
import WalloniePrimeCalculController from "controllers/wallonie/wallonie_prime_calcul_controller"
import WalloniePrimeCardController from "controllers/wallonie/wallonie_prime_card_controller"
import WallonieSimulationController from "controllers/wallonie/wallonie_simulation_controller"
import WallonieSimulationCardController from "controllers/wallonie/wallonie_simulation_card_controller"
import WalloniePretReductionController from "controllers/wallonie/wallonie_pret_reduction_controller"
import FlandrePrimeCardController from "controllers/flandre/flandre_prime_card_controller"
import FlandrePrimeCalculController from "controllers/flandre/flandre_prime_calcul_controller"
import FlandreSimulationController from "controllers/flandre/flandre_simulation_controller"
import FlandreSimulationCardController from "controllers/flandre/flandre_simulation_card_controller"
import FlandreWizardController from "controllers/flandre/flandre_wizard_controller"
import WallonieWizardController from "controllers/wallonie/wallonie_wizard_controller"
import LogoutModalController from "controllers/user/logout_modal_controller"
import LanguageController from "controllers/site/language_controller"
import RenopackWallonieController from "controllers/wallonie/renopack_wallonie_controller"
import RequestFormController from "controllers/documents/request_form_controller"
import RequestAutosaveController from "controllers/documents/request_autosave_controller"
import ImagePreviewController from "controllers/documents/image_preview_controller"
import DocumentPreviewController from "controllers/documents/document_preview_controller"
import PricingController from "controllers/site/pricing_controller"
import DecisionHubController from "controllers/subsidies/decision_hub_controller"
import DecisionHubInteractionsController from "controllers/subsidies/decision_hub_interactions_controller"
import EntrepreneurVerificationController from "controllers/project/entrepreneur_verification_controller"
import PrimeSelectionController from "controllers/subsidies/prime_selection_controller"
import PrimesCommunalesController from "controllers/flandre/primes_communales_controller"
import PrimesCommunalesBruxellesController from "controllers/bruxelles/primes_communales_bruxelles_controller"
import PrimesCommunalesWallonieController from "controllers/wallonie/primes_communales_wallonie_controller"
import MapboxController from "controllers/property/mapbox_controller"
import AmianteController from "controllers/flandre/amiante_controller"
import EntrepreneursManagementController from "controllers/project/entrepreneurs_management_controller"
import RoiCalculatorController from "controllers/subsidies/roi_calculator_controller"
import LoanSimulatorController from "controllers/subsidies/loan_simulator_controller"
import PwaInstallController from "controllers/site/pwa_install_controller"
import SidebarController from "controllers/site/sidebar_controller"
import HealthScoreController from "controllers/project/health_score_controller"
import ArchitecturalParallaxController from "controllers/site/architectural_parallax_controller"
import CookieConsentController from "controllers/site/cookie_consent_controller"
import NpsController from "controllers/user/nps_controller"
import DashboardTabsController from "controllers/dashboard/dashboard_tabs_controller"
import SimulationLaunchController from "controllers/subsidies/simulation_launch_controller"

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
application.register("wallonie-pret-reduction", WalloniePretReductionController)
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
application.register("cookie-consent", CookieConsentController)
application.register("nps", NpsController)
application.register("dashboard-tabs", DashboardTabsController)
application.register("simulation-launch", SimulationLaunchController)

export { application }
