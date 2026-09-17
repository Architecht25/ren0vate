module ContractTemplatesHelper
  def category_badge_class(category)
    case category
    when 'Architecte'
      'bg-primary'
    when 'Entrepreneur'
      'bg-success'
    when 'Coordination'
      'bg-warning'
    when 'Études'
      'bg-info'
    else
      'bg-secondary'
    end
  end

  def category_icon(category)
    case category
    when 'Architecte'
      'bi-pencil-square'
    when 'Entrepreneur'
      'bi-tools'
    when 'Coordination'
      'bi-diagram-3'
    when 'Études'
      'bi-graph-up'
    else
      'bi-file-earmark-text'
    end
  end
end
