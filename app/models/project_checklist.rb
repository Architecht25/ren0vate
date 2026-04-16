class ProjectChecklist < ApplicationRecord
  belongs_to :project
  belongs_to :checklist_template
  has_many   :project_checklist_items, dependent: :destroy

  # Construit les items à partir du template lors de la création
  after_create :build_items_from_template

  def completed?
    completed_at.present?
  end

  def progress_pct
    total = project_checklist_items.count
    return 0 if total.zero?
    (project_checklist_items.where(checked: true).count * 100.0 / total).round
  end

  def all_required_checked?
    required_item_ids = checklist_template.checklist_items.where(required: true).pluck(:id)
    return true if required_item_ids.empty?
    project_checklist_items.where(checklist_item_id: required_item_ids, checked: true).count == required_item_ids.size
  end

  def check_completion!
    if all_required_checked? && project_checklist_items.where(checked: false).none?
      update_column(:completed_at, Time.current) unless completed?
    end
  end

  private

  def build_items_from_template
    checklist_template.checklist_items.ordered.each do |item|
      project_checklist_items.create!(checklist_item: item)
    end
  end
end
