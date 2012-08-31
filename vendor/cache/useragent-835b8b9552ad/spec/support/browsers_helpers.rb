require 'rspec/expectations'

RSpec::Matchers.define :be_browser do |browser|
  @version             = nil
  @type                = :browser
  @platform            = nil
  @os                  = nil
  @linux_distribution  = nil
  @language            = nil
  @mobile              = false
  @crawler             = false
  @chromeframe         = false
  @chromeframe_version = nil
  @gecko_version       = nil
  @security            = nil
  @compatible          = false
  @webkit_version      = nil
  @build               = nil

  chain :version              do |version|              @version              = version              end # mandatory
  chain :type                 do |type|                 @type                 = type                 end # optional
  chain :platform             do |platform|             @platform             = platform             end # optional
  chain :os                   do |os|                   @os                   = os                   end # optional
  chain :linux_distribution   do |linux_distribution|   @linux_distribution   = linux_distribution   end # optional
  chain :language             do |language|             @language             = language             end # optional
  chain :mobile               do |mobile|               @mobile               = mobile               end # optional
  chain :crawler              do |crawler|              @crawler              = crawler              end # optional
  chain :chromeframe          do |chromeframe|          @chromeframe          = chromeframe          end # optional
  chain :chromeframe_version  do |chromeframe_version|  @chromeframe_version  = chromeframe_version  end # optional
  chain :gecko_version        do |gecko_version|        @gecko_version        = gecko_version        end # optional
  chain :security             do |security|             @security             = security             end # optional
  chain :compatible           do |compatible|           @compatible           = compatible           end # optional
  chain :webkit_version       do |webkit_version|       @webkit_version       = webkit_version       end # optional
  chain :build                do |build|                @build                = build                end # optional

  match do |user_agent_string|
    @ua = UserAgent.parse(user_agent_string)

    browser              = "Internet Explorer" if browser == "IE" # shortcut
    @type                = :browser unless @type
    @platform            = nil      unless @platform
    @os                  = nil      unless @os
    @linux_distribution  = nil      unless @linux_distribution
    @language            = nil      unless @language
    @mobile              = false    unless @mobile
    @crawler             = false    unless @crawler
    @chromeframe         = false    unless @chromeframe
    @chromeframe_version = nil      unless @chromeframe_version
    @gecko_version       = nil      unless @gecko_version
    @security            = nil      unless @security
    @compatible          = false    unless @compatible
    @webkit_version      = nil      unless @webkit_version
    @build               = nil      unless @build

    if false # debug
      puts "CLASS: #{@ua.class.name}"
      puts @ua.inspect
      puts "ACTUAL/EXPECTED"
      puts "Browser: #{@ua.browser}/#{browser}"                                   unless @ua.browser == browser
      puts "Type: #{@ua.type}/#{@type}"                                           unless @ua.type == @type
      puts "Version: #{@ua.version}/#{@version}"                                  unless @ua.version == @version
      puts "Platform: #{@ua.platform}/#{@platform}"                               unless @ua.platform == @platform
      puts "OS: #{@ua.os}/#{@os}"                                                 unless @ua.os == @os
      puts "Linux Distribution: #{@ua.linux_distribution}/#{@linux_distribution}" unless @ua.linux_distribution == @linux_distribution
      puts "Language: #{@ua.language}/#{@language}"                               unless @ua.language == @language
      puts "Mobile: #{@ua.mobile?}/#{@mobile}"                                    unless @ua.mobile? == @mobile
      puts "Crawler: #{@ua.crawler?}/#{@crawler}"                                 unless @ua.crawler? == @crawler
      puts "Security: #{@ua.security}/#{@security}"                               unless @ua.security == @security

      puts "Compatible: #{@ua.compatible?}/#{@compatible}" unless !@ua.respond_to?(:compatible?) || (@ua.compatible? == @compatible)
      if @ua.respond_to?(:chromeframe)
        puts "Chromeframe: #{@ua.chromeframe}/#{@chromeframe}"                         unless !@ua.chromeframe.nil? == @chromeframe
        puts "Chromeframe Version: #{@ua.chromeframe_version}/#{@chromeframe_version}" unless (@ua.chromeframe_version == @chromeframe_version)
      end

      if @ua.webkit?
        puts "Webkit Version: #{@ua.webkit.version}/#{@webkit_version}" unless !@ua.webkit? || (@ua.webkit.version == @webkit_version)
        puts "Build: #{@ua.build}/#{@build}"                            unless !@ua.webkit? || (@ua.build == @build)
      end

      puts "Gecko Version: #{@ua.gecko_version}/#{@gecko_version}" unless !@ua.gecko? || (@ua.gecko_version == @gecko_version)
    end

    ie_conditions     = !@ua.respond_to?(:compatible?) || (@ua.compatible? == @compatible) &&
                        !@ua.respond_to?(:chromeframe) || (@ua.respond_to?(:chromeframe) && !@ua.chromeframe.nil? == @chromeframe && @ua.chromeframe_version == @chromeframe_version)
    webkit_conditions = !@ua.webkit? || (@ua.webkit.version == @webkit_version && @ua.build == @build)
    gecko_conditions  = !@ua.gecko? || (@ua.gecko_version == @gecko_version)

    @ua.browser == browser && @ua.type == @type && @ua.version == @version && @ua.platform == @platform &&
      @ua.os == @os && @ua.linux_distribution == @linux_distribution && @ua.language == @language &&
      @ua.security == @security && @ua.mobile? == @mobile && @ua.crawler? == @crawler && ie_conditions && webkit_conditions && gecko_conditions
  end

  failure_message_for_should do |user_agent_string|
    message = "Expected '#{user_agent_string}' to represent:\n"
    message += "\nBrowser: '#{@ua.browser}', '#{browser}' was expected"                                   unless @ua.browser == browser
    message += "\nType: '#{@ua.type}', '#{@type}' was expected"                                           unless @ua.type == @type
    message += "\nVersion: '#{@ua.version}', '#{@version}' was expected"                                  unless @ua.version == @version
    message += "\nPlatform: '#{@ua.platform}', '#{@platform}' was expected"                               unless @ua.platform == @platform
    message += "\nOS: '#{@ua.os}', '#{@os}' was expected"                                                 unless @ua.os == @os
    message += "\nLinux Distribution: '#{@ua.linux_distribution}', '#{@linux_distribution}' was expected" unless @ua.linux_distribution == @linux_distribution
    message += "\nLanguage: '#{@ua.language}', '#{@language}' was expected"                               unless @ua.language == @language
    message += "\nSecurity: '#{@ua.security}', '#{@security}' was expected"                               unless @ua.security == @security
    message += "\nMobile: '#{@ua.mobile?}', '#{@mobile}' was expected"                                    unless @ua.mobile? == @mobile
    message += "\nCrawler: '#{@ua.crawler?}', '#{@crawler}' was expected"                                 unless @ua.crawler? == @crawler

    message += "\nCompatible: '#{@ua.compatible?}', '#{@compatible}' was expected" unless !@ua.respond_to?(:compatible?) || (@ua.compatible? == @compatible)

    if @ua.respond_to?(:chromeframe)
      message += "\nChromeframe: '#{@ua.chromeframe}', '#{@chromeframe}' was expected"                         unless !@ua.chromeframe.nil? == @chromeframe
      message += "\nChromeframe Version: '#{@ua.chromeframe_version}', '#{@chromeframe_version}' was expected" unless @ua.chromeframe_version == @chromeframe_version
    end

    if @ua.webkit?
      message += "\nWebkit Version: '#{@ua.webkit.version}', '#{@webkit_version}' was expected" unless @ua.webkit.version == @webkit_version
      message += "\nWebkit Build: '#{@ua.build}', '#{@build}' was expected"                     unless @ua.build == @build
    end

    message += "\nGecko Version: '#{@ua.gecko_version}', '#{@gecko_version}' was expected" unless !@ua.gecko? || @ua.gecko_version == @gecko_version

    message
  end

end
