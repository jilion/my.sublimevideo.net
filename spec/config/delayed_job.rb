RSpec.configure do |config|
  config.before(:suite) do
    $worker = Delayed::Worker.new(quiet: true)
  end
end
