require "test_helper"

class AuditEventTest < ActiveSupport::TestCase
  fixtures :users, :properties, :projects

  setup do
    @owner = users(:freemium_user)
    @project = projects(:one)
  end

  test "record! crée un événement rattaché au projet de l'auditable par défaut" do
    event = AuditEvent.record!(action: "document.validated", auditable: @project, actor: @owner)
    assert_equal @project, event.project
    assert_equal @owner, event.actor
    assert_equal "document.validated", event.action
  end

  test "un événement ne peut pas être modifié après création — append-only" do
    event = AuditEvent.record!(action: "project.updated", auditable: @project, actor: @owner)

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      event.update!(action: "project.deleted")
    end
  end

  test "un événement ne peut pas être supprimé directement" do
    event = AuditEvent.record!(action: "project.updated", auditable: @project, actor: @owner)

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      event.destroy!
    end
  end

  test "la suppression du projet audité anonymise la référence sans bloquer ni supprimer l'événement" do
    event = AuditEvent.record!(action: "project.updated", auditable: @project, actor: @owner)

    @project.destroy!

    assert_nil event.reload.project_id
  end
end
