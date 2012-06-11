# require 'factory_girl'
# require 'factory_girl_rails'
# require Rails.root.join("spec/factories")

RSpec.configure do |config|
  # FactoryGirl http://railscasts.com/episodes/158-factories-not-fixtures-revised
  config.include FactoryGirl::Syntax::Methods
end
