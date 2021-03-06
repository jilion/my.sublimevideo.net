# These methods are included into the Rails console
module ConsoleMethods
  # Find a user by id
  def u(user_id)
    User.find(user_id.to_i)
  end

  # Find a site by token
  def s(site_token)
    Site.where(token: site_token.to_s).first!
  end
end
