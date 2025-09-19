module DecisionHubHelper
  def get_prime_icon(category)
    case category&.downcase
    when 'isolation' then 'house'
    when 'chauffage' then 'fire'
    when 'ventilation' then 'wind'
    when 'menuiserie' then 'window'
    when 'audit' then 'clipboard-check'
    when 'eclairage' then 'lightbulb'
    else 'gear'
    end
  end

  def get_prime_color(category)
    case category&.downcase
    when 'isolation' then 'primary'
    when 'chauffage' then 'danger'
    when 'ventilation' then 'info'
    when 'menuiserie' then 'warning'
    when 'audit' then 'success'
    when 'eclairage' then 'warning'
    else 'secondary'
    end
  end
end
