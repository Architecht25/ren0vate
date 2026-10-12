class ProjectMemberLot < ApplicationRecord
  belongs_to :project_member
  belongs_to :lot

  validate :lot_belongs_to_same_project

  private

  def lot_belongs_to_same_project
    return if project_member.blank? || lot.blank?
    errors.add(:lot, "n'appartient pas au même chantier que l'intervenant") if lot.project_id != project_member.project_id
  end
end
