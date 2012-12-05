require 'highrise'
require_dependency 'highrise_wrapper'

Highrise::Base.site   = HighriseWrapper.url
Highrise::Base.user   = HighriseWrapper.api_token
Highrise::Base.format = :xml
