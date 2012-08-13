require 'spec_helper'

describe UserAgent::Browsers::Opera do

  describe "comparisons" do
    before(:all) do
      @opera_9_26 = UserAgent.parse("Opera/9.26 (Macintosh; Intel Mac OS X; U; en)")
      @opera_9_27 = UserAgent.parse("Opera/9.27 (Windows NT 5.1; U; en)")
      @opera_9_28 = UserAgent.parse("Opera/9.28 (Windows NT 5.1; U; en)")
    end

    specify { @opera_9_27.should_not == @opera_9_26 }
    specify { @opera_9_27.should_not <  @opera_9_26 }
    specify { @opera_9_27.should_not <= @opera_9_26 }
    specify { @opera_9_27.should     >  @opera_9_26 }
    specify { @opera_9_27.should     >= @opera_9_26 }

    specify { @opera_9_27.should     == @opera_9_27 }
    specify { @opera_9_27.should_not <  @opera_9_27 }
    specify { @opera_9_27.should     <= @opera_9_27 }
    specify { @opera_9_27.should_not >  @opera_9_27 }
    specify { @opera_9_27.should     >= @opera_9_27 }

    specify { @opera_9_27.should_not == @opera_9_28 }
    specify { @opera_9_27.should     <  @opera_9_28 }
    specify { @opera_9_27.should     <= @opera_9_28 }
    specify { @opera_9_27.should_not >  @opera_9_28 }
    specify { @opera_9_27.should_not >= @opera_9_28 }
  end

  describe "Unknown os (very short comment)" do
    it { "Opera/9.23 (Windows NT 5.0;)".should be_browser("Opera").platform("Windows").os("Windows 2000").version("9.23") }
    it { "Opera/9.23 (Windows NT 5.0; U;)".should be_browser("Opera").platform("Windows").os("Windows 2000").version("9.23").security(:strong) }
  end

  describe "os not in the first comment" do
    it { "Opera/9.23 (foo; bar;) (Mac OS X; fr)".should be_browser("Opera").version("9.23").platform("Macintosh").os("OS X").language("fr") }
    it { "Opera/9.23 (foo; bar;) (Macintosh; Intel Mac OS X; fr)".should be_browser("Opera").version("9.23").platform("Macintosh").os("Intel Mac OS X").language("fr") }
  end

  describe "Without comment" do
    it { "Opera/9.23 Linux".should be_browser("Opera").version("9.23").platform("Linux") }
  end

  describe "Opera" do
    describe "Windows" do
      it { "Opera/9.23 (Windows NT 5.0; U; en)".should be_browser("Opera").version("9.23").platform("Windows").os("Windows 2000").language("en").security(:strong) }
      it { "Opera/9.23 (Windows NT 5.0; U; de)".should be_browser("Opera").version("9.23").platform("Windows").os("Windows 2000").language("de").security(:strong) }
      it { "Opera/9.23 (Windows NT 5.1; U; zh-cn)".should be_browser("Opera").version("9.23").platform("Windows").os("Windows XP").language("zh-CN").security(:strong) }
      it { "Opera/9.23 (Windows NT 5.1; U; SV1; MEGAUPLOAD 1.0; ru)".should be_browser("Opera").version("9.23").platform("Windows").os("Windows XP").language("ru").security(:strong) }
      it { "Opera/9.23 (Windows NT 5.1; U; pt)".should be_browser("Opera").version("9.23").platform("Windows").os("Windows XP").language("pt").security(:strong) }
      it { "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; es-es) Opera 9.23".should be_browser("Opera").version("9.23").platform("Windows").os("Windows XP").language("es-ES") }
      it { "Mozilla/5.0 (Windows NT 5.1; U; de; rv:1.8.0) Gecko/20060728 Firefox/1.5.0 Opera 9.23".should be_browser("Opera").version("9.23").platform("Windows").os("Windows XP").language("de").security(:strong) }
      it { "Opera/9.23 (Windows NT 6.0; U; de)".should be_browser("Opera").version("9.23").platform("Windows").os("Windows Vista").language("de").security(:strong) }
      it { "Opera/9.23 (Windows NT 6.0; U; it)".should be_browser("Opera").version("9.23").platform("Windows").os("Windows Vista").language("it").security(:strong) }
      it { "Opera/9.23 (Windows NT 6.0; U; fi)".should be_browser("Opera").version("9.23").platform("Windows").os("Windows Vista").language("fi").security(:strong) }
      it { "Opera/9.23 (Windows NT 6.0; U; da)".should be_browser("Opera").version("9.23").platform("Windows").os("Windows Vista").language("da").security(:strong) }
      it { "Opera/9.27 (Windows NT 5.1; U; en)".should be_browser("Opera").version("9.27").platform("Windows").os("Windows XP").language("en").security(:strong) }
      it { "Opera/9.80 (Windows NT 5.1; U; ru) Presto/2.7.62 Version/11.01".should be_browser("Opera").version("11.01").platform("Windows").os("Windows XP").language("ru").security(:strong) }
    end

    describe "Macintosh" do
      it { "Opera/9.23 (Macintosh; Intel Mac OS X; U; ja)".should be_browser("Opera").version("9.23").platform("Macintosh").os("Intel Mac OS X").language("ja").security(:strong) }
      it { "Opera/9.23 (Mac OS X; ru)".should be_browser("Opera").version("9.23").platform("Macintosh").os("OS X").language("ru") }
      it { "Opera/9.23 (Mac OS X; fr)".should be_browser("Opera").version("9.23").platform("Macintosh").os("OS X").language("fr") }
      it { "Opera/9.27 (Macintosh; Intel Mac OS X; U; en)".should be_browser("Opera").version("9.27").platform("Macintosh").os("Intel Mac OS X").language("en").security(:strong) }
      it { "Opera/9.80 (Macintosh; Intel Mac OS X 10.7.1; U; en) Presto/2.9.168 Version/11.51".should be_browser("Opera").version("11.51").platform("Macintosh").os("Intel Mac OS X 10.7.1").language("en").security(:strong) }
    end

    describe "Linux" do
      it { "Opera/9.23 (X11; Linux x86_64; U; en)".should be_browser("Opera").version("9.23").platform("Linux").os("Linux x86_64").language("en").security(:strong) }
      it { "Opera/9.23 (X11; Linux i686; U; es-es)".should be_browser("Opera").version("9.23").platform("Linux").os("Linux i686").language("es-ES").security(:strong) }
      it { "Opera/9.23 (X11; Linux i686; U; en)".should be_browser("Opera").version("9.23").platform("Linux").os("Linux i686").language("en").security(:strong) }
      it { "Mozilla/4.0 (compatible; MSIE 6.0; X11; Linux i686; en) Opera 9.23".should be_browser("Opera").version("9.23").platform("Linux").os("Linux i686").language("en") }
      it { "Mozilla/5.0 (X11; Linux i686; U; en; rv:1.8.0) Gecko/20060728 Firefox/1.5.0 Opera 9.23".should be_browser("Opera").version("9.23").platform("Linux").os("Linux i686").language("en").security(:strong) }
      it { "Opera/9.27 (X11; Linux x86_64; U; en)".should be_browser("Opera").version("9.27").platform("Linux").os("Linux x86_64").language("en").security(:strong) }
    end

    describe "Wii" do
      # Console
      it { "Opera/9.23 (Nintendo Wii; U; ; 1038-58; Wii Internet Channel/1.0; en)".should be_browser("Opera").version("9.23").type(:console).platform("Nintendo Wii").language("en").security(:strong) }
      it { "Opera/9.30 (Nintendo Wii; U; ; 3642; en)".should be_browser("Opera").version("9.30").type(:console).platform("Nintendo Wii").language("en").security(:strong) }
    end

  end

  describe "Opera Mini" do
    it { "Opera/9.80 (Series 60; Opera Mini/5.1.22784/22.394; U; en) Presto/2.5.25 Version/10.54".should be_browser("Opera Mini").version("5.1.22784").language("en").security(:strong).mobile(true) }
    it { "Opera/9.80 (J2ME/MIDP; Opera Mini/4.2.14613/23.317; U; en) Presto/2.5.25 Version/10.54".should be_browser("Opera Mini").version("4.2.14613").language("en").security(:strong).mobile(true) }
    it { "SAMSUNG-SGH-A797/A797UCIIB; Mozilla/5.0 (Profile/MIDP-2.0 Configuration/CLDC-1.1; Opera Mini/att/4.2.15354; U; en-US) Opera 9.50".should be_browser("Opera Mini").version("att").platform("Samsung").language("en-US").security(:strong).mobile(true) }
    it { "Opera/9.80 (J2ME/MIDP; Opera Mini/5.0 (iPod; U; CPU iPhone OS 4_1 like Mac OS X; en-gb) AppleWebKit/20.2497; U; en) Presto/2.5.25".should be_browser("Opera Mini").version("5.0").platform("iPod").os("iOS 4.1").language("en").security(:strong).mobile(true) }
    it { "Opera/9.80 (J2ME/MIDP; Opera Mini/5.1.21214 (iPhone 4.0 Simulator; iPod Touch; U; CPU iPhone OS 4_0 like Mac OS X 10_6_4; en-US) Apple iPhone OS v4.0 CoreMedia v2.0.0.7A400; GTB5.0.20090324; rv:1.9.3a".should be_browser("Opera Mini").version("5.1.21214").platform("iPhone Simulator").os("iOS 4.0").security(:strong).mobile(true) }
    it { "Opera/9.80 (J2ME/MIDP; Opera Mini/1.1.0 (Linux; U; Android 2.1-update1; Nexus One Build/20.2485; U; en) Presto/2.5.25".should be_browser("Opera Mini").version("1.1.0").platform("Android").os("Android 2.1-update1").security(:strong).mobile(true) }
    it { "Opera/9.80 (J2ME/MIDP; Opera Mini (Linux; U; Android 2.1-update1; Nexus One Build/20.2485; U; en) Presto/2.5.25".should be_browser("Opera Mini").platform("Android").os("Android 2.1-update1").security(:strong).mobile(true) }
    it { "Opera/9.80 (J2ME/MIDP; Opera Mini//25.858; U; en) Presto/2.5.25 Version/10.54".should be_browser("Opera Mini").version("25.858").language("en").security(:strong).mobile(true) }
  end

  describe "Opera Mobile" do
    it { "Opera/9.80 (Android; Linux; Opera Mobi/ADR-1012221546; U; pl) Presto/2.7.60 Version/10.5".should be_browser("Opera Mobile").version("10.5").platform("Android").os("Android").language("pl").security(:strong).mobile(true) }
    it { "Opera/9.80 (Android 2.2; Opera Mobi/-2118645896; U; pl) Presto/2.7.60 Version/10.5".should be_browser("Opera Mobile").version("10.5").platform("Android").os("Android 2.2").language("pl").security(:strong).mobile(true) }
  end

end
