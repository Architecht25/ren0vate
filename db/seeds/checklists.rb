# db/seeds/checklists.rb
# Templates d'inspection chantier — données de référence

puts "→ Seed checklists..."

TEMPLATES = [
  {
    name: "Gros œuvre",
    phase: "gros_oeuvre",
    description: "Contrôle des travaux structurels : fondations, murs porteurs, dalle, charpente.",
    position: 1,
    items: [
      { description: "Fondations coulées conformément aux plans (profondeur, largeur, armatures)", required: true,  position: 1 },
      { description: "Cotes de niveaux vérifiées (plancher fini, seuils, terrasse)", required: true,  position: 2 },
      { description: "Murs porteurs d'aplomb et à l'équerre", required: true,  position: 3 },
      { description: "Classe d'exposition du béton conforme (gel, humidité)", required: false, position: 4 },
      { description: "Dalles sans fissures ni nids de cailloux visibles", required: true,  position: 5 },
      { description: "Charpente fixée, contreventement posé", required: true,  position: 6 },
      { description: "Évacuations encastrées / pentes OK (min. 1 %)", required: true,  position: 7 },
      { description: "Passage fourreaux électricité / plomberie prévu", required: false, position: 8 },
      { description: "Protection provisoire toiture (bâche si travaux en cours)", required: false, position: 9 },
      { description: "Nettoyage chantier — gravats évacués", required: false, position: 10 }
    ]
  },
  {
    name: "Second œuvre",
    phase: "second_oeuvre",
    description: "Isolation, toiture, façades, menuiseries extérieures, plomberie, électricité brute.",
    position: 2,
    items: [
      { description: "Couverture posée, étanchéité vérifiée (descentes EP, noues, solins)", required: true,  position: 1 },
      { description: "Isolation toiture : épaisseur conforme, sans ponts thermiques", required: true,  position: 2 },
      { description: "Isolation façades / murs posée (épaisseur, fixations, joints)", required: true,  position: 3 },
      { description: "Châssis extérieurs posés (d'aplomb, joints de calfeutrement, seuils)", required: true,  position: 4 },
      { description: "Valeurs Uw châssis conformes au devis / cahier des charges", required: true,  position: 5 },
      { description: "Réseau plomberie : test pression effectué (no fuites)", required: true,  position: 6 },
      { description: "Réseau électrique : câblage conforme au schéma, sections correctes", required: true,  position: 7 },
      { description: "Ventilation : gaines posées, bouches aux emplacements prévus", required: false, position: 8 },
      { description: "Chaudière / pompe à chaleur installée et raccordée", required: false, position: 9 },
      { description: "Cloisons intérieures d'aplomb et à équerres", required: false, position: 10 },
      { description: "Enduits muraux et plafonds sans fissures larges (> 0,3 mm)", required: false, position: 11 }
    ]
  },
  {
    name: "Finitions",
    phase: "finitions",
    description: "Revêtements, peintures, menuiseries intérieures, sanitaires, éclairage, nettoyage.",
    position: 3,
    items: [
      { description: "Carrelages posés : joints réguliers, pas de sonnage creux", required: true,  position: 1 },
      { description: "Parquet / sol souple : pose sans boursouflures, plinthes jointes", required: false, position: 2 },
      { description: "Peintures : aplat uniforme, finition conforme au bon de commande", required: false, position: 3 },
      { description: "Portes intérieures : alignement, poignées, serrures fonctionnelles", required: true,  position: 4 },
      { description: "Cuisine équipée : niveaux, joints, appareils raccordés", required: false, position: 5 },
      { description: "Sanitaires posés : étanchéité receveur/bac douche, WC, lavabo", required: true,  position: 6 },
      { description: "Tableau électrique : disjoncteurs étiquetés, test différentiel", required: true,  position: 7 },
      { description: "Éclairages fonctionnels dans toutes les pièces", required: false, position: 8 },
      { description: "Interrupteurs et prises à bonne hauteur, couvercles posés", required: false, position: 9 },
      { description: "Terrasse / abords : évacuations d'eau libres, garde-corps stables", required: false, position: 10 },
      { description: "Nettoyage fin de chantier complet (vitres, sols, protections enlevées)", required: true,  position: 11 }
    ]
  },
  {
    name: "Réception provisoire",
    phase: "reception",
    description: "Contrôle final avant remise des clés — vérification de la conformité globale au cahier des charges.",
    position: 4,
    items: [
      { description: "Tous les travaux prévus au contrat sont exécutés", required: true,  position: 1 },
      { description: "Réserves du dernier état d'avancement levées", required: true,  position: 2 },
      { description: "Certificat PEB après travaux disponible", required: true,  position: 3 },
      { description: "Attestation de conformité électrique (RGIE) fournie", required: true,  position: 4 },
      { description: "Documents de garantie remis (décennale, RC pro)", required: false, position: 5 },
      { description: "Notices d'entretien des équipements fournis (chaudière, VMC, PV...)", required: false, position: 6 },
      { description: "Clés, badges, télécommandes remis en bonne quantité", required: true,  position: 7 },
      { description: "Plans « as-built » remis (si prévu au contrat)", required: false, position: 8 },
      { description: "Décompte final signé par les deux parties", required: true,  position: 9 },
      { description: "Chantier nettoyé, matériaux excédentaires enlevés", required: true,  position: 10 },
      { description: "Compteurs eau / gaz / électricité réindexés", required: false, position: 11 }
    ]
  }
].freeze

TEMPLATES.each do |tpl_data|
  tpl = ChecklistTemplate.find_or_create_by!(name: tpl_data[:name], phase: tpl_data[:phase]) do |t|
    t.description = tpl_data[:description]
    t.position    = tpl_data[:position]
  end

  tpl_data[:items].each do |item_data|
    ChecklistItem.find_or_create_by!(checklist_template: tpl, description: item_data[:description]) do |i|
      i.required = item_data[:required]
      i.position = item_data[:position]
    end
  end

  puts "   ✓ #{tpl.name} (#{tpl.checklist_items.count} items)"
end

puts "✓ Checklists seedées."
