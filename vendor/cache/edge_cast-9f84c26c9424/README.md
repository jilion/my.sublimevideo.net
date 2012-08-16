# EdgeCast

EdgeCast Web Services REST API Ruby wrapper.

## Installation

Add this line to your application's Gemfile:

    gem 'edge_cast'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install edge_cast

## Usage

```ruby
edge_cast = EdgeCast.new(:account_number => '1234', :api_token => 'abcd1234')

# Cache compression settings
edge_cast.compression(:http_small_object)
edge_cast.enable_compression(:http_small_object, ['text/javascript'])
edge_cast.disable_compression(:http_small_object, ['text/javascript'])

# Cache query string caching settings
edge_cast.query_string_caching(:http_small_object)
edge_cast.update_query_string_caching(:http_small_object, 'no-cache')


# Cache query string logging settings
edge_cast.query_string_logging(:http_small_object)
edge_cast.update_query_string_logging(:http_small_object, 'no-log')


# Cache management
edge_cast.load(:http_small_object, '/foo/bar.js')
edge_cast.purge(:http_small_object, '/foo/bar.js')

# Token-Based Authentication
edge_cast.encrypt_token_data(:key => 'abcd1234', :token_parameter => 'ec_expire=1356955200&ec_country_deny=CA&ec_country_allow=US,MX')

```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
