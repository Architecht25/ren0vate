# V2 — Lot 3 : simulation publique de primes (SubsidyCase), distincte de
# resources :simulations (Simulation V1) définies dans config/routes/simulations.rb
#
# DÉSACTIVÉ avant déploiement prod du 12/10/2026, à la demande de Robin :
# les montants seedés dans SubsidyRule (migration
# 20261012140100_seed_initial_subsidy_rules.rb, Wallonie/Flandre) sont des
# PLACEHOLDERS non vérifiés avec le barème officiel (voir
# docs/QUESTIONS_OUVERTES.md Q14 — "ne jamais citer ces montants à un
# client avant confirmation"). Le mécanisme (règles versionnées, moteur,
# tests) reste en place et fonctionnel ; seule l'exposition publique est
# coupée. Réactiver en décommentant la ligne ci-dessous une fois les
# montants confirmés avec le barème officiel.
# resources :subsidy_simulations, only: %i[new create show]
