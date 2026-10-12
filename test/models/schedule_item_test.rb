require "test_helper"

class ScheduleItemTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @project = projects(:one)
  end

  test "une tâche est bloquée tant que sa dépendance n'est pas terminée" do
    demolition = @project.schedule_items.create!(label: "Démolition")
    pose = @project.schedule_items.create!(label: "Pose", depends_on: demolition)

    assert pose.blocked?

    demolition.update!(status: "termine")
    assert_not pose.reload.blocked?
  end

  test "une tâche ne peut pas dépendre d'elle-même" do
    item = @project.schedule_items.create!(label: "Test")
    item.depends_on_id = item.id
    assert_not item.valid?
  end

  test "une dépendance d'un autre chantier est rejetée" do
    other_project = Project.create!(user: @project.user, property: properties(:one), nom: "Autre chantier")
    foreign_item = other_project.schedule_items.create!(label: "Tâche étrangère")

    item = @project.schedule_items.build(label: "Test", depends_on: foreign_item)
    assert_not item.valid?
  end
end
