require 'spec_helper'

describe VideoTagsController do

  it { get(with_subdomain('my', 'sites/1/videos')).should route_to('video_tags#index', site_id: '1') }
  it { get(with_subdomain('my', 'sites/1/video_tags/2')).should route_to('video_tags#show', site_id: '1', id: '2') }

end
