# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "https://cdn.skypack.dev/@hotwired/turbo-rails"
pin "@hotwired/stimulus", to: "https://cdn.skypack.dev/@hotwired/stimulus"
pin_all_from "app/javascript/controllers", under: "controllers"

# Bootstrap via CDN
pin "bootstrap", to: "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"

# Logic files
pin "logic/categorie_choix_logic", to: "logic/categorie_choix_logic.js"
pin "logic/categorie_utilitaire_logic", to: "logic/categorie_utilitaire_logic.js"
pin "logic/prime_total_logic", to: "logic/prime_total_logic.js"

# External libraries via CDN
pin "sweetalert2", to: "https://cdn.skypack.dev/sweetalert2"
pin "html2pdf", to: "https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"
