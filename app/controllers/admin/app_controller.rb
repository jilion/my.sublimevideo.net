class Admin::AppController < Admin::AdminController
  before_filter { |controller| require_role?('player') }
end
