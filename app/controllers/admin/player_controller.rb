class Admin::PlayerController < Admin::AdminController
  before_filter { |controller| require_role?('player') }
end
