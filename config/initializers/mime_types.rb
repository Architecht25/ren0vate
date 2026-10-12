# V2 — Lot 6 : nécessaire pour project_vault_export_path (format: :zip) —
# "zip" n'est pas un type MIME reconnu par Rails par défaut, sans cet
# enregistrement la route répond 406 Not Acceptable.
Mime::Type.register "application/zip", :zip
