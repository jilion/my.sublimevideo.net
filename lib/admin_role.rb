class AdminRole < Settingslogic
  source "#{Rails.root}/config/admin_role.yml"
end

module AdminRoleMethods

  def has_role?(role)
    (roles & %W[god #{role}]).present?
  end

end
