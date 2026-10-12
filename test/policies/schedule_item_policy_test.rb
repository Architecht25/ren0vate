require "test_helper"

class ScheduleItemPolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)

    @architect = User.create!(email: "architect_sched@example.com", password: "password123", nom: "Architecte")
    @project.project_members.create!(user: @architect, role: "architect", status: "active")

    @roofer = User.create!(email: "roofer_sched@example.com", password: "password123", nom: "Couvreur")
    @project.project_members.create!(user: @roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @toiture)

    @item = @project.schedule_items.create!(label: "Pose toiture", lot: @toiture)
  end

  test "le propriétaire et l'architecte peuvent gérer le planning, pas l'entrepreneur" do
    assert ScheduleItemPolicy.new(@owner, @item).create?
    assert ScheduleItemPolicy.new(@architect, @item).create?
    assert_not ScheduleItemPolicy.new(@roofer, @item).create?
  end

  test "un entrepreneur scopé voit les tâches de son lot" do
    assert ScheduleItemPolicy.new(@roofer, @item).show?
  end
end
