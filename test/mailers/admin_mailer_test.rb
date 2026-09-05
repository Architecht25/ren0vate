require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  fixtures :users, :properties, :projects, :requests, :simulations, :documents

  test "document_uploaded rend le corps du mail sans exception avec un contexte project" do
    # Régression : le template appelait @project.title (inexistant, Project a
    # `nom`) — l'exception était avalée silencieusement par le rescue autour
    # de deliver_now dans les contrôleurs, ce qui bloquait la notification
    # admin sur tout dépôt de document lié à un chantier.
    user     = users(:freemium_user)
    project  = projects(:one)
    document = documents(:one)

    mail = AdminMailer.document_uploaded(user, [ document ], project: project, property: project.property)

    assert_emails 1 do
      mail.deliver_now
    end
    assert_match project.nom, mail.html_part.body.to_s
    assert_match project.nom, mail.text_part.body.to_s
  end

  test "document_uploaded rend le corps du mail sans exception avec un contexte request" do
    user     = users(:freemium_user)
    request  = requests(:one)
    document = documents(:one)

    mail = AdminMailer.document_uploaded(user, [ document ], request: request)

    assert_emails 1 do
      mail.deliver_now
    end
    assert_match request.title.to_s, mail.html_part.body.to_s
  end
end
