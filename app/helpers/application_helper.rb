module ApplicationHelper
  include FormulairePreremplissageHelper

  # Détermine si l'utilisateur actuel est un administrateur
  def current_user_admin?
    return false unless user_signed_in?
    # Pour l'instant, basé sur l'email admin - à améliorer avec un vrai système de rôles
    current_user.email == 'robin@primes-services.be'
  end

  # Helper pour les statuts RequestProgress
  def request_progress_status_badge(status)
    status_config = {
      'en_preparation' => { class: 'secondary', icon: 'clock', text: 'En préparation' },
      'soumis' => { class: 'primary', icon: 'upload', text: 'Soumis' },
      'en_cours' => { class: 'info', icon: 'arrow-repeat', text: 'En cours' },
      'complet' => { class: 'success', icon: 'check-circle', text: 'Complet' },
      'incomplet' => { class: 'warning', icon: 'exclamation-triangle', text: 'Incomplet' },
      'accorde' => { class: 'success', icon: 'check-circle-fill', text: 'Accordé' },
      'refuse' => { class: 'danger', icon: 'x-circle', text: 'Refusé' },
      'annule' => { class: 'dark', icon: 'slash-circle', text: 'Annulé' }
    }

    config = status_config[status] || status_config['en_preparation']

    content_tag :span, class: "badge bg-#{config[:class]}" do
      concat content_tag(:i, '', class: "bi bi-#{config[:icon]} me-1")
      concat config[:text]
    end
  end

  # Helper pour formater les montants
  def format_currency_amount(amount)
    return content_tag(:small, '-', class: 'text-muted') if amount.blank? || amount.zero?

    number_to_currency(amount, unit: '€', separator: ',', delimiter: ' ')
  end

  # Helper pour le taux d'octroi avec couleur
  def format_taux_octroi(taux)
    return '' if taux.zero?

    color_class = case taux
                 when 0..25 then 'text-danger'
                 when 26..50 then 'text-warning'
                 when 51..75 then 'text-info'
                 else 'text-success'
                 end

    content_tag :small, "(#{taux}%)", class: "#{color_class} fw-semibold"
  end

  # Helper pour obtenir les options de types de formulaires selon la région
  def options_for_select_form_types(region = nil)
    # Normaliser la région pour être case-insensitive
    normalized_region = region&.downcase

    case normalized_region
    when 'wallonie'
      [
        ['audit', 'Prime Audit Énergétique'],
        ['regionale', 'Prime Régionale'],
        ['communale', 'Primes Communales'],
        ['monument', 'Prime Monument & Site']
      ]
    when 'flandre'
      [
        ['regional', 'Formulaire régional'],
        ['communal', 'Formulaires communaux'],
        ['monuments', 'Monuments & Sites']
      ]
    when 'bruxelles'
      [
        ['regional', 'Formulaire régional'],
        ['monuments', 'Monuments & Sites'],
        ['petit_patrimoine', 'Petit patrimoine'],
        ['communal', 'Primes communales']
      ]
    else
      [
        ['regional', 'Formulaire régional'],
        ['communal', 'Formulaires communaux'],
        ['monuments', 'Monuments & Sites']
      ]
    end
  end
end
