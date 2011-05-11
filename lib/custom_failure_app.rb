class CustomFailureApp < Devise::FailureApp

protected

  def http_auth_body
    if scope == :api_token
      { :request => attempted_path, :error => i18n_message }.to_json
    else
      super
    end
  end
  
end
