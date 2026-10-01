namespace :checklists do
  desc "Crée les ProjectChecklistItem manquants pour les ChecklistItem ajoutés à un template après coup"
  task backfill_items: :environment do
    total_created = 0

    ProjectChecklist.includes(:checklist_template, :project_checklist_items).find_each do |project_checklist|
      existing_item_ids = project_checklist.project_checklist_items.pluck(:checklist_item_id)
      missing_items = project_checklist.checklist_template.checklist_items.where.not(id: existing_item_ids)

      missing_items.each do |checklist_item|
        project_checklist.project_checklist_items.create!(checklist_item: checklist_item)
        total_created += 1
      end
    end

    puts "✓ #{total_created} ProjectChecklistItem créé(s)."
  end
end
