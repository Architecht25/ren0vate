import { application } from "../application"

import UserTypeController from "./user_type_controller"
application.register("user_type", UserTypeController)

import TestEligibiliteController from "./test_eligibilite_controller"
application.register("test-eligibilite", TestEligibiliteController)

import CategorieEstimationController from "./categorie_estimation_controller"
application.register("categorie-estimation", CategorieEstimationController)

import PrimeCardController from "./prime_card_controller"
application.register("prime-card", PrimeCardController)

import PrimeCalculController from "./prime_calcul_controller"
application.register("prime-calcul", PrimeCalculController)
