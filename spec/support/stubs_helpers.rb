module Spec
  module Support
    module StubsHelpers

      def stub_site_stats
        allow(SiteStat).to receive(:last_hours_stats) { [] }
        allow(LastSiteStat).to receive(:last_stats) { [] }
        allow(LastSitePlay).to receive(:last_plays) { [] }
        allow(SiteAdminStat).to receive(:all) { [] }
      end

    end
  end
end

RSpec.configure do |config|
  config.include Spec::Support::StubsHelpers
end
