require 'spec_helper'

describe UserAgent::Browsers::GooglebotMobile do

  describe "Googlebot-Mobile" do
    it { "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_1 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8B117 Safari/6531.22.7 (compatible; Googlebot-Mobile/2.1; +http://www.google.com/bot.html)".
      should be_browser("Googlebot-Mobile").
      platform('iPhone').
      security(:strong).
      webkit_version('532.9').
      build('532.9').
      language('en-US').
      compatible(true).
      version("2.1").
      crawler(true).
      mobile(true) }
    it { "Googlebot-Mobile/2.1; +http://www.google.com/bot.html".should be_browser("Googlebot-Mobile").version("2.1").crawler(true).mobile(true) }
    it { "Googlebot-Mobile".should be_browser("Googlebot-Mobile").version(nil).crawler(true).mobile(true) }
end

end

