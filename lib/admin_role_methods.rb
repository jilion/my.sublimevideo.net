module AdminRoleMethods
  def has_role?(role)
    (roles & %W[god #{role}]).present?
  end
end
