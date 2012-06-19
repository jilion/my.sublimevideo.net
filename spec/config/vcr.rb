require 'vcr'

VCR.config do |config|
  config.stub_with :webmock, :typhoeus
  config.cassette_library_dir     = 'spec/fixtures/vcr_cassettes'
  config.ignore_localhost         = true
  config.default_cassette_options = { record: :new_episodes }
end

RSpec.configure do |config|
  config.extend VCR::RSpec::Macros
end
