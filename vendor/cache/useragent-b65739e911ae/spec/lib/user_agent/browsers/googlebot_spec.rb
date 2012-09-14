require 'spec_helper'

describe UserAgent::Browsers::Googlebot do

  describe "Googlebot" do
    it { "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)".should be_browser("Googlebot").compatible(true).version("2.1").crawler(true) }
    it { "Googlebot/2.1 (+http://www.googlebot.com/bot.html)".should be_browser("Googlebot").version("2.1").crawler(true) }
    it { "Googlebot/2.1 (+http://www.google.com/bot.html)".should be_browser("Googlebot").version("2.1").crawler(true) }
  end

end

