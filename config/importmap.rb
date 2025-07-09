# Pin npm packages by running ./bin/importmap

pin "application"

# Hotwired libs avec des CDN plus fiables
pin "@hotwired/turbo-rails", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo-rails@8.0.5/app/assets/javascripts/turbo.min.js"
pin "@hotwired/turbo", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.5/dist/turbo.es2017-esm.js"
pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.js"
pin "@hotwired/stimulus-loading", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus-loading@1.0.0/dist/stimulus-loading.js"

pin_all_from "app/javascript/controllers", under: "controllers"

# Bootstrap via CDN
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"

# Logic files
pin "logic/categorie_choix_logic", to: "logic/categorie_choix_logic.js"
pin "logic/categorie_utilitaire_logic", to: "logic/categorie_utilitaire_logic.js"
pin "logic/prime_total_logic", to: "logic/prime_total_logic.js"

# External libraries via CDN
pin "sweetalert2", to: "https://cdn.jsdelivr.net/npm/sweetalert2@11/dist/sweetalert2.all.min.js"
pin "html2pdf", to: "https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"
