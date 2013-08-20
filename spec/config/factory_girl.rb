RSpec.configure do |config|
  # FactoryGirl http://railscasts.com/episodes/158-factories-not-fixtures-revised
  config.include FactoryGirl::Syntax::Methods

  # Spring issue https://github.com/jonleighton/spring/issues/88
  config.before(:all) do
    FactoryGirl.reload
  end
end
