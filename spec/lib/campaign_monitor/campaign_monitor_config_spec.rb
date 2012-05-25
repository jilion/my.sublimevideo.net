require 'spec_helper'

describe CampaignMonitorConfig do

  specify { CampaignMonitorConfig.api_key.should eq "8844ec1803ffbe6501c3d7e9cfa23bf3" }
  specify { CampaignMonitorConfig.lists.sublimevideo.list_id.should eq "a064dfc4b8ccd774252a2e9c9deb9244" }
  specify { CampaignMonitorConfig.lists.sublimevideo.segment.should eq "test" }
  specify { CampaignMonitorConfig.lists.sublimevideo_newsletter.list_id.should eq "a064dfc4b8ccd774252a2e9c9deb9244" }

end
