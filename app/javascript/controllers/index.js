// Import and register controllers with the global Stimulus application
import { application } from "../application"

console.log('📁 Loading controllers into existing Stimulus application...')

import UserTypeController from "./user_type_controller"
import TestEligibiliteController from "./test_eligibilite_controller"
import CategorieEstimationController from "./categorie_estimation_controller"
import PrimeCardController from "./prime_card_controller"
import PrimeCalculController from "./prime_calcul_controller"

console.log('📦 Controllers imported, registering...')

application.register("user_type", UserTypeController)
application.register("test-eligibilite", TestEligibiliteController)
application.register("categorie-estimation", CategorieEstimationController)
application.register("prime-card", PrimeCardController)
application.register("prime-calcul", PrimeCalculController)

console.log('✅ All controllers registered successfully!')
console.log('📊 Registered controllers:', application.router.modules)
