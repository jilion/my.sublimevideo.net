require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock, :typhoeus
  c.ignore_hosts 'sublimevideo.dev', 'example.com', 'codeclimate.com'
  c.ignore_localhost = true
  c.default_cassette_options = { record: :new_episodes }
  c.configure_rspec_metadata!
end
WebMock.disable_net_connect!(allow: "codeclimate.com")
