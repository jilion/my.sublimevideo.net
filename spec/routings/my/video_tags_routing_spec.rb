require 'spec_helper'

describe My::VideoTagsController do

  it { get(with_subdomain('my', 'sites/1/video_tags/2')).should route_to('my/video_tags#show', site_id: '1', id: '2') }

end
