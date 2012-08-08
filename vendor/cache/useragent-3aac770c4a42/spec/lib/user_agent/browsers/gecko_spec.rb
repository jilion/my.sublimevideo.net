require 'spec_helper'

describe UserAgent::Browsers::Gecko do

  describe "comparisons" do
    before(:all) do
      @firefox_2 = UserAgent.parse("Mozilla/5.0 (X11; U; OpenBSD amd64; en-US; rv:1.8.1.6) Gecko/20070817 Firefox/2.0.0.6")
      @firefox_3 = UserAgent.parse("Mozilla/5.0 (X11; U; SunOS sun4u; en-US; rv:1.9b5) Gecko/2008032620 Firefox/3.0b5")
      @firefox_4 = UserAgent.parse("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0b8) Gecko/20100101 Firefox/4.0b8")
    end

    specify { @firefox_3.should_not == @firefox_2 }
    specify { @firefox_3.should_not <  @firefox_2 }
    specify { @firefox_3.should_not <= @firefox_2 }
    specify { @firefox_3.should     >  @firefox_2 }
    specify { @firefox_3.should     >= @firefox_2 }

    specify { @firefox_3.should     == @firefox_3 }
    specify { @firefox_3.should_not <  @firefox_3 }
    specify { @firefox_3.should     <= @firefox_3 }
    specify { @firefox_3.should_not >  @firefox_3 }
    specify { @firefox_3.should     >= @firefox_3 }

    specify { @firefox_3.should_not == @firefox_4 }
    specify { @firefox_3.should     <  @firefox_4 }
    specify { @firefox_3.should     <= @firefox_4 }
    specify { @firefox_3.should_not >  @firefox_4 }
    specify { @firefox_3.should_not >= @firefox_4 }
  end

  describe "Unknown browser" do
    it { "Mozilla/5.0 (Windows; U; WinNT; en; rv:1.0.2) Gecko/20030311 FooBar/0.5".should be_browser("Mozilla").version("1.0.2").gecko_version("20030311").platform("Windows").os("Windows NT").language("en").security(:strong) }
  end

  describe "no comment" do
    it { "Mozilla/5.0 Gecko/20030311 FooBar/0.5".should be_browser("Mozilla").version("5.0").gecko_version("20030311").security(:strong) }
  end

  describe "Beonex" do
    it { "Mozilla/5.0 (Windows; U; WinNT; en; rv:1.0.2) Gecko/20030311 Beonex/0.8.2-stable".should be_browser("Beonex").version("0.8.2-stable").gecko_version("20030311").platform("Windows").os("Windows NT").language("en").security(:strong) }
  end

  describe "BonEcho" do
    it { "Mozilla/5.0 (X11; U; Linux i686; nl; rv:1.8.1b2) Gecko/20060821 BonEcho/2.0b2 (Debian-1.99+2.0b2+dfsg-1)".should be_browser("BonEcho").version("2.0b2").platform("Linux").os("Linux i686").gecko_version("20060821").linux_distribution("Debian 1.99+2.0b2+dfsg-1").language("nl").security(:strong) }
  end

  describe "Camino" do
    describe "Macintosh" do
      it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.0.1) Gecko/20030306 Camino/0.7".should be_browser("Camino").version("0.7").gecko_version("20030306").platform("Macintosh").os("PPC Mac OS X Mach-O").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en; rv:1.8.1.14) Gecko/20080409 Camino/1.6 (like Firefox/2.0.0.14)".should be_browser("Camino").version("1.6").gecko_version("20080409").platform("Macintosh").os("Intel Mac OS X").language("en").security(:strong) }
    end
  end

  describe "Fennec" do
    it { "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:2.0b8) Gecko/20101221 Firefox/4.0b8 Fennec/4.0b3".should be_browser("Fennec").version("4.0b3").platform("Windows").os("Windows 7").gecko_version("20101221").security(:strong) }
  end

  describe "Firebird" do
    it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.6b) Gecko/20031212 Firebird/0.7+".should be_browser("Firebird").version("0.7+").gecko_version("20031212").platform("Windows").os("Windows XP").language("en-US").security(:strong) }
  end

  describe "Flock" do
    it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.19) Gecko/2010061201 Firefox/3.0.19 Flock/2.6.0".should be_browser("Flock").version("2.6.0").gecko_version("2010061201").platform("Windows").os("Windows XP").language("en-US").security(:strong) }
    it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.4) Gecko/20060612 Firefox/1.5.0.4 Flock/0.7.0.17.1".should be_browser("Flock").version("0.7.0.17.1").gecko_version("20060612").platform("Linux").os("Linux i686").language("en-US").security(:strong) }
  end

  describe "Galeon" do
    it { "Mozilla/5.0 Galeon/1.0.3 (X11; Linux i686; U;) Gecko/0".should be_browser("Galeon").version("1.0.3").platform("Linux").os("Linux i686").security(:strong) }
    it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.8) Gecko/20090327 Galeon/2.0.7".should be_browser("Galeon").version("2.0.7").gecko_version("20090327").platform("Linux").os("Linux i686").language("en-US").security(:strong) }
  end

  describe "Iceweasel" do
    it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1) Gecko/20061024 Iceweasel/2.0 (Debian-2.0+dfsg-1)".should be_browser("Iceweasel").version("2.0").gecko_version("20061024").platform("Linux").os("Linux i686").linux_distribution("Debian 2.0+dfsg-1").language("en-US").security(:strong) }
  end

  describe "Minefield" do
    it { "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:2.0b4pre) Gecko/20100815 Minefield/4.0b4pre".should be_browser("Minefield").version("4.0b4pre").gecko_version("20100815").platform("Windows").os("Windows 7").security(:strong) }
  end

  describe "Netscape" do
    it { "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.8.1.8pre) Gecko/20070928 Firefox/2.0.0.7 Navigator/9.0RC1".should be_browser("Netscape").version("9.0RC1").gecko_version("20070928").platform("Windows").os("Windows Vista").language("en-US").security(:strong) }
  end

  describe "Phoenix" do
    it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.3a) Gecko/20021207 Phoenix/0.5".should be_browser("Phoenix").version("0.5").gecko_version("20021207").platform("Linux").os("Linux i686").language("en-US").security(:strong) }
  end

  describe "SeaMonkey" do
    describe "Macintosh" do
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.1.4) Gecko/20091017 SeaMonkey/2.0".should be_browser("Seamonkey").version("2.0").gecko_version("20091017").platform("Macintosh").os("Intel Mac OS X 10.6").language("en-US").security(:strong) }
    end
  end

  describe "Sunrise" do
    it { "Mozilla/6.0 (X11; U; Linux x86_64; en-US; rv:2.9.0.3) Gecko/2009022510 FreeBSD/ Sunrise/4.0.1/like Safari".should be_browser("Sunrise").version("4.0.1").gecko_version("2009022510").platform("FreeBSD").os("FreeBSD").language("en-US").security(:strong) }
  end

  describe "Thunderbird" do
    it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.2.13) Gecko/20101208 Lightning/1.0b2 Thunderbird/3.1.7".should be_browser("Thunderbird").version("3.1.7").gecko_version("20101208").platform("Linux").os("Linux i686").language("en-US").security(:strong) }
  end

  describe "Firefox" do
    describe "Windows" do
      it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.12) Gecko/20070508 Firefox/1.5.0.12".should be_browser("Firefox").version("1.5.0.12").gecko_version("20070508").platform("Windows").os("Windows XP").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; pl; rv:1.8.1.1) Gecko/20061204 Mozilla/5.0 (X11; U; Linux i686; fr; rv:1.8.1) Gecko/20060918 Firefox/2.0b2".should be_browser("Firefox").version("2.0b2").gecko_version("20061204").platform("Windows").os("Windows XP").language("pl").security(:strong) }
      it { "Mozilla/5.0 (Windows; Windows NT 5.1; en-US; rv:1.8.1.9) Gecko/20071025 Firefox/2.0.0.9".should be_browser("Firefox").version("2.0.0.9").gecko_version("20071025").platform("Windows").os("Windows XP").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (compatible; N; Windows NT 5.1; en;) Gecko/20080325 Firefox/2.0.0.13".should be_browser("Firefox").version("2.0.0.13").gecko_version("20080325").platform("Windows").os("Windows XP").language("en").security(:none) }
      it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14".should be_browser("Firefox").version("2.0.0.14").gecko_version("20080404").platform("Windows").os("Windows XP").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (U; Windows NT 5.1; en-GB) Gecko Firefox/2.0.0.17".should be_browser("Firefox").version("2.0.0.17").platform("Windows").os("Windows XP").language("en-GB").security(:strong) }
      it { "Mozilla/5.0 (U; Windows NT 5.1; en-GB; rv:1.8.1.17) Gecko/20080808 Firefox/2.0.0.17".should be_browser("Firefox").version("2.0.0.17").gecko_version("20080808").platform("Windows").os("Windows XP").language("en-GB").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Windows NT 5.0; en-US; rv:1.9b4) Gecko/2008030318 Firefox/3.0b4".should be_browser("Firefox").version("3.0b4").gecko_version("2008030318").platform("Windows").os("Windows 2000").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Windows; U; Windows NT 6.1; uk; rv:1.9.1.5) Gecko/20091102 Firefox/3.5.5".should be_browser("Firefox").version("3.5.5").gecko_version("20091102").platform("Windows").os("Windows 7").language("uk").security(:strong) }
      it { "Mozilla/5.0 (Windows; U; Windows NT 6.1; lt; rv:1.9.2) Gecko/20100115 Firefox/3.6".should be_browser("Firefox").version("3.6").gecko_version("20100115").platform("Windows").os("Windows 7").language("lt").security(:strong) }
      it { "Mozilla/5.0 (Windows NT 5.1; rv:2.0b9pre) Gecko/20110105 Firefox/4.0b9pre".should be_browser("Firefox").version("4.0b9pre").gecko_version("20110105").platform("Windows").os("Windows XP").security(:strong) }
      it { "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:2.0b9pre) Gecko/20101228 Firefox/4.0b9pre".should be_browser("Firefox").version("4.0b9pre").gecko_version("20101228").platform("Windows").os("Windows 7").security(:strong) }
      it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2.3) Gecko/20100401 Mozilla/5.0 (X11; U; Linux i686; it-IT; rv:1.9.0.2) Gecko/2008092313 Ubuntu/9.25 (jaunty) Firefox/3.8".should be_browser("Firefox").version("3.8").gecko_version("20100401").platform("Windows").os("Windows XP").language("en-US").security(:strong) }
    end

    describe "Macintosh" do
      it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.12) Gecko/20070508 Firefox/1.5.0.12".should be_browser("Firefox").version("1.5.0.12").gecko_version("20070508").platform("Macintosh").os("PPC Mac OS X Mach-O").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14".should be_browser("Firefox").version("2.0.0.14").gecko_version("20080404").platform("Macintosh").os("Intel Mac OS X").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; de; rv:1.8.1.15) Gecko/20080623 Firefox/2.0.0.15".should be_browser("Firefox").version("2.0.0.15").gecko_version("20080623").platform("Macintosh").os("PPC Mac OS X Mach-O").language("de").security(:strong) }
      it { "Mozilla/6.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:2.0.0.0) Gecko/20061028 Firefox/3.0".should be_browser("Firefox").version("3.0").gecko_version("20061028").platform("Macintosh").os("PPC Mac OS X Mach-O").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2.13) Gecko/20101203 Firefox/3.6.13".should be_browser("Firefox").version("3.6.13").gecko_version("20101203").platform("Macintosh").os("Intel Mac OS X 10.6").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0b8) Gecko/20100101 Firefox/4.0b8".should be_browser("Firefox").version("4.0b8").gecko_version("20100101").platform("Macintosh").os("Intel Mac OS X 10.6").security(:strong) }
    end

    describe "SunOS" do
      it { "Mozilla/5.0 (X11; U; SunOS sun4u; en-US; rv:1.9b5) Gecko/2008032620 Firefox/3.0b5".should be_browser("Firefox").version("3.0b5").gecko_version("2008032620").platform("SunOS").os("SunOS sun4u").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; SunOS sun4u; it-IT; ) Gecko/20080000 Firefox/3.0".should be_browser("Firefox").version("3.0").gecko_version("20080000").platform("SunOS").os("SunOS sun4u").language("it-IT").security(:strong) }
    end

    describe "FreeBSD" do
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.9) Gecko/20071025 FreeBSD/i386 Firefox/2.0.0.9".should be_browser("Firefox").version("2.0.0.9").gecko_version("20071025").platform("FreeBSD").os("FreeBSD i386").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; FreeBSD i386; en-US; rv:1.8.1.14) Gecko/20080621 Firefox/2.0.0.14".should be_browser("Firefox").version("2.0.0.14").gecko_version("20080621").platform("FreeBSD").os("FreeBSD i386").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; FreeBSD i386; en-US; rv:1.9.1) Gecko/20090703 Firefox/3.5".should be_browser("Firefox").version("3.5").gecko_version("20090703").platform("FreeBSD").os("FreeBSD i386").language("en-US").security(:strong) }
    end

    describe "OpenBSD" do
      it { "Mozilla/5.0 (X11; U; OpenBSD amd64; en-US; rv:1.8.1.6) Gecko/20070817 Firefox/2.0.0.6".should be_browser("Firefox").version("2.0.0.6").gecko_version("20070817").platform("OpenBSD").os("OpenBSD amd64").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; OpenBSD i386; en-US; rv:1.8.1.7) Gecko/20070930 Firefox/2.0.0.7".should be_browser("Firefox").version("2.0.0.7").gecko_version("20070930").platform("OpenBSD").os("OpenBSD i386").language("en-US").security(:strong) }
    end

    describe "NetBSD" do
      it { "Mozilla/5.0 (X11; U; NetBSD alpha; en-US; rv:1.8.1.6) Gecko/20080115 Firefox/2.0.0.6".should be_browser("Firefox").version("2.0.0.6").gecko_version("20080115").platform("NetBSD").os("NetBSD alpha").language("en-US").security(:strong) }
    end

    describe "Linux" do
      it { "Mozilla/5.0 (X11; U; Linux i686; Ubuntu 7.04; de-CH; rv:1.8.1.5) Gecko/20070309 Firefox/2.0.0.5".should be_browser("Firefox").version("2.0.0.5").gecko_version("20070309").platform("Linux").os("Linux i686").linux_distribution("Ubuntu 7.04").language("de-CH").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux Gentoo; pl-PL; rv:1.8.1.7) Gecko/20070914 Firefox/2.0.0.7".should be_browser("Firefox").version("2.0.0.7").gecko_version("20070914").platform("Linux").os("Linux Gentoo").linux_distribution("Gentoo").language("pl-PL").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686 Gentoo; en-US; rv:1.8.1.13) Gecko/20080413 Firefox/2.0.0.13 (Gentoo Linux)".should be_browser("Firefox").version("2.0.0.13").gecko_version("20080413").platform("Linux").os("Linux i686 Gentoo").linux_distribution("Gentoo").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.17) Gecko/20080703 Mandriva/2.0.0.17-1.1mdv2008.1 (2008.1) Firefox/2.0.0.17".should be_browser("Firefox").version("2.0.0.17").gecko_version("20080703").platform("Linux").os("Linux i686").linux_distribution("Mandriva 2.0.0.17-1.1mdv2008.1").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9pre) Gecko/2008040318 Firefox/3.0pre (Swiftfox)".should be_browser("Firefox").version("3.0pre").gecko_version("2008040318").platform("Linux").os("Linux i686").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; tr-TR; rv:1.9b5) Gecko/2008032600 SUSE/2.9.95-25.1 Firefox/3.0b5".should be_browser("Firefox").version("3.0b5").gecko_version("2008032600").platform("Linux").os("Linux i686").linux_distribution("SUSE 2.9.95-25.1").language("tr-TR").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux x86_64; pt-BR; rv:1.9b5) Gecko/2008041515 Firefox/3.0b5".should be_browser("Firefox").version("3.0b5").gecko_version("2008041515").platform("Linux").os("Linux x86_64").language("pt-BR").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9b5) Gecko/2008041816 Fedora/3.0-0.55.beta5.fc9 Firefox/3.0b5".should be_browser("Firefox").version("3.0b5").gecko_version("2008041816").platform("Linux").os("Linux x86_64").linux_distribution("Fedora 3.0-0.55.beta5.fc9").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9) Gecko/2008062908 Firefox/3.0 (Debian-3.0~rc2-2)".should be_browser("Firefox").version("3.0").gecko_version("2008062908").platform("Linux").os("Linux x86_64").linux_distribution("Debian 3.0~rc2-2").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.1) Gecko/2008070206 Firefox/3.0.1".should be_browser("Firefox").version("3.0.1").gecko_version("2008070206").platform("Linux").os("Linux i686").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux x86_64) Gecko/2008072820 Firefox/3.0.1".should be_browser("Firefox").version("3.0.1").gecko_version("2008072820").platform("Linux").os("Linux x86_64").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.1) Gecko/2008081310 Gentoo Firefox/3.0.1".should be_browser("Firefox").version("3.0.1").gecko_version("2008081310").platform("Linux").os("Linux i686").linux_distribution("Gentoo").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.0.1) Gecko/2008072820 Kubuntu/8.04 (hardy) Firefox/3.0.1".should be_browser("Firefox").version("3.0.1").gecko_version("2008072820").platform("Linux").os("Linux x86_64").linux_distribution("Kubuntu 8.04").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.2) Gecko/2008092313 Ubuntu/8.04 (hardy) Firefox/3.1".should be_browser("Firefox").version("3.1").gecko_version("2008092313").platform("Linux").os("Linux i686").linux_distribution("Ubuntu 8.04").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; Linux x86_64; rv:2.0b9pre) Gecko/20110111 Firefox/4.0b9pre".should be_browser("Firefox").version("4.0b9pre").gecko_version("20110111").platform("Linux").os("Linux x86_64").security(:strong) }
    end

    describe "BeOS" do
      it { "Mozilla/5.0 (BeOS; U; BeOS BePC; en-US; rv:1.8.1b2) Gecko/20060901 Firefox/2.0b2".should be_browser("Firefox").version("2.0b2").gecko_version("20060901").platform("BeOS").os("BeOS BePC").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (BeOS; U; BeOS-BePC; en-US; rv:1.8.1b2) Gecko/20060901 Firefox/2.0b2".should be_browser("Firefox").version("2.0b2").gecko_version("20060901").platform("BeOS").os("BeOS BePC").language("en-US").security(:strong) }
    end

    describe "Nintendo DS" do
      it { "Mozilla/5.0 (Nintendo DS v4; U; M3 Adapter CF + PassMe2; en-US; rv:1.8.0.6 ) Gecko/20060728 Firefox/1.5.0.6 (firefox.gba.ds)".should be_browser("Firefox").version("1.5.0.6").gecko_version("20060728").platform("Nintendo DS").os("Nintendo DS v4").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Nintendo DSi; U; M3 Adapter CF + PassMe2; en-US; rv:1.8.0.6 ) Gecko/20060728 Firefox/1.5.0.6 (firefox.gba.ds)".should be_browser("Firefox").version("1.5.0.6").gecko_version("20060728").platform("Nintendo DS").os("Nintendo DS i").language("en-US").security(:strong) }
    end

    describe "Android" do
      it { "Mozilla/5.0 (Android; Mobile; rv:14.0) Gecko/14.0 Firefox/14.0".should be_browser("Firefox").version("14.0").gecko_version("14.0").platform("Android").os("Android").security(:strong).mobile(true) }
    end
  end

  describe "Mozilla" do
    describe "Windows" do
      it { "Mozilla/5.0 (Windows; U; Win 9x 4.90; de-AT; rv:1.7.2) Gecko/20040803".should be_browser("Mozilla").version("1.7.2").gecko_version("20040803").platform("Windows").os("Windows Me").language("de-AT").security(:strong) }
      it { "Mozilla/5.0 (Windows; ; Windows NT 5.1; rv:1.7.2) Gecko/20040804".should be_browser("Mozilla").version("1.7.2").gecko_version("20040804").platform("Windows").os("Windows XP").security(:strong) }
      it { "Mozilla/5.0 (Windows NT 5.1; U; pt-br; rv:1.7.5) Gecko/20041110".should be_browser("Mozilla").version("1.7.5").gecko_version("20041110").platform("Windows").os("Windows XP").language("pt-br").security(:strong) }
      it { "Mozilla/5.0 (Windows; U; WinNT4.0; en-US; rv:1.7.12) Gecko/20050915".should be_browser("Mozilla").version("1.7.12").gecko_version("20050915").platform("Windows").os("Windows NT 4.0").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.7.13) Gecko/20060414".should be_browser("Mozilla").version("1.7.13").gecko_version("20060414").platform("Windows").os("Windows Vista").language("en-US").security(:strong) }
      it { "Mozilla/4.0 (compatible; Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.13) Gecko/20060414; Windows NT 5.1)".should be_browser("Mozilla").version("1.7.13").gecko_version("20060414").platform("Windows").os("Windows XP").security(:strong) }
      it { "Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.8b2) Gecko/20050702".should be_browser("Mozilla").version("1.8b2").gecko_version("20050702").platform("Windows").os("Windows 2000").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Windows; U; Win98; en-US; rv:1.8a6) Gecko/20050111".should be_browser("Mozilla").version("1.8a6").gecko_version("20050111").platform("Windows").os("Windows 98").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (compatible; Windows; U; Windows NT 5.1; en-US; rv:1.8.1.2) Gecko/20070219".should be_browser("Mozilla").version("1.8.1.2").gecko_version("20070219").platform("Windows").os("Windows XP").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.3) Gecko/20070309 Mozilla/4.8 [en] (Windows NT 5.1; U)".should be_browser("Mozilla").version("1.8.1.3").gecko_version("20070309").platform("Windows").os("Windows XP").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Windows; U; Windows NT 5.1; cs; rv:1.9) Gecko/2008052906".should be_browser("Mozilla").version("1.9").gecko_version("2008052906").platform("Windows").os("Windows XP").language("cs").security(:strong) }
    end

    describe "Macintosh" do
      it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en; rv:1.8b) Gecko/20050217".should be_browser("Mozilla").version("1.8b").gecko_version("20050217").platform("Macintosh").os("PPC Mac OS X Mach-O").language("en").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.1.1) Gecko/20061204".should be_browser("Mozilla").version("1.8.1.1").gecko_version("20061204").platform("Macintosh").os("PPC Mac OS X Mach-O").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en; rv:1.8.1.2pre) Gecko/20070223".should be_browser("Mozilla").version("1.8.1.2pre").gecko_version("20070223").platform("Macintosh").os("Intel Mac OS X").language("en").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.11) Gecko/20071127".should be_browser("Mozilla").version("1.8.1.11").gecko_version("20071127").platform("Macintosh").os("Intel Mac OS X").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en; rv:1.9.0.1) Gecko/2008070206".should be_browser("Mozilla").version("1.9.0.1").gecko_version("2008070206").platform("Macintosh").os("Intel Mac OS X 10.5").language("en").security(:strong) }
      it { "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.1) Gecko/2008070206".should be_browser("Mozilla").version("1.9.0.1").gecko_version("2008070206").platform("Macintosh").os("Intel Mac OS X 10.5").language("en-US").security(:strong) }
    end

    describe "SunOS" do
      it { "Mozilla/5.0 (X11; U; SunOS sun4u; en-US; rv:1.7.7) Gecko/20050421".should be_browser("Mozilla").version("1.7.7").gecko_version("20050421").platform("SunOS").os("SunOS sun4u").language("en-US").security(:strong) }
    end

    describe "Linux" do
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.6) Gecko/20050328 Fedora/1.7.6-1.2.5".should be_browser("Mozilla").version("1.7.6").gecko_version("20050328").platform("Linux").os("Linux i686").linux_distribution("Fedora 1.7.6-1.2.5").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; rv:1.7.8) Gecko/20061113 Debian/1.7.8-1sarge8".should be_browser("Mozilla").version("1.7.8").gecko_version("20061113").platform("Linux").os("Linux i686").linux_distribution("Debian 1.7.8-1sarge8").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.8) Gecko/20050512 Red Hat/1.7.8-1.1.3.1".should be_browser("Mozilla").version("1.7.8").gecko_version("20050512").platform("Linux").os("Linux i686").linux_distribution("Red Hat 1.7.8-1.1.3.1").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux x86_64; de-AT; rv:1.7.8) Gecko/20050513 Debian/1.7.8-1".should be_browser("Mozilla").version("1.7.8").gecko_version("20050513").platform("Linux").os("Linux x86_64").linux_distribution("Debian 1.7.8-1").language("de-AT").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686 (x86_64); fr; rv:1.7.12) Gecko/20051010 Debian/1.7.12-0ubuntu2".should be_browser("Mozilla").version("1.7.12").gecko_version("20051010").platform("Linux").os("Linux i686 (x86_64)").linux_distribution("Debian 1.7.12-0ubuntu2").language("fr").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686 (x86_64); en-US; rv:1.7.13) Gecko/20060417".should be_browser("Mozilla").version("1.7.13").gecko_version("20060417").platform("Linux").os("Linux i686 (x86_64)").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.13) Gecko/20060717 Debian/1.7.13-0ubuntu05.04".should be_browser("Mozilla").version("1.7.13").gecko_version("20060717").platform("Linux").os("Linux i686").linux_distribution("Debian 1.7.13-0ubuntu05.04").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.4) Gecko/20060912 pango-text".should be_browser("Mozilla").version("1.8.0.4").gecko_version("20060912").platform("Linux").os("Linux i686").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.1) Gecko/20061205 Mozilla/5.0 (Debian-2.0.0.1+dfsg-2)".should be_browser("Mozilla").version("1.8.1.1").gecko_version("20061205").platform("Linux").os("Linux i686").linux_distribution("Debian 2.0.0.1+dfsg-2").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; ; Linux i686; en-US; rv:1.8.1.3) Gecko".should be_browser("Mozilla").version("1.8.1.3").platform("Linux").os("Linux i686").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.3) Gecko/20061201 MEGAUPLOAD 1.0 (Ubuntu-feisty)".should be_browser("Mozilla").version("1.8.1.3").gecko_version("20061201").platform("Linux").os("Linux i686").linux_distribution("Ubuntu feisty").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.4) Gecko/20061201 Mozilla/5.0 (Linux Mint)".should be_browser("Mozilla").version("1.8.1.4").gecko_version("20061201").platform("Linux").os("Linux i686").language("en-US").security(:strong) }
      it { "Mozilla/5.001 (X11; U; Linux i686; rv:1.8.1.6; de-ch) Gecko/25250101 (ubuntu-feisty)".should be_browser("Mozilla").version("1.8.1.6").gecko_version("25250101").platform("Linux").os("Linux i686").linux_distribution("Ubuntu feisty").language("de-ch").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; de-AT; rv:1.8.1.15) Gecko/20080620 Mozilla/4.0".should be_browser("Mozilla").version("1.8.1.15").gecko_version("20080620").platform("Linux").os("Linux i686").language("de-AT").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9a3pre) Gecko/20070330".should be_browser("Mozilla").version("1.9a3pre").gecko_version("20070330").platform("Linux").os("Linux i686").language("en-US").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux i686; en; rv:1.9) Gecko".should be_browser("Mozilla").version("1.9").platform("Linux").os("Linux i686").language("en").security(:strong) }
      it { "Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9.0.1) Gecko".should be_browser("Mozilla").version("1.9.0.1").platform("Linux").os("Linux x86_64").language("en-US").security(:strong) }
      # We loose the processor type here :( because of the "(Linux Mint)" comment
      it { "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.1) Gecko/2008072820 Ubuntu/8.04 (hardy) (Linux Mint)".should be_browser("Mozilla").version("1.9.0.1").gecko_version("2008072820").platform("Linux").os("Linux i686").linux_distribution("Ubuntu 8.04").language("en-US").security(:strong) }
    end

    describe "FreeBSD" do
      it { "Mozilla/5.0 (X11; U; FreeBSD i386; en-US; rv:1.7b) Gecko/20040429".should be_browser("Mozilla").version("1.7b").gecko_version("20040429").platform("FreeBSD").os("FreeBSD i386").language("en-US").security(:strong) }
    end

    describe "OpenBSD" do
      it { "Mozilla/5.0 (X11; U; OpenBSD i386; en-US; rv:1.7.13) Gecko/20060901".should be_browser("Mozilla").version("1.7.13").gecko_version("20060901").platform("OpenBSD").os("OpenBSD i386").language("en-US").security(:strong) }
    end

    describe "OS/2" do
      it { "Mozilla/5.0 (OS/2; U; Warp 4.5; de-DE; rv:1.7.5) Gecko/20050523".should be_browser("Mozilla").version("1.7.5").gecko_version("20050523").platform("OS/2").os("OS/2").language("de-DE").security(:strong) }
    end

    describe "AIX" do
      it { "Mozilla/5.0 (X11; U; AIX 5.3; en-US; rv:1.7.12) Gecko/20051025".should be_browser("Mozilla").version("1.7.12").gecko_version("20051025").platform("AIX").os("AIX 5.3").language("en-US").security(:strong) }
    end

  end

end
