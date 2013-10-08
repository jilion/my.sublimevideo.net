module Spec
  module Support
    module StubsHelpers

      def stub_site_stats
        SiteStat.stub(:last_hours_stats) { [] }
        LastSiteStat.stub(:last_stats) { [] }
        LastSitePlay.stub(:last_plays) { [] }
        SiteAdminStat.stub(:all) { [] }
      end

    end
  end
end

RSpec.configure do |config|
  config.include Spec::Support::StubsHelpers
end
