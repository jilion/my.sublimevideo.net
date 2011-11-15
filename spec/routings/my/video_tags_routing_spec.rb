require 'spec_helper'

describe My::VideoTagsController do

  it { { get: 'sites/1/video_tags/2' }.should route_to(controller: 'video_tags', site_id: '1', id: '2', action: 'show') }

end
