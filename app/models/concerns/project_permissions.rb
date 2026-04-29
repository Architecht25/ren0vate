module ProjectPermissions
  extend ActiveSupport::Concern

  def can_invite_pros?
    role == 'owner'
  end

  def can_upload_quote?
    %w[entrepreneur intermediary].include?(role)
  end

  def can_validate_step?
    %w[owner architect intermediary].include?(role)
  end

  def full_financial_access?
    %w[owner intermediary].include?(role)
  end

  def can_post_message?
    %w[owner entrepreneur architect intermediary].include?(role)
  end

  def can_upload_photos?
    %w[owner entrepreneur architect intermediary].include?(role)
  end

  def can_edit_project?
    %w[owner intermediary].include?(role)
  end

  def can_manage_permis?
    %w[owner architect intermediary].include?(role)
  end

  def can_upload_metre?
    %w[owner architect intermediary].include?(role)
  end

  def can_view_metre?
    %w[owner architect entrepreneur intermediary].include?(role)
  end

  def role_label
    case role
    when 'owner'        then 'Propriétaire'
    when 'entrepreneur' then 'Entrepreneur'
    when 'architect'    then 'Architecte'
    when 'intermediary' then 'Intermédiaire'
    else role.humanize
    end
  end
end
