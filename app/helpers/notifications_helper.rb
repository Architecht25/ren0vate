module NotificationsHelper
  # Badge pour les notifications non lues
  def unread_notifications_badge(user)
    count = user.unread_notifications_count
    return '' if count.zero?

    content_tag :span, count,
                class: "badge bg-danger rounded-pill position-absolute translate-middle",
                style: "top: 8px; left: 24px; font-size: 0.65rem;"
  end

  # Icône selon le type de notification
  def notification_icon(notification)
    content_tag :i, '', class: "#{notification.type_icon} me-3 fs-5 text-#{notification.priority_color}"
  end

  # Badge de priorité
  def notification_priority_badge(notification)
    return '' if notification.priority == 'normale'

    case notification.priority
    when 'critique'
      content_tag :span, '🔴 URGENT', class: 'badge bg-danger ms-2'
    when 'haute'
      content_tag :span, '🟡 Important', class: 'badge bg-warning ms-2'
    else
      ''
    end
  end

  # Formatage du temps relatif
  def notification_time_ago(notification)
    if notification.created_at > 1.day.ago
      time_ago_in_words(notification.created_at)
    else
      l(notification.created_at, format: :short)
    end
  end

  # Couleur de fond selon le statut lu/non lu
  def notification_card_class(notification)
    base_class = "list-group-item list-group-item-action border-start-0 border-end-0 py-3 px-4"

    if notification.read?
      "#{base_class} text-muted"
    else
      "#{base_class} bg-light border-start border-4 border-primary"
    end
  end

  # Message d'action selon le type
  def notification_action_text(notification)
    case notification.type
    when 'dossier_incomplet', 'document_requis'
      'Compléter le dossier'
    when 'facture_manquante'
      'Télécharger la facture'
    when 'deadline_proche'
      'Voir les détails'
    when 'conseil_optimisation'
      'Optimiser ma simulation'
    when 'etape_suivante'
      'Suivre le conseil'
    when 'simulation_expiration'
      'Prolonger la simulation'
    when 'prime_eligible'
      'Découvrir la prime'
    when 'verification_requise'
      'Vérifier maintenant'
    when 'suivi_projet'
      'Voir le projet'
    else
      'Voir les détails'
    end
  end

  # Couleur du bouton d'action
  def notification_action_button_class(notification)
    case notification.priority
    when 'critique'
      'btn btn-danger btn-sm'
    when 'haute'
      'btn btn-warning btn-sm'
    when 'normale'
      'btn btn-primary btn-sm'
    else
      'btn btn-outline-secondary btn-sm'
    end
  end

  # Dropdown pour filtres rapides
  def notification_filter_options
    [
      ['Toutes', notifications_path],
      ['Non lues', notifications_path(status: 'unread')],
      ['Lues', notifications_path(status: 'read')],
      ['---', nil],
      ['Documents', notifications_path(category: 'documents')],
      ['Primes', notifications_path(category: 'primes')],
      ['Projets', notifications_path(category: 'projets')],
      ['Système', notifications_path(category: 'systeme')]
    ]
  end

  # Résumé des stats pour dashboard
  def notifications_summary_widget(user)
    unread = user.unread_notifications_count
    total_active = user.notifications.active.count

    content_tag :div, class: 'card border-info' do
      content_tag(:div, class: 'card-body text-center') do
        content_tag(:h4, unread, class: 'text-info mb-1') +
        content_tag(:small, "notification(s) non lue(s)", class: 'text-muted d-block') +
        content_tag(:small, "#{total_active} total actives", class: 'text-muted d-block mt-1') +
        link_to('Voir toutes', notifications_path, class: 'btn btn-outline-info btn-sm mt-2')
      end
    end
  end

  # Widget pour la sidebar ou dashboard
  def recent_notifications_widget(user, limit = 3)
    notifications = user.notifications.unread.active.by_priority.limit(limit)

    return '' if notifications.empty?

    content_tag :div, class: 'card' do
      content_tag(:div, class: 'card-header') do
        content_tag(:h6, class: 'mb-0') do
          content_tag(:i, '', class: 'bi bi-bell me-2') + 'Notifications récentes'
        end
      end +
      content_tag(:div, class: 'card-body p-0') do
        content_tag(:div, class: 'list-group list-group-flush') do
          notifications.map do |notification|
            link_to notification_path(notification),
                    class: 'list-group-item list-group-item-action py-2 px-3 border-0' do
              content_tag(:div, class: 'd-flex align-items-center') do
                notification_icon(notification) +
                content_tag(:div, class: 'flex-grow-1 min-w-0') do
                  content_tag(:div, notification.title, class: 'fw-medium small mb-1') +
                  content_tag(:div, truncate(notification.message, length: 60), class: 'text-muted small')
                end
              end
            end
          end.join.html_safe
        end
      end +
      if notifications.count == limit
        content_tag(:div, class: 'card-footer text-center') do
          link_to 'Voir toutes les notifications', notifications_path, class: 'small text-decoration-none'
        end
      else
        ''
      end
    end
  end
end
