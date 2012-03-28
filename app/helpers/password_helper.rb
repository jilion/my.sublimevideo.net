module PasswordHelper

  def password_box(options = {})
    resource       = options.delete(:resource)
    password_state = options.delete(:password_state)

    options[:password_description] = ["Your", password_state, "password is needed to perform this action:"].compact.join(" ")
    options[:password_label]       = [password_state, "password"].compact.join(" ").humanize
    options[:password_placeholder] = ["Your", password_state, "password"].compact.join(" ")

    resource && resource.errors.clear
    flash.clear

    render "password/box", options
  end

end
