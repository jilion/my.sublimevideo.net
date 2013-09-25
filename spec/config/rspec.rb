RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run_including focus: ENV['CI'] != 'true'
  config.mock_with :rspec
  config.fail_fast = ENV['CI'] != 'true'
  config.order = ENV['ORDER'] || 'random'
end
