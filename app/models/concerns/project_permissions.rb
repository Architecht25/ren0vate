module ProjectPermissions
  extend ActiveSupport::Concern

  def can_invite_pros?
    role == 'owner'
  end

  def can_upload_quote?
    role == 'entrepreneur'
  end

  def can_validate_step?
    %w[owner architect].include?(role)
  end

  def full_financial_access?
    role == 'owner'
  end

  def can_post_message?
    %w[owner entrepreneur architect].include?(role)
  end

  def can_upload_photos?
    %w[owner entrepreneur architect].include?(role)
  end

  def can_edit_project?
    role == 'owner'
  end

  def role_label
    case role
    when 'owner'       then 'Propriétaire'
    when 'entrepreneur' then 'Entrepreneur'
    when 'architect'   then 'Architecte'
    else role.humanize
    end
  end
end
