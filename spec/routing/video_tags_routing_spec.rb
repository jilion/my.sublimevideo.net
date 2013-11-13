require 'spec_helper'

describe VideoTagsController do

  it { expect(get(with_subdomain('my', 'sites/1/videos'))).to route_to('video_tags#index', site_id: '1') }
  it { expect(get(with_subdomain('my', 'sites/1/video_tags/2'))).to route_to('video_tags#show', site_id: '1', id: '2') }

end
