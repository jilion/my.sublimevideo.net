# This example the following variables to be defined in its context:
#  - url => the url to GET
#  - expected_last_modified => the first expected 'Last-Modified' (unless the :cache_validation option is set to false)
#  - update_record => a proc that when called should update a resource and
#    thus, stale the next response
#
# @note You can omit `expected_last_modified` if you set the
#   `:cache_validation` to false
#
shared_examples 'valid caching headers' do |opts = {}|
  it 'responds with the right caching headers depending on the request headers' do
    options = { cache_control: 'max-age=120, public', cache_validation: true }.merge(opts)
    get url, {}, @env

    response.status.should eq 200
    response.headers['Cache-Control'].should eq options[:cache_control]
    if options[:cache_validation]
      (etag = response.headers['Etag']).should be_present
      (last_modified = response.headers['Last-Modified']).should eq expected_last_modified.httpdate
    end

    if options[:cache_validation]
      Timecop.travel(5.seconds.from_now) do
        # Conditional request
        @env.merge!('HTTP_IF_NONE_MATCH' => etag, 'HTTP_IF_MODIFIED_SINCE' => last_modified)
        get url, {}, @env

        response.status.should eq 304
        response.headers['Cache-Control'].should eq options[:cache_control]
        response.headers['Etag'].should eq etag
        response.headers['Last-Modified'].should eq last_modified

        # Make the resource staled
        update_record.call

        get url, {}, @env
        response.status.should eq 200
        response.headers['Cache-Control'].should eq options[:cache_control]
        response.headers['Etag'].should_not eq etag
        response.headers['Last-Modified'].should_not eq last_modified
      end
    end
  end
end
