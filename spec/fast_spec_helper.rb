require_relative 'support/stubs'
require_relative 'support/redis'
require_relative 'support/vcr'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run_including focus: true
end