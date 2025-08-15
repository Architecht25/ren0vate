module I18nHelper
  # Sélecteur de langue avec drapeaux
  def language_selector
    content_tag :div, class: "language-selector dropdown" do
      button_content = content_tag(:span, current_locale_flag, class: "me-2") +
                      content_tag(:span, current_locale_name) +
                      content_tag(:i, "", class: "bi bi-chevron-down ms-2")

      button_tag(button_content,
                 class: "btn btn-outline-secondary btn-sm dropdown-toggle",
                 data: { bs_toggle: "dropdown" },
                 type: "button") +
      content_tag(:ul, class: "dropdown-menu") do
        language_options.map do |locale, data|
          content_tag(:li) do
            link_to(url_for(locale: locale),
                   class: "dropdown-item #{'active' if I18n.locale.to_s == locale}") do
              content_tag(:span, data[:flag], class: "me-2") +
              content_tag(:span, data[:name])
            end
          end
        end.join.html_safe
      end
    end
  end

  # Options de langues disponibles
  def language_options
    {
      'fr' => { name: 'Français', flag: '🇫🇷' },
      'nl' => { name: 'Nederlands', flag: '🇧🇪' },  # Drapeau belge pour le flamand
      'en' => { name: 'English', flag: '🇬🇧' }
    }
  end

  # Nom de la langue actuelle
  def current_locale_name
    language_options[I18n.locale.to_s][:name]
  end

  # Drapeau de la langue actuelle
  def current_locale_flag
    language_options[I18n.locale.to_s][:flag]
  end

  # Traduction intelligente selon la région
  def region_aware_t(key, region: nil, **options)
    region ||= current_user&.properties&.last&.region

    # Essayer d'abord avec la région spécifique
    if region.present?
      region_key = "#{key}.#{region.downcase}"
      if I18n.exists?(region_key, I18n.locale)
        return t(region_key, **options)
      end
    end

    # Fallback sur la traduction générale
    t(key, **options)
  end

  # Formatage des montants selon la locale
  def format_currency(amount, options = {})
    case I18n.locale
    when :fr
      number_to_currency(amount, unit: "€", format: "%n %u", **options)
    when :nl
      number_to_currency(amount, unit: "€", format: "€ %n", **options)
    when :en
      number_to_currency(amount, unit: "€", format: "€%n", **options)
    else
      number_to_currency(amount, **options)
    end
  end

  # Date selon la locale
  def localize_date(date, format: :default)
    case I18n.locale
    when :fr
      l(date, format: format, locale: :fr)
    when :nl
      l(date, format: format, locale: :nl)
    when :en
      l(date, format: format, locale: :en)
    else
      l(date, format: format)
    end
  end

  # URL avec locale
  def url_with_locale(url, locale = I18n.locale)
    if url.starts_with?('/')
      "/#{locale}#{url}"
    else
      url
    end
  end
end
