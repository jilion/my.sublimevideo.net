require 'spec_helper'

describe UserAgent::Browsers::All do
  describe "comparisons" do
    before(:all) do
      @ie_7    = UserAgent.parse("Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)")
      @ie_6    = UserAgent.parse("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)")
      @firefox = UserAgent.parse("Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14")
      @fake_chrome_2 = UserAgent.parse("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/2.0.912.63 Safari/535.7")
      @chrome  = UserAgent.parse("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_2) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.63 Safari/535.7")
    end

    describe "#<" do
      specify { @ie_7.should_not < "Mozilla" }
      specify { @ie_7.should_not < @firefox }
      specify { @ie_6.should     < @ie_7 }
      specify { @ie_6.should_not < @ie_6 }
      specify { @ie_7.should_not < @ie_6 }
      specify { @fake_chrome_2.should < @chrome}
    end

    describe "#<=" do
      specify { @ie_7.should_not <= "Mozilla" }
      specify { @ie_7.should_not <= @firefox }
      specify { @ie_6.should     <= @ie_7 }
      specify { @ie_6.should     <= @ie_6 }
      specify { @ie_7.should_not <= @ie_6 }
    end

    describe "#==" do
      specify { @ie_7.should_not == "Mozilla" }
      specify { @ie_7.should_not == @firefox }
      specify { @ie_6.should_not == @ie_7 }
      specify { @ie_6.should     == @ie_6 }
      specify { @ie_7.should_not == @ie_6 }
    end

    describe "#>" do
      specify { @ie_7.should_not > "Mozilla" }
      specify { @ie_7.should_not > @firefox }
      specify { @ie_6.should_not > @ie_7 }
      specify { @ie_6.should_not > @ie_6 }
      specify { @ie_7.should     > @ie_6 }
    end

    describe "#>=" do
      specify { @ie_7.should_not >= "Mozilla" }
      specify { @ie_7.should_not >= @firefox }
      specify { @ie_6.should_not >= @ie_7 }
      specify { @ie_6.should     >= @ie_6 }
      specify { @ie_7.should     >= @ie_6 }
    end
  end
  
  describe "#browser" do
    specify { UserAgent.parse(nil).browser.should be_nil }
    specify { UserAgent.parse("").browser.should be_nil }
  end
  
  describe "#version" do
    specify { UserAgent.parse(nil).version.should be_nil }
    specify { UserAgent.parse("").version.should be_nil }
  end

  describe "#platform" do
    before(:all) do
      @nil               = UserAgent.parse(nil)
      @empty             = UserAgent.parse("")
      @nintendo_wii      = UserAgent.parse("Opera/9.23 (Nintendo Wii; U; ; 1038-58; Wii Internet Channel/1.0; en)")
      @nintendo_ds       = UserAgent.parse("Opera/9.23 (Nintendo DS v4; U; ; 1038-58; en)")
      @web_tv            = UserAgent.parse("WebTV 1.2 Mozilla/3.0 WebTV/1.2 (compatible; MSIE 2.0)")
      @windows           = UserAgent.parse("Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.14) Gecko/20080404 Firefox/2.0.0.14")
      @i_pad             = UserAgent.parse("Mozilla/5.0 (iPad; U; CPU OS 3_2 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Version/4.0.4 Mobile/7B367 Safari/531.21.10")
      @i_pod             = UserAgent.parse("Mozilla/5.0 (iPod; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A102 Safari/419")
      @i_phone_simulator = UserAgent.parse("Mozilla/5.0 (iPhone Simulator; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A102 Safari/419")
      @i_phone           = UserAgent.parse("Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420.1 (KHTML, like Gecko) Version/3.0 Mobile/4A102 Safari/419")
      @sun_os            = UserAgent.parse("Mozilla/5.0 (X11; U; SunOS sun4u; en-US; rv:1.7.7) Gecko/20050421")
      @web_os            = UserAgent.parse("Mozilla/5.0 (X11; U; webOS sun4u; en-US; rv:1.7.7) Gecko/20050421")
      @macinstosh1       = UserAgent.parse("Opera/9.23 (Macintosh; Intel Mac OS X; U; ja)")
      @macinstosh2       = UserAgent.parse("Opera/9.23 (Mac OS X; ru)")
      @android           = UserAgent.parse("Mozilla/5.0 (Linux; U; Android 1.5; de-; HTC Magic Build/PLAT-RC33) AppleWebKit/528.5+ (KHTML, like Gecko) Version/3.1.2 Mobile Safari/525.20.1")
      @free_bsd          = UserAgent.parse("Mozilla/5.0 (X11; U; FreeBSD i386; en-US; rv:1.7b) Gecko/20040429")
      @open_bsd          = UserAgent.parse("Mozilla/5.0 (X11; U; OpenBSD i386; en-US; rv:1.7.13) Gecko/20060901")
      @net_bsd           = UserAgent.parse("Mozilla/5.0 (X11; U; NetBSD alpha; en-US; rv:1.8.1.6) Gecko/20080115 Firefox/2.0.0.6")
      @linux             = UserAgent.parse("Mozilla/5.0 (X11; U; Linux x86_64; de-AT; rv:1.7.8) Gecko/20050513 Debian/1.7.8-1")
      @nokia             = UserAgent.parse("Mozilla/5.0 (SymbianOS/9.4; Series60/5.0 NokiaN97-1/12.0.024; Profile/MIDP-2.1 Configuration/CLDC-1.1; en-us) AppleWebKit/525 (KHTML, like Gecko) BrowserNG/7.1.12344")
      @black_berry       = UserAgent.parse("Mozilla/5.0 (BlackBerry; U; BlackBerry 9800; en) AppleWebKit/534.1+ (KHTML, Like Gecko) Version/6.0.0.141 Mobile Safari/534.1+")
      @opensolaris       = UserAgent.parse("Mozilla/5.0 (X11; U; OpenSolaris; en-US; rv:1.8.1.6) Gecko/20080115 Firefox/2.0.0.6")
      @os_2              = UserAgent.parse("Mozilla/5.0 (OS/2; U; Warp 4.5; de-DE; rv:1.7.5) Gecko/20050523")
      @be_os             = UserAgent.parse("Mozilla/5.0 (BeOS; U; BeOS BePC; en-US; rv:1.8.1b2) Gecko/20060901 Firefox/2.0b2")
      @aix               = UserAgent.parse("Mozilla/5.0 (X11; U; AIX 5.3; en-US; rv:1.7.12) Gecko/20051025")
      @x11               = UserAgent.parse("Mozilla/5.0 (X11; U; en-US; rv:1.7.12) Gecko/20051025")
    end

    specify { @nil.platform.should               be_nil }
    specify { @empty.platform.should             be_nil }
    specify { @nintendo_wii.platform.should      == "Nintendo Wii" }
    specify { @nintendo_ds.platform.should       == "Nintendo DS" }
    specify { @web_tv.platform.should            == "WebTV" }
    specify { @windows.platform.should           == "Windows" }
    specify { @i_pad.platform.should             == "iPad" }
    specify { @i_pod.platform.should             == "iPod" }
    specify { @i_phone_simulator.platform.should == "iPhone Simulator" }
    specify { @i_phone.platform.should           == "iPhone" }
    specify { @sun_os.platform.should            == "SunOS" }
    specify { @web_os.platform.should            == "webOS" }
    specify { @macinstosh1.platform.should       == "Macintosh" }
    specify { @macinstosh2.platform.should       == "Macintosh" }
    specify { @android.platform.should           == "Android" }
    specify { @free_bsd.platform.should          == "FreeBSD" }
    specify { @open_bsd.platform.should          == "OpenBSD" }
    specify { @net_bsd.platform.should           == "NetBSD" }
    specify { @linux.platform.should             == "Linux" }
    specify { @nokia.platform.should             == "Nokia" }
    specify { @black_berry.platform.should       == "BlackBerry" }
    specify { @opensolaris.platform.should       == "OpenSolaris" }
    specify { @os_2.platform.should              == "OS/2" }
    specify { @be_os.platform.should             == "BeOS" }
    specify { @aix.platform.should               == "AIX" }
    specify { @x11.platform.should               == "X11" }
  end

  describe "#os" do
    before(:all) do
      @nil                 = UserAgent.parse(nil)
      @empty               = UserAgent.parse("")
      @windows_7           = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 6.1; en-US; rv:1.8.1.14)")
      @windows_vista_1     = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 6; en-US; rv:1.8.1.14)")
      @windows_vista_2     = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.8.1.14)")
      @windows_nt_1        = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.3; en-US; rv:1.8.1.14)")
      @windows_nt_2        = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.4; en-US; rv:1.8.1.14)")
      @windows_nt_3        = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.5; en-US; rv:1.8.1.14)")
      @windows_nt_4        = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.6; en-US; rv:1.8.1.14)")
      @windows_nt_5        = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.7; en-US; rv:1.8.1.14)")
      @windows_nt_6        = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.8; en-US; rv:1.8.1.14)")
      @windows_nt_7        = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.9; en-US; rv:1.8.1.14)")
      @windows_server_2003 = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.2; en-US; rv:1.8.1.14)")
      @windows_xp          = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.14)")
      @windows_2000_sp1    = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.01; en-US; rv:1.8.1.14)")
      @windows_2000_1      = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5; en-US; rv:1.8.1.14)")
      @windows_2000_2      = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.8.1.14)")
      @windows_nt_40_1     = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 4; en-US; rv:1.8.1.14)")
      @windows_nt_40_2     = UserAgent.parse("Fake/5.0 (Windows; U; Windows NT 4.0; en-US; rv:1.8.1.14)")
      @win_nt_40_1         = UserAgent.parse("Fake/5.0 (Windows; U; Win NT 4; en-US; rv:1.8.1.14)")
      @win_nt_40_2         = UserAgent.parse("Fake/5.0 (Windows; U; Win NT 4.0; en-US; rv:1.8.1.14)")
      @win_nt              = UserAgent.parse("Fake/5.0 (Windows; U; WinNT; en-US; rv:1.8.1.14)")
      @windows_me          = UserAgent.parse("Fake/5.0 (Windows; U; Win 9x 98; en-US; rv:1.8.1.14)")
      @windows_95          = UserAgent.parse("Fake/5.0 (Windows; U; Windows 95; en-US; rv:1.8.1.14)")
      @win_95              = UserAgent.parse("Fake/5.0 (Windows; U; Win 95; en-US; rv:1.8.1.14)")
      @windows_98          = UserAgent.parse("Fake/5.0 (Windows; U; Windows 98; en-US; rv:1.8.1.14)")
      @win_98              = UserAgent.parse("Fake/5.0 (Windows; U; Win 98; en-US; rv:1.8.1.14)")
      @windows_lambda      = UserAgent.parse("Fake/5.0 (Windows; U; Windows lambda; en-US; rv:1.8.1.14)")
      @free_bsd_1          = UserAgent.parse("Fake/5.0 (FreeBSD-1.2.3; en-US; rv:1.8.1.14)")
      @free_bsd_2          = UserAgent.parse("Fake/5.0 (FreeBSD/1.2.3; en-US; rv:1.8.1.14)")
      @free_bsd_3          = UserAgent.parse("Fake/5.0 (FreeBSD 1.2.3; en-US; rv:1.8.1.14)")
      @open_bsd_1          = UserAgent.parse("Fake/5.0 (OpenBSD-1.2.3; en-US; rv:1.8.1.14)")
      @open_bsd_2          = UserAgent.parse("Fake/5.0 (OpenBSD/1.2.3; en-US; rv:1.8.1.14)")
      @open_bsd_3          = UserAgent.parse("Fake/5.0 (OpenBSD 1.2.3; en-US; rv:1.8.1.14)")
      @net_bsd_1           = UserAgent.parse("Fake/5.0 (NetBSD-1.2.3; en-US; rv:1.8.1.14)")
      @net_bsd_2           = UserAgent.parse("Fake/5.0 (NetBSD/1.2.3; en-US; rv:1.8.1.14)")
      @net_bsd_3           = UserAgent.parse("Fake/5.0 (NetBSD 1.2.3; en-US; rv:1.8.1.14)")
      @sun_os_1            = UserAgent.parse("Fake/5.0 (SunOS-1.2.3; en-US; rv:1.8.1.14)")
      @sun_os_2            = UserAgent.parse("Fake/5.0 (SunOS/1.2.3; en-US; rv:1.8.1.14)")
      @sun_os_3            = UserAgent.parse("Fake/5.0 (SunOS 1.2.3; en-US; rv:1.8.1.14)")
      @be_os_1             = UserAgent.parse("Fake/5.0 (BeOS; U; BeOS-BePC; en-US; rv:1.8.1b2)")
      @be_os_2             = UserAgent.parse("Fake/5.0 (BeOS; U; BeOS/BePC; en-US; rv:1.8.1b2)")
      @be_os_3             = UserAgent.parse("Fake/5.0 (BeOS; U; BeOS BePC; en-US; rv:1.8.1b2)")
      @os2_1               = UserAgent.parse("Fake/5.0 (OS/2-1.2.3; en-US; rv:1.8.1.14)")
      @os2_2               = UserAgent.parse("Fake/5.0 (OS/2/1.2.3; en-US; rv:1.8.1.14)")
      @os2_3               = UserAgent.parse("Fake/5.0 (OS/2 1.2.3; en-US; rv:1.8.1.14)")
      @web_tv_1            = UserAgent.parse("Fake/3.0 WebTV/2.6 (compatible; MSIE 2.0)")
      @web_tv_2            = UserAgent.parse("WebTV 2.6 Mozilla/4.0 (compatible; MSIE 4.0; WebTV/2.6)")
      @amiga_os            = UserAgent.parse("AmigaVoyager/3.2 (AmigaOS/MC680x0)")
      @black_berry_os      = UserAgent.parse("Fake/5.0 (BlackBerry; U; BlackBerry 9800; en)")
      @symbian_os          = UserAgent.parse("Fake/5.0 (SymbianOS/9.3; U; en)")
      @nintendo_ds         = UserAgent.parse("Fake/5.0 (Nintendo DS v4; U; M3 Adapter CF + PassMe2; en-US; rv:1.8.0.6)")
      @nintendo_dsi        = UserAgent.parse("Fake/5.0 (Nintendo DSi; U; M3 Adapter CF + PassMe2; en-US; rv:1.8.0.6)")
    end

    specify { @nil.os.should be_nil }
    specify { @empty.os.should be_nil }
    specify { @windows_7.os.should == "Windows 7" }
    specify { [@windows_vista_1, @windows_vista_2].all? { |ua| ua.os.should == "Windows Vista" } }
    specify { @windows_server_2003.os.should == "Windows Server 2003" }
    specify { @windows_xp.os.should == "Windows XP" }
    specify { @windows_2000_sp1.os.should == "Windows 2000, Service Pack 1 (SP1)" }
    specify { [@windows_2000_1, @windows_2000_2].all? { |ua| ua.os.should == "Windows 2000" } }
    specify { [@windows_nt_40_1, @windows_nt_40_2, @win_nt_40_1, @win_nt_40_2].all? { |ua| ua.os.should == "Windows NT 4.0" } }
    specify { [@windows_nt_1, @windows_nt_2, @windows_nt_3, @windows_nt_4, @windows_nt_5, @windows_nt_6, @windows_nt_7, @win_nt].all? { |ua| ua.os.should == "Windows NT" } }
    specify { @windows_me.os.should == "Windows Me" }
    specify { [@windows_95, @win_95].all? { |ua| ua.os.should == "Windows 95" } }
    specify { [@windows_98, @win_98].all? { |ua| ua.os.should == "Windows 98" } }
    specify { @windows_lambda.os.should == "Windows" }
    specify { [@free_bsd_1, @free_bsd_2, @free_bsd_3].all? { |ua| ua.os.should == "FreeBSD 1.2.3" } }
    specify { [@open_bsd_1, @open_bsd_2, @open_bsd_3].all? { |ua| ua.os.should == "OpenBSD 1.2.3" } }
    specify { [@net_bsd_1, @net_bsd_2, @net_bsd_3].all? { |ua| ua.os.should == "NetBSD 1.2.3" } }
    specify { [@sun_os_1, @sun_os_2, @sun_os_3].all? { |ua| ua.os.should == "SunOS 1.2.3" } }
    specify { [@be_os_1, @be_os_2, @be_os_3].all? { |ua| ua.os.should == "BeOS" } } # version is returned only from the overidden #os method in the Gecko module
    specify { [@os2_1, @os2_2, @os2_3].all? { |ua| ua.os.should == "OS/2 1.2.3" } }
    specify { [@web_tv_1, @web_tv_2].all? { |ua| ua.os.should == "WebTV 2.6" } }
    specify { @amiga_os.os.should == "AmigaOS" }
    specify { @black_berry_os.os.should == "BlackBerryOS" }
    specify { @symbian_os.os.should == "SymbianOS 9.3" }
    specify { @nintendo_ds.os.should == "Nintendo DS v4" }
    specify { @nintendo_dsi.os.should == "Nintendo DS i" }
  end

  describe "#linux_distribution" do
    context "without a version" do
      before(:all) do
        @nil      = UserAgent.parse(nil)
        @empty    = UserAgent.parse("")
        @debian   = UserAgent.parse("Mozilla/5.0 (X11; U; Linux x86_64; de-AT; rv:1.7.8) Gecko/20050513 Debian")
        @kubuntu  = UserAgent.parse("Mozilla/5.001 (X11; U; Linux i686; rv:1.8.1.6; de-ch) Gecko/25250101 (kubuntu)")
        @ubuntu   = UserAgent.parse("Mozilla/5.001 (X11; U; Linux i686; rv:1.8.1.6; de-ch) Gecko/25250101 (ubuntu)")
        @fedora   = UserAgent.parse("Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9b5) Gecko/2008041816 Fedora Firefox/3.0b5")
        @suse     = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; tr-TR; rv:1.9b5) Gecko/2008032600 SUSE Firefox/3.0b5")
        @gentoo   = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; tr-TR; rv:1.9b5) Gecko/2008032600 Gentoo Firefox/3.0b5")
        @mandriva = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; tr-TR; rv:1.9b5) Gecko/2008032600 Mandriva Firefox/3.0b5")
        @red_hat  = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.8) Gecko/20050512 Red Hat")
      end

      specify { @nil.linux_distribution.should      be_nil }
      specify { @empty.linux_distribution.should    be_nil }
      specify { @debian.linux_distribution.should   == "Debian" }
      specify { @kubuntu.linux_distribution.should  == "Kubuntu" }
      specify { @ubuntu.linux_distribution.should   == "Ubuntu" }
      specify { @fedora.linux_distribution.should   == "Fedora" }
      specify { @suse.linux_distribution.should     == "SUSE" }
      specify { @gentoo.linux_distribution.should   == "Gentoo" }
      specify { @mandriva.linux_distribution.should == "Mandriva" }
      specify { @red_hat.linux_distribution.should  == "Red Hat" }
    end

    context "with a version" do
      before(:all) do
        @debian1  = UserAgent.parse("Mozilla/5.0 (X11; U; Linux x86_64; de-AT; rv:1.7.8) Gecko/20050513 Debian/1.7.8-1")
        @debian2  = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; rv:1.7.8) Gecko/20061113 Debian/1.7.8-1sarge8")
        @kubuntu1 = UserAgent.parse("Mozilla/5.001 (X11; U; Linux i686; rv:1.8.1.6; de-ch) Gecko/25250101 (kubuntu-feisty)")
        @kubuntu2 = UserAgent.parse("Mozilla/5.001 (X11; U; Linux i686; rv:1.8.1.6; de-ch) Gecko/25250101 (kubuntu/8.04)")
        @ubuntu1  = UserAgent.parse("Mozilla/5.001 (X11; U; Linux i686; rv:1.8.1.6; de-ch) Gecko/25250101 (ubuntu-feisty)")
        @ubuntu2  = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.1) Gecko/2008072820 Ubuntu/8.04 (hardy) (Linux Mint)")
        @fedora   = UserAgent.parse("Mozilla/5.0 (X11; U; Linux x86_64; en-US; rv:1.9b5) Gecko/2008041816 Fedora/3.0-0.55.beta5.fc9 Firefox/3.0b5")
        @suse     = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; tr-TR; rv:1.9b5) Gecko/2008032600 SUSE/2.9.95-25.1 Firefox/3.0b5")
        @gentoo   = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; tr-TR; rv:1.9b5) Gecko/2008032600 Gentoo/2.9.95-25.1 Firefox/3.0b5")
        @mandriva = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; tr-TR; rv:1.9b5) Gecko/2008032600 Mandriva/2.9.95-25.1 Firefox/3.0b5")
        @red_hat  = UserAgent.parse("Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.8) Gecko/20050512 Red Hat/1.7.8-1.1.3.1")
      end

      specify { @debian1.linux_distribution.should  == "Debian 1.7.8-1" }
      specify { @debian2.linux_distribution.should  == "Debian 1.7.8-1sarge8" }
      specify { @kubuntu1.linux_distribution.should == "Kubuntu feisty" }
      specify { @kubuntu2.linux_distribution.should == "Kubuntu 8.04" }
      specify { @ubuntu1.linux_distribution.should  == "Ubuntu feisty" }
      specify { @ubuntu2.linux_distribution.should  == "Ubuntu 8.04" }
      specify { @fedora.linux_distribution.should   == "Fedora 3.0-0.55.beta5.fc9" }
      specify { @suse.linux_distribution.should     == "SUSE 2.9.95-25.1" }
      specify { @gentoo.linux_distribution.should   == "Gentoo 2.9.95-25.1" }
      specify { @mandriva.linux_distribution.should == "Mandriva 2.9.95-25.1" }
      specify { @red_hat.linux_distribution.should  == "Red Hat 1.7.8-1.1.3.1" }
    end
  end

  describe "#language" do
    specify { UserAgent.parse(nil).language.should be_nil }
    specify { UserAgent.parse("").language.should be_nil }
  end

  describe "#security" do
    specify { UserAgent.parse(nil).security.should be_nil }
    specify { UserAgent.parse("").security.should be_nil }
  end

end
