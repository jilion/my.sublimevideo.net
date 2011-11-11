require 'spec_helper'

describe VideoTagsController do

  it { { get: 'sites/1/video_tags/2' }.should route_to(controller: 'video_tags', site_id: '1', id: '2', action: 'show') }

end
