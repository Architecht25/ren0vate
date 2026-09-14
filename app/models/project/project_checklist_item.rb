class ProjectChecklistItem < ApplicationRecord
  belongs_to :project_checklist
  belongs_to :checklist_item

  def check!(notes: nil)
    update!(checked: true, checked_at: Time.current, notes: notes.presence || self.notes)
    project_checklist.check_completion!
  end

  def uncheck!
    update!(checked: false, checked_at: nil)
    project_checklist.update_column(:completed_at, nil) if project_checklist.completed?
  end
end
