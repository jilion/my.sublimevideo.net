require 'spec_helper'

describe UserAgent::Browsers::Other do

  describe "ABrowse" do
    it { "Mozilla/5.0 (compatible; ABrowse 0.4; Syllable)".should be_browser("ABrowse").version("0.4") }
    it { "Mozilla/5.0 (compatible; U; ABrowse 0.6; Syllable) AppleWebKit/420+ (KHTML, like Gecko)".should be_browser("ABrowse").version("0.6").security(:strong) }
  end

  describe "Acoo Browser" do
    it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; Acoo Browser; GTB5; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; Maxthon; InfoPath.1; .NET CLR 3.5.30729; .NET CLR 3.0.30618)".should be_browser("Acoo Browser").platform("Windows").os("Windows Vista") }
  end

  describe "Amaya" do
    it { "amaya/9.51 libwww/5.4.0".should be_browser("amaya").version("9.51") }
    specify { UserAgent.parse("amaya/9.51 libwww/5.4.0").libwww.version.should == "5.4.0" }
  end

  describe "America Online Browser" do
    it { "Mozilla/4.0 (compatible; MSIE 7.0; America Online Browser 1.1; Windows NT 5.1; (R1 1.5); .NET CLR 2.0.50727; InfoPath.1)".should be_browser("America Online Browser").version("1.1").platform("Windows").os("Windows XP").compatible(true) }
  end

  describe "Amiga" do
    it { "AmigaVoyager/3.2 (AmigaOS/MC680x0)".should be_browser("AmigaVoyager").version("3.2").os("AmigaOS") }
  end

  describe "AOL" do
    it { "Mozilla/4.0 (compatible; MSIE 8.0; AOL 9.6; AOLBuild 4340.27; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)".should be_browser("AOL").version("9.6").platform("Windows").os("Windows XP").compatible(true) }
  end

  describe "Avant Browser" do
    it { "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; Avant Browser; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0)".should be_browser("Avant Browser").platform("Windows").os("Windows 7").compatible(true) }
    it { "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; Avant Browser; InfoPath.2; .NET CLR 2.0.50727; OfficeLiveConnector.1.3; OfficeLivePatch.0.0; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729; BO1IE8_v1;ENUS; AskTbFWV5/5.9.1.14019)".should be_browser("Avant Browser").platform("Windows").os("Windows XP").compatible(true) }
  end

  describe "BlackBerry" do
    it { "BlackBerry9700/5.0.0.862 Profile/MIDP-2.1 Configuration/CLDC-1.1 VendorID/331".should be_browser("BlackBerry").version("5.0.0.862").platform("BlackBerry").os("BlackBerryOS") }
  end

  describe "Galaxy" do
    it { "Galaxy/1.0 [en] (Mac OS X 10.5.6; U; en)".should be_browser("Galaxy").version("1.0").platform("Macintosh").language("en").security(:strong) }
  end

  describe "Kindle" do
    it { "Mozilla/4.0 (compatible; Linux 2.6.10) NetFront/3.3 Kindle/1.0 (screen 600x800)".should be_browser("Kindle").version("1.0").platform("Linux").os("Linux 2.6.10") }
    it { "Mozilla/5.0 (Linux; U; en-US) AppleWebKit/528.5+ (KHTML, like Gecko, Safari/528.5+) Version/4.0 Kindle/3.0 (screen 600x800; rotate)".should be_browser("Kindle").version("3.0").platform("Linux").os("Linux").language("en-US").security(:strong) }
    it { "Mozilla/5.0 (Windows; U; Windows NT 6.1; zh-CN; rv:1.9.2.7) Gecko/20100713 Kindle/1.0 ( .NET CLR 3.5.30729)".should be_browser("Kindle").version("1.0").platform("Windows").os("Windows 7").language("zh-CN").security(:strong) }
  end

  describe "Konqueror" do
    it { "Mozilla/5.0 (compatible; Konqueror/4.4; Linux) KHTML/4.4.1 (like Gecko) Fedora/4.4.1-1.fc12".should be_browser("Konqueror").version("4.4").platform("Linux").os("Linux").linux_distribution("Fedora 4.4.1-1.fc12") }
    it { "Mozilla/5.0 (compatible; Konqueror/4.4; Linux 2.6.32-22-generic; X11; en_US) KHTML/4.4.3 (like Gecko) Kubuntu".should be_browser("Konqueror").version("4.4").platform("Linux").os("Linux 2.6.32-22-generic").linux_distribution("Kubuntu").language("en-US") }
  end

  describe "Lynx" do
    it { "Lynx/2.8.8dev.3 libwww-FM/2.14 SSL-MM/1.4.1".should be_browser("Lynx").version("2.8.8dev.3") }
  end

  describe "NetFront" do
    it { "LGE-VM510 NetFront/3.5.1 (GUI) MMP/2.0".should be_browser("NetFront").version("3.5.1") }
  end

  describe "NetPositive" do
    it { "Mozilla/3.0 (compatible; NetPositive/2.2)".should be_browser("NetPositive").version("2.2").compatible(true) }
    it { "Mozilla/3.0 (compatible; NetPositive/2.2.1; BeOS)".should be_browser("NetPositive").version("2.2.1").platform("BeOS").os("BeOS").compatible(true) }
    it { "Mozilla/3.0 (compatible; NetPositive/2.2.2; BeOS)".should be_browser("NetPositive").version("2.2.2").platform("BeOS").os("BeOS").compatible(true) }
    it { "Mozilla/3.0 (compatible; NetPositive/2.2.3; FreeBSD 5.2.1 i686)".should be_browser("NetPositive").version("2.2.3").platform("FreeBSD").os("FreeBSD 5.2.1 i686").compatible(true) }
  end

  describe "Playstation 3" do
    it { "Mozilla/5.0 (PLAYSTATION 3; 3.55)".should be_browser("PlayStation 3").version("3.55").platform("PlayStation 3").os("PlayStation 3") }
    it { "Mozilla/5.0 (PLAYSTATION 3; 1.00)".should be_browser("PlayStation 3").version("1.00").platform("PlayStation 3").os("PlayStation 3") }
  end

  describe "Playstation Portable" do
    it { "PSP (PlayStation Portable); 2.00".should be_browser("PlayStation Portable").platform("PlayStation Portable").os("PlayStation Portable").mobile(true) }
    it { "Mozilla/4.0 (PSP (PlayStation Portable); 2.00)".should be_browser("PlayStation Portable").platform("PlayStation Portable").os("PlayStation Portable").mobile(true) }
  end

end
