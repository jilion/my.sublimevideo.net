require 'spec_helper'

describe UserAgent::Browsers::Webkit do

  describe "comparisons" do
    before(:all) do
      @safari_419_3  = UserAgent.parse("Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/419 (KHTML, like Gecko) Safari/419.3")
      @safari_525_18 = UserAgent.parse("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.18")
      @safari_526_8  = UserAgent.parse("Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/526.9 (KHTML, like Gecko) Version/4.0dp1 Safari/526.8")
    end

    specify { @safari_525_18.should_not == @safari_419_3 }
    specify { @safari_525_18.should_not <  @safari_419_3 }
    specify { @safari_525_18.should_not <= @safari_419_3 }
    specify { @safari_525_18.should     >  @safari_419_3 }
    specify { @safari_525_18.should     >= @safari_419_3 }

    specify { @safari_525_18.should     == @safari_525_18 }
    specify { @safari_525_18.should_not <  @safari_525_18 }
    specify { @safari_525_18.should     <= @safari_525_18 }
    specify { @safari_525_18.should_not >  @safari_525_18 }
    specify { @safari_525_18.should     >= @safari_525_18 }

    specify { @safari_525_18.should_not == @safari_526_8 }
    specify { @safari_525_18.should     <  @safari_526_8 }
    specify { @safari_525_18.should     <= @safari_526_8 }
    specify { @safari_525_18.should_not >  @safari_526_8 }
    specify { @safari_525_18.should_not >= @safari_526_8 }
  end

  describe UserAgent::Browsers::Webkit do

    describe "Unknown os (very short comment)" do
      it { "Mozilla/5.0 (foo;) AppleWebKit/527+ Arora/0.8.0".should be_browser("Arora").version("0.8.0").webkit_version("527+").build("527+").security(:strong) }
      it { "Mozilla/5.0 (foo; U;) AppleWebKit/527+ Arora/0.8.0".should be_browser("Arora").version("0.8.0").webkit_version("527+").build("527+").security(:strong) }
      it { "Mozilla/5.0 (foo; I;) AppleWebKit/527+ Arora/0.8.0".should be_browser("Arora").version("0.8.0").webkit_version("527+").build("527+").security(:weak) }
      it { "Mozilla/5.0 (foo; N;) AppleWebKit/527+ Arora/0.8.0".should be_browser("Arora").version("0.8.0").webkit_version("527+").build("527+").security(:none) }
    end

    describe "Without comment" do
      it { "Mozilla/5.0 AppleWebKit/527+ Arora/0.8.0".should be_browser("Arora").version("0.8.0").webkit_version("527+").build("527+").security(:strong) }
    end

    describe "AdobeAIR" do
      it { "Mozilla/5.0 (Windows; U; en-US) AppleWebKit/531.9 (KHTML, like Gecko) AdobeAIR/2.5.1".should be_browser("AdobeAIR").version("2.5.1").webkit_version("531.9").build("531.9").platform("Windows").os("Windows").language("en-US").security(:strong) }
    end

    describe "Arora" do
      it { "Mozilla/5.0 (X11; U; Linux; de-DE) AppleWebKit/527+ (KHTML, like Gecko, Safari/419.3)  Arora/0.8.0".should be_browser("Arora").version("0.8.0").webkit_version("527+").build("527+").platform("Linux").os("Linux").language("de-DE").security(:strong) }
    end

    describe "Android" do
      it { "Mozilla/5.0 (Linux; U; Android 1.5; de-; HTC Magic Build/PLAT-RC33) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1".should be_browser("Android").version("3.1.2").webkit_version("528.5+").build("528.5+").platform("Android").os("Android 1.5").language("de").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (Linux; U; Android 2.1-update1; en-us; Nexus One Build/ERE27) AppleWebKit/530.17 (KHTML, like Gecko) Version/4.0 Mobile Safari/530.17 Chrome/4.1.249.1025".should be_browser("Android").version("4.0").webkit_version("530.17").build("530.17").platform("Android").os("Android 2.1-update1").language("en-US").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (Linux; U; Android 2.2; ja-jp; SBM003SH Build/S1100) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1".should be_browser("Android").version("4.0").webkit_version("533.1").build("533.1").platform("Android").os("Android 2.2").language("ja-JP").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (Linux; U; Android 1.6; es-mx; SonyEricssonX10a Build/R2BA026) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1".should be_browser("Android").version("3.1.2").webkit_version("528.5+").build("528.5+").platform("Android").os("Android 1.6").language("es-MX").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (Linux; U; Android 2.2.1; en-us; Droid Build/FRG83D) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1".should be_browser("Android").version("4.0").webkit_version("533.1").build("533.1").platform("Android").os("Android 2.2.1").language("en-US").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (Linux; U; Android 1.5; en-us; MB200 Build/CUPCAKE) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1".should be_browser("Android").version("3.1.2").webkit_version("528.5+").build("528.5+").platform("Android").os("Android 1.5").language("en-US").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (Linux; U; Android 2.2.1; en-us; T-Mobile myTouch 3G Build/FRG83D) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1".should be_browser("Android").version("4.0").webkit_version("533.1").build("533.1").platform("Android").os("Android 2.2.1").language("en-US").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (Linux; U; Android 2.1-update1; en-us; SCH-I500 Build/ECLAIR) AppleWebKit/530.17 (KHTML, like Gecko) Version/4.0 Mobile Safari/530.17".should be_browser("Android").version("4.0").webkit_version("530.17").build("530.17").platform("Android").os("Android 2.1-update1").language("en-US").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (Linux; U; Android 1.6; en-gb; HTC Magic Build/DRC92) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1".should be_browser("Android").version("3.1.2").webkit_version("528.5+").build("528.5+").platform("Android").os("Android 1.6").language("en-GB").security(:strong).mobile(true) }
      it { "(Linux; U; Android 1.5; de-; HTC Magic Build/PLAT-RC33) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1 ".should be_browser("Android").version("3.1.2").webkit_version("528.5+").build("528.5+").platform("Android").os("Android 1.5").language("de").security(:strong).mobile(true) }
      it { "LG-GW620 Mozilla/5.0 (Linux; U; Android 1.5) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1 Java/Jbed/7.0 Profile/MIDP-2.1 Configuration/CLDC-1.1 MMS/LG-Android-MMS-V1.0/1".should be_browser("Android").version("3.1.2").webkit_version("528.5+").build("528.5+").platform("Android").os("Android 1.5").security(:strong).mobile(true) }
      it { "HTC Dream Mozilla/5.0 (Linux; U; Android 1.5; en-ca; Build/CUPCAKE) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1".should be_browser("Android").version("3.1.2").webkit_version("528.5+").build("528.5+").platform("Android").os("Android 1.5").language("en-CA").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (Linux; U; Android 1.6; en-us; AOSP on Dream (US) Build/Donut) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1".should be_browser("Android").version("3.1.2").webkit_version("528.5+").build("528.5+").platform("Android").os("Android 1.6").language("en-US").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (Linux; U; Android 1.6; fr-fr; LG-GT540 ; Build/Donut) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1 Java/Jbed/7.0 Profile/MIDP-2.1 Configuration/CLDC-1.1 MMS".should be_browser("Android").version("3.1.2").webkit_version("528.5+").build("528.5+").platform("Android").os("Android 1.6").language("fr-FR").security(:strong).mobile(true) }
    end

    describe "BlackBerry" do
      it { "Mozilla/5.0 (BlackBerry; U; BlackBerry 9800; en) AppleWebKit/534.1+ (KHTML, Like Gecko) Version/6.0.0.141 Mobile Safari/534.1+".should be_browser("BlackBerry").version("6.0.0.141").webkit_version("534.1+").build("534.1+").platform("BlackBerry").os("BlackBerryOS").language("en").security(:strong).mobile(true) }
    end

    describe "Chrome" do
      describe "Windows" do
        it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/525.13 (KHTML, like Gecko) Chrome/0.0.2 Safari/525.13".should be_browser("Chrome").version("0.0.2").webkit_version("525.13").build("525.13").platform("Windows").os("Windows XP").language("en-US").security(:strong) }
        it { "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.2 (KHTML, like Gecko) Chrome/6.0".should be_browser("Chrome").version("6.0").webkit_version("533.2").build("533.2").platform("Windows").os("Windows 7").language("en-US").security(:strong) }
      end

      describe "Macintosh" do
        it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; en-US) AppleWebKit/534.10 (KHTML, like Gecko) Chrome/8.0.552.231 Safari/534.10".should be_browser("Chrome").version("8.0.552.231").webkit_version("534.10").build("534.10").platform("Macintosh").os("Intel Mac OS X 10.6.5").language("en-US").security(:strong) }
      end

      describe "Linux" do
        it { "Mozilla/5.0 (X11; U; Linux i686; en-US) AppleWebKit/534.10 (KHTML, like Gecko) Ubuntu/10.10 Chromium/8.0.552.237 Chrome/8.0.552.237 Safari/534.10".should be_browser("Chrome").version("8.0.552.237").webkit_version("534.10").build("534.10").platform("Linux").os("Linux i686").linux_distribution("Ubuntu 10.10").language("en-US").security(:strong) }
      end
    end

    describe "Epiphany" do
      it { "Mozilla/5.0 (X11; U; Linux i686; en-ca) AppleWebKit/531.2+ (KHTML, like Gecko) Safari/531.2+ Epiphany/2.30.2".should be_browser("Epiphany").version("2.30.2").webkit_version("531.2+").build("531.2+").platform("Linux").os("Linux i686").language("en-CA").security(:strong) }
    end

    describe "Fluid" do
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_1; nl-nl) AppleWebKit/532.3+ (KHTML, like Gecko) Fluid/0.9.6 Safari/532.3+".should be_browser("Fluid").version("0.9.6").webkit_version("532.3+").build("532.3+").platform("Macintosh").os("Intel Mac OS X 10.6.1").language("nl-NL").security(:strong) }
    end

    describe "Gruml" do
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; de-de) AppleWebKit/533.17.8 (KHTML, like Gecko) Gruml/0.9.22".should be_browser("Gruml").version("0.9.22").webkit_version("533.17.8").build("533.17.8").platform("Macintosh").os("Intel Mac OS X 10.6.4").language("de-DE").security(:strong) }
    end

    describe "Iron" do
      it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US) AppleWebKit/532.0 (KHTML, like Gecko) Iron/3.0.197.0 Safari/532.0".should be_browser("Iron").version("3.0.197.0").webkit_version("532.0").build("532.0").platform("Windows").os("Windows XP").language("en-US").security(:strong) }
    end

    describe "Maxthon" do
      it { "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.9 (KHTML, like Gecko) Maxthon/3.0 Safari/533.9".should be_browser("Maxthon").version("3.0").webkit_version("533.9").build("533.9").platform("Windows").os("Windows 7").language("en-US").security(:strong) }
    end

    describe "Midori" do
      it { "Mozilla/5.0 (X11; U; Linux; it-it) AppleWebKit/531+ (KHTML, like Gecko) Safari/531.2+ Midori/0.3".should be_browser("Midori").version("0.3").webkit_version("531+").build("531+").platform("Linux").os("Linux").language("it-IT").security(:strong) }
    end

    describe "NetNewsWire" do
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; de-de) AppleWebKit/531.22.7 (KHTML, like Gecko) NetNewsWire/3.2.7".should be_browser("NetNewsWire").version("3.2.7").webkit_version("531.22.7").build("531.22.7").platform("Macintosh").os("Intel Mac OS X 10.6.3").language("de-DE").security(:strong) }
    end

    describe "OmniWeb" do
      it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/522+ (KHTML, like Gecko) OmniWeb".should be_browser("OmniWeb").webkit_version("522+").build("522+").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; it-IT) AppleWebKit/125.4 (KHTML, like Gecko, Safari) OmniWeb/v563.15".should be_browser("OmniWeb").version("563.15").webkit_version("125.4").build("125.4").platform("Macintosh").os("PPC Mac OS X").language("it-IT").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US) AppleWebKit/528.16 (KHTML, like Gecko, Safari/528.16) OmniWeb/v622.8.0.112941".should be_browser("OmniWeb").version("622.8.0.112941").webkit_version("528.16").build("528.16").platform("Macintosh").os("Intel Mac OS X").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; PowerPC Mac OS X 10_5_8; en-US) AppleWebKit/531.9+(KHTML, like Gecko, Safari/528.16) OmniWeb/v622.10.0".should be_browser("OmniWeb").version("622.10.0").webkit_version("531.9+").build("531.9+").platform("Macintosh").os("PowerPC Mac OS X 10.5.8").language("en-US").security(:strong) }
    end

    describe "Dolfin" do
      it { "Mozilla/5.0 (SAMSUNG; SAMSUNG-GT-S5380D/1.0; U; Bada/2.0; en-us) AppleWebKit/534.20 (KHTML, like Gecko) Dolfin/3.0 Mobile HVGA SMM-MMS/1.2.0 OPN-B".should be_browser("Dolfin").version("3.0").webkit_version("534.20").build("534.20").platform("Samsung").os("Bada 2.0").language("en-US").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (SAMSUNG; SAMSUNG-GT-S8500/S8500XXJEE; U; Bada/1.0; sv-se) AppleWebKit/533.1 (KHTML, like Gecko) Dolfin/2.0 Mobile WVGA SMM-MMS/1.2.0 OPN-B".should be_browser("Dolfin").version("2.0").webkit_version("533.1").build("533.1").platform("Samsung").os("Bada 1.0").language("sv-SE").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (SAMSUNG; SAMSUNG-GT-S8530-ORANGE/S8530BVKA1; U; Bada/1.2; fr-fr) AppleWebKit/533.1 (KHTML, like Gecko) Dolfin/2.2 Mobile WVGA SMM-MMS/1.2.0 NexPlayer/3.0 profile/MIDP-2.1 configuration/CLDC-1.1 OPN-B".should be_browser("Dolfin").version("2.2").webkit_version("533.1").build("533.1").platform("Samsung").os("Bada 1.2").language("fr-FR").security(:strong).mobile(true) }
    end

    describe "Shiira" do
      it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; ja-jp) AppleWebKit/419 (KHTML, like Gecko) Shiira/1.2.3 Safari/125".should be_browser("Shiira").version("1.2.3").webkit_version("419").build("419").platform("Macintosh").os("PPC Mac OS X").language("ja-JP").security(:strong) }
    end

    describe "Vienna" do
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_4; en-us) AppleWebKit/533.17.8 (KHTML, like Gecko) Vienna/2.5.0.2501".should be_browser("Vienna").version("2.5.0.2501").webkit_version("533.17.8").build("533.17.8").platform("Macintosh").os("Intel Mac OS X 10.6.4").language("en-US").security(:strong) }
    end

    describe "webOS" do
      it { "Mozilla/5.0 (webOS/1.4.0; U; en-US) AppleWebKit/532.2 (KHTML, like Gecko) Version/1.0 Safari/532.2 Pre/1.1".should be_browser("webOS").version("1.0").webkit_version("532.2").build("532.2").platform("webOS").os("Palm Pre 1.1").language("en-US").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (webOS/1.4.0; U; en-US) AppleWebKit/532.2 (KHTML, like Gecko) Version/1.0 Safari/532.2 Pixi/1.1".should be_browser("webOS").version("1.0").webkit_version("532.2").build("532.2").platform("webOS").os("Palm Pixi 1.1").language("en-US").security(:strong).mobile(true) }
    end

    describe "Symbian" do
      it { "Mozilla/5.0 (SymbianOS/9.3; U; Series60/3.2 Nokia6790s-1c/20.007; Profile/MIDP-2.1 Configuration/CLDC-1.1 ) AppleWebKit/413 (KHTML, like Gecko) Safari/413".should be_browser("Symbian").webkit_version("413").build("413").platform("Nokia").os("SymbianOS 9.3").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (SymbianOS/9.4; Series60/5.0 NokiaN97-1/20.0.027; Profile/MIDP-2.1 Configuration/CLDC-1.1) AppleWebKit/525 (KHTML, like Gecko) BrowserNG/7.1.18124".should be_browser("Symbian").webkit_version("525").build("525").platform("Nokia").os("SymbianOS 9.4").security(:strong).mobile(true) }
      it { "Mozilla/5.0 (SymbianOS/9.3; U; Series60/3.2 Samsung/I8510/DJHJ4; Profile/MIDP-2.1 Configuration/CLDC-1.1 ) AppleWebKit/413 (KHTML, like Gecko) Safari/413".should be_browser("Symbian").webkit_version("413").build("413").platform("Samsung").os("SymbianOS 9.3").security(:strong).mobile(true) }
    end

    describe "Destkop Safari" do
      describe "Windows" do
        it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; en) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.18".should be_browser("Safari").version("3.1.1").webkit_version("525.18").build("525.18").platform("Windows").os("Windows XP").language("en").security(:strong) }
        it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; en) AppleWebKit/526.9 (KHTML, like Gecko) Version/4.0dp1 Safari/526.8".should be_browser("Safari").version("4.0dp1").webkit_version("526.9").build("526.9").platform("Windows").os("Windows XP").language("en").security(:strong) }
        it { "Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/534.27+ (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27".should be_browser("Safari").version("5.0.4").webkit_version("534.27+").build("534.27+").platform("Windows").os("Windows Vista").security(:strong) }
      end

      describe "Macintosh, version mapping up to 2.2" do
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; fr-fr) AppleWebKit/85.7 (KHTML, like Gecko) Safari/85.5".should be_browser("Safari").version("1.0").webkit_version("85.7").build("85.7").platform("Macintosh").os("PPC Mac OS X").language("fr-FR").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; fr-fr) AppleWebKit/85.8.2 (KHTML, like Gecko) Safari/85.5".should be_browser("Safari").version("1.0.3").webkit_version("85.8.2").build("85.8.2").platform("Macintosh").os("PPC Mac OS X").language("fr-FR").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; fr-fr) AppleWebKit/85.8.5 (KHTML, like Gecko) Safari/85.5".should be_browser("Safari").version("1.0.3").webkit_version("85.8.5").build("85.8.5").platform("Macintosh").os("PPC Mac OS X").language("fr-FR").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/124 (KHTML, like Gecko) Safari/125".should be_browser("Safari").version("1.2").webkit_version("124").build("124").platform("Macintosh").os("PPC Mac OS X").language("en-US").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/125.2 (KHTML, like Gecko) Safari/125.12".should be_browser("Safari").version("1.2.2").webkit_version("125.2").build("125.2").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/125.5.5 (KHTML, like Gecko) Safari/125.12".should be_browser("Safari").version("1.2.4").webkit_version("125.5.5").build("125.5.5").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/125.5.6 (KHTML, like Gecko) Safari/125.12".should be_browser("Safari").version("1.2.4").webkit_version("125.5.6").build("125.5.6").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/125.5.7 (KHTML, like Gecko) Safari/125.12".should be_browser("Safari").version("1.2.4").webkit_version("125.5.7").build("125.5.7").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; fr-ch) AppleWebKit/312.1 (KHTML, like Gecko) Safari/312".should be_browser("Safari").version("1.3").webkit_version("312.1").build("312.1").platform("Macintosh").os("PPC Mac OS X").language("fr-CH").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; fr-ch) AppleWebKit/312.1.1 (KHTML, like Gecko) Safari/312".should be_browser("Safari").version("1.3").webkit_version("312.1.1").build("312.1.1").platform("Macintosh").os("PPC Mac OS X").language("fr-CH").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/312.5 (KHTML, like Gecko) Safari/312.3".should be_browser("Safari").version("1.3.1").webkit_version("312.5").build("312.5").platform("Macintosh").os("PPC Mac OS X").language("en-US").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; fr) AppleWebKit/312.5.1 (KHTML, like Gecko) Safari/312.3.1".should be_browser("Safari").version("1.3.1").webkit_version("312.5.1").build("312.5.1").platform("Macintosh").os("PPC Mac OS X").language("fr").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; es-es) AppleWebKit/312.5.2 (KHTML, like Gecko) Safari/312.3.3".should be_browser("Safari").version("1.3.1").webkit_version("312.5.2").build("312.5.2").platform("Macintosh").os("PPC Mac OS X").language("es-ES").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/312.8 (KHTML, like Gecko) Safari/312.6".should be_browser("Safari").version("1.3.2").webkit_version("312.8").build("312.8").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/312.8.1 (KHTML, like Gecko) Safari/312.6".should be_browser("Safari").version("1.3.2").webkit_version("312.8.1").build("312.8.1").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/312.9 (KHTML, like Gecko) Safari/312.6".should be_browser("Safari").version("1.3.2").webkit_version("312.9").build("312.9").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/412 (KHTML, like Gecko) Safari/412.2".should be_browser("Safari").version("2.0").webkit_version("412").build("412").platform("Macintosh").os("PPC Mac OS X").language("en-US").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/412.6 (KHTML, like Gecko) Safari/412.2".should be_browser("Safari").version("2.0").webkit_version("412.6").build("412.6").platform("Macintosh").os("PPC Mac OS X").language("en-US").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/412.6.2 (KHTML, like Gecko) Safari/412.2.2".should be_browser("Safari").version("2.0").webkit_version("412.6.2").build("412.6.2").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/412.7 (KHTML, like Gecko) Safari/412.2.2".should be_browser("Safari").version("2.0.1").webkit_version("412.7").build("412.7").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/416.11 (KHTML, like Gecko) Safari/412.2.2".should be_browser("Safari").version("2.0.2").webkit_version("416.11").build("416.11").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/416.12 (KHTML, like Gecko) Safari/412.2.2".should be_browser("Safari").version("2.0.2").webkit_version("416.12").build("416.12").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/417.9 (KHTML, like Gecko) Safari/412.2.2".should be_browser("Safari").version("2.0.3").webkit_version("417.9").build("417.9").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/418 (KHTML, like Gecko) Safari/412.2.2".should be_browser("Safari").version("2.0.3").webkit_version("418").build("418").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/418.8 (KHTML, like Gecko) Safari/412.2.2".should be_browser("Safari").version("2.0.4").webkit_version("418.8").build("418.8").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/418.9 (KHTML, like Gecko) Safari/412.2.2".should be_browser("Safari").version("2.0.4").webkit_version("418.9").build("418.9").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/418.9.1 (KHTML, like Gecko) Safari/412.2.2".should be_browser("Safari").version("2.0.4").webkit_version("418.9.1").build("418.9.1").platform("Macintosh").os("PPC Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/419 (KHTML, like Gecko) Safari/419.3".should be_browser("Safari").version("2.0.4").webkit_version("419").build("419").platform("Macintosh").os("Intel Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en) AppleWebKit/425.13 (KHTML, like Gecko) Safari/419.3".should be_browser("Safari").version("2.2").webkit_version("425.13").build("425.13").platform("Macintosh").os("Intel Mac OS X").language("en").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_6; sv-se) AppleWebKit/533.19.4 (KHTML, like Gecko) WebClip/6530.10 Safari/6533.19.4".should be_browser("Safari").webkit_version("533.19.4").build("533.19.4").platform("Macintosh").os("Intel Mac OS X 10.6.6").language("sv-SE").security(:strong) }
      end

      describe "Macintosh, with proper version" do
        it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/525.18 (KHTML, like Gecko) Version/3.1.1 Safari/525.18".should be_browser("Safari").version("3.1.1").webkit_version("525.18").build("525.18").platform("Macintosh").os("Intel Mac OS X 10.5.3").language("en-US").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_3; en-us) AppleWebKit/526.9 (KHTML, like Gecko) Version/4.0dp1 Safari/526.8".should be_browser("Safari").version("4.0dp1").webkit_version("526.9").build("526.9").platform("Macintosh").os("Intel Mac OS X 10.5.3").language("en-US").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; en-us) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16".should be_browser("Safari").version("5.0").webkit_version("533.16").build("533.16").platform("Macintosh").os("Intel Mac OS X 10.6.3").language("en-US").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; en-us) AppleWebKit/533.19.4 (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4".should be_browser("Safari").version("5.0.3").webkit_version("533.19.4").build("533.19.4").platform("Macintosh").os("Intel Mac OS X 10.6.5").language("en-US").security(:strong) }
        it { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_7) AppleWebKit/534.27+ (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27".should be_browser("Safari").version("5.0.4").webkit_version("534.27+").build("534.27+").platform("Macintosh").os("Intel Mac OS X 10.6.7").security(:strong) }
      end

    end

    describe "iOS Safari" do
      describe "version mapping from Webkit version" do
        it { "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0_1 like Mac OS X; en-us) AppleWebKit/419.3 (KHTML, like Gecko) Mobile/8A306".should be_browser("Safari").version("3.0").webkit_version("419.3").build("419.3").platform("iPhone").os("iOS 4.0.1").language("en-US").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0_1 like Mac OS X; en-us) AppleWebKit/525.20 (KHTML, like Gecko) Mobile/8A306".should be_browser("Safari").version("3.1.1").webkit_version("525.20").build("525.20").platform("iPhone").os("iOS 4.0.1").language("en-US").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0_1 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Mobile/8A306".should be_browser("Safari").version("4.0").webkit_version("528.18").build("528.18").platform("iPhone").os("iOS 4.0.1").language("en-US").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/8A306".should be_browser("Safari").version("4.0.4").webkit_version("531.21.10").build("531.21.10").platform("iPhone").os("iOS 4.0.1").language("en-US").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0_1 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Mobile/8A306".should be_browser("Safari").version("4.0.5").webkit_version("532.9").build("532.9").platform("iPhone").os("iOS 4.0.1").language("en-US").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_0_1 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Mobile/8A306".should be_browser("Safari").version("5.0.2").webkit_version("533.17.9").build("533.17.9").platform("iPhone").os("iOS 4.0.1").language("en-US").security(:strong).mobile(true) }
      end

      describe "iPhone" do
        it { "Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A102 Safari/419".should be_browser("Safari").version("3.0").webkit_version("420.1").build("420.1").platform("iPhone").os("iOS").language("en").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_1_3 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7E18 Safari/528.16".should be_browser("Safari").version("4.0").webkit_version("528.18").build("528.18").platform("iPhone").os("iOS 3.1.3").language("en-US").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_1 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8B117 Safari/6531.22.7".should be_browser("Safari").version("4.0.5").webkit_version("532.9").build("532.9").platform("iPhone").os("iOS 4.1").language("en-US").security(:strong).mobile(true) }
      end

      describe "iPhone Simulator" do
        it { "Mozilla/5.0 (iPhone Simulator; U; CPU iPhone OS 4_0_1 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8A306 Safari/6531.22.7".should be_browser("Safari").version("4.0.5").webkit_version("532.9").build("532.9").platform("iPhone Simulator").os("iOS 4.0.1").language("en-US").security(:strong).mobile(true) }
      end

      describe "iPod" do
        it { "Mozilla/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A102 Safari/419".should be_browser("Safari").version("3.0").webkit_version("420.1").build("420.1").platform("iPod").os("iOS").language("en").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPod; U; CPU iPhone OS 3_1_3 like Mac OS X; en-us) AppleWebKit/528.18 (KHTML, like Gecko) Version/4.0 Mobile/7E18 Safari/528.16".should be_browser("Safari").version("4.0").webkit_version("528.18").build("528.18").platform("iPod").os("iOS 3.1.3").language("en-US").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPod; U; CPU iPhone OS 4_1 like Mac OS X; en-us) AppleWebKit/532.9 (KHTML, like Gecko) Version/4.0.5 Mobile/8B117 Safari/6531.22.7".should be_browser("Safari").version("4.0.5").webkit_version("532.9").build("532.9").platform("iPod").os("iOS 4.1").language("en-US").security(:strong).mobile(true) }
      end

      describe "iPad" do
        it { "Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B367 Safari/531.21.10".should be_browser("Safari").version("4.0.4").webkit_version("531.21.10").build("531.21.10").platform("iPad").os("iOS 3.2").language("en-US").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPad; U; CPU iPhone OS 4_2_1 like Mac OS X; en_US) AppleWebKit (KHTML, like Gecko) Mobile [FBAN/FBForIPhone;FBAV/4.0;FBBV/4000.0;FBDV/iPad1,1;FBMD/iPad;FBSN/iPhone OS;FBSV/4.2.1;FBSS/1; FBCR/Maxis;FBID/tablet;FBLC/en_US;FBSF/1.0]".should be_browser("Safari").platform("iPad").os("iOS 4.2.1").language("en-US").security(:strong).mobile(true) }
        it { "Mozilla/5.0 (iPad; U; CPU iPhone OS 5_0 like Mac OS X; en_US) AppleWebKit (KHTML, like Gecko) Mobile [FBAN/FBForIPhone;FBAV/4.1;FBBV/4100.0;FBDV/iPad2,2;FBMD/iPad;FBSN/iPhone OS;FBSV/5.0;FBSS/1; FBCR/".should be_browser("Safari").platform("iPad").os("iOS 5.0").language("en-US").security(:strong).mobile(true) }
      end
    end

    describe "Nokia Safari" do
      it { "Nokia7230/5.0 (10.82) Profile/MIDP-2.1 Configuration/CLDC-1.1 Mozilla/5.0 AppleWebKit/420+ (KHTML, like Gecko) Safari/420+".should be_browser("Safari").webkit_version("420+").build("420+").platform("Nokia").security(:strong).mobile(true) }
    end

  end

end
