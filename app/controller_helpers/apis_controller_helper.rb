module ApisControllerHelper

  private

  def _with_cache_control(max_age = 2.minutes, is_public = true)
    expires_in max_age, public: is_public
    yield
  end

end

