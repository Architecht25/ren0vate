require "test_helper"

class MessageThreadPolicyTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
    @toiture = @project.lots.create!(key: "toiture", name: "Toiture", position: 0)
    @menuiseries = @project.lots.create!(key: "menuiseries", name: "Menuiseries", position: 1)

    @roofer = User.create!(email: "roofer_msg@example.com", password: "password123", nom: "Couvreur")
    @project.project_members.create!(user: @roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @toiture)

    @thread = @project.message_threads.create!(title: "Question toiture", lot: @toiture)
  end

  test "un entrepreneur scopé à un lot voit le fil de ce lot, pas celui d'un autre" do
    assert MessageThreadPolicy.new(@roofer, @thread).show?

    other_roofer = User.create!(email: "other_roofer_msg@example.com", password: "password123", nom: "Menuisier")
    @project.project_members.create!(user: other_roofer, role: "entrepreneur", status: "active").project_member_lots.create!(lot: @menuiseries)
    assert_not MessageThreadPolicy.new(other_roofer, @thread).show?
  end

  test "poster un message suit les mêmes règles que voir le fil" do
    message = @thread.messages.build(body: "Test", author: @roofer)
    assert MessagePolicy.new(@roofer, message).create?

    outsider = User.create!(email: "outsider_msg@example.com", password: "password123", nom: "Outsider")
    assert_not MessagePolicy.new(outsider, message).create?
  end
end
