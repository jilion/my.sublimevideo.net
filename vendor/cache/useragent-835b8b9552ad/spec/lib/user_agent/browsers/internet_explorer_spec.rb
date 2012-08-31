# coding: utf-8
require 'spec_helper'

describe "comparisons" do
  before(:all) do
    @ie_6 = UserAgent.parse("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)")
    @ie_5 = UserAgent.parse("Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.1)")
    @ie_7 = UserAgent.parse("Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)")
  end

  specify { @ie_6.should_not == @ie_5 }
  specify { @ie_6.should_not <  @ie_5 }
  specify { @ie_6.should_not <= @ie_5 }
  specify { @ie_6.should     >  @ie_5 }
  specify { @ie_6.should     >= @ie_5 }

  specify { @ie_6.should     == @ie_6 }
  specify { @ie_6.should_not <  @ie_6 }
  specify { @ie_6.should     <= @ie_6 }
  specify { @ie_6.should_not >  @ie_6 }
  specify { @ie_6.should     >= @ie_6 }

  specify { @ie_6.should_not == @ie_7 }
  specify { @ie_6.should     <  @ie_7 }
  specify { @ie_6.should     <= @ie_7 }
  specify { @ie_6.should_not >  @ie_7 }
  specify { @ie_6.should_not >= @ie_7 }
end

describe UserAgent::Browsers::InternetExplorer do

  describe "Internet Explorer" do
    describe "Windows" do
      it { "Mozilla/4.0 (compatible; MSIE 4.01; Windows NT)".should be_browser("IE").version("4.01").platform("Windows").os("Windows NT").compatible(true) }
      it { "Mozilla/4.0 (compatible; MSIE 4.01; Windows NT 5.0)".should be_browser("IE").version("4.01").platform("Windows").os("Windows 2000").compatible(true) }

      ["Mozilla/4.0 (compatible; MSIE 4.01; Windows CE)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; Smartphone; 176x220)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; Sprint;PPC-i830; PPC; 240x320)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; Sprint:SCH-i830; PPC; 240x320)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; Sprint; SCH-i830; PPC; 240x320)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; Sprint:SPH-ip830w; PPC; 240x320)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; Sprint:SCH-i320; Smartphone; 176x220)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; Sprint:SPH-ip320; Smartphone; 176x220)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows CE; PPC; 240x320; Sprint:PPC-6700; PPC; 240x320)",
      "Mozilla/4.0 PPC (compatible; MSIE 4.01; Windows CE; PPC; 240x320; Sprint:PPC-6700; PPC; 240x320)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("4.01").platform("Windows").os("Windows CE").compatible(true).mobile(true).crawler(false)
        end
      end

      it { "Mozilla/4.0 (compatible; MSIE 4.01; Windows 95)".should be_browser("IE").version("4.01").platform("Windows").os("Windows 95").compatible(true) }

      ["Mozilla/4.0 (compatible; MSIE 4.01; Windows 98)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows 98; DigExt)",
      "Mozilla/4.0 (compatible; MSIE 4.01; Windows 98; Hotbar 3.0)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("4.01").platform("Windows").os("Windows 98").compatible(true)
        end
      end

      it { "Mozilla/4.0 (compatible; MSIE 4.01; Mac_PowerPC)".should be_browser("IE").version("4.01").platform("Macintosh").compatible(true) }

      it { "Mozilla/4.0 (compatible; MSIE 5.00; Windows 98)".should be_browser("IE").version("5.00").platform("Windows").os("Windows 98").compatible(true) }

      ["Mozilla/4.0 (compatible; MSIE 5.0; Windows 98;)",
      "Mozilla/4.0(compatible; MSIE 5.0; Windows 98; DigExt)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; Hotbar 3.0)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; YComp 5.0.2.4)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt; YComp 5.0.2.6; yplus 1.0)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt; YComp 5.0.2.5; YComp 5.0.0.0)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("5.0").platform("Windows").os("Windows 98").compatible(true)
        end
      end

      ["Mozilla/4.0 (compatible; MSIE 5.0; Windows NT)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT;)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt; Hotbar 3.0)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt; YComp 5.0.2.6)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt; YComp 5.0.2.5)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt; YComp 5.0.0.0)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt; Hotbar 4.1.8.0)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT; DigExt; .NET CLR 1.0.3705)",
      "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT 5.9; .NET CLR 1.1.4322)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("5.0").platform("Windows").os("Windows NT").compatible(true)
        end
      end

      it { "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT 5.2; .NET CLR 1.1.4322)".should be_browser("IE").version("5.0").platform("Windows").os("Windows Server 2003").compatible(true) }
      it { "Mozilla/4.0 (compatible; MSIE 5.0; Windows NT 5.0)".should be_browser("IE").version("5.0").platform("Windows").os("Windows 2000").compatible(true) }

      it { "Mozilla/4.0 (compatible; MSIE 5.5;)".should be_browser("IE").version("5.5").platform(nil).compatible(true) }
      it { "Mozilla/4.0 (compatible;MSIE 5.5; Windows 98)".should be_browser("IE").version("5.5").platform("Windows").os("Windows 98").compatible(true) }
      it { "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT)".should be_browser("IE").version("5.5").platform("Windows").os("Windows NT").compatible(true) }

      ["Mozilla/4.0 (compatible; MSIE 5.5; Windows NT5)",
      "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0; YComp 5.0.2.4)",
      "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0; YComp 5.0.2.5)",
      "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0; YComp 5.0.2.6)",
      "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0; YComp 5.0.2.4; (R1 1.1))",
      "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.0; YComp 5.0.2.6; .NET CLR 1.0.3705)",
      "Mozilla/4.0 (Compatible; MSIE 5.5; Windows NT5.0; Q312461; SV1; .NET CLR 1.1.4322; InfoPath.2)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("5.5").platform("Windows").os("Windows 2000").compatible(true)
        end
      end

      ["Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.1)",
      "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.1)",
      "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.1; SV1; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 5.5; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("5.5").platform("Windows").os("Windows XP").compatible(true)
        end
      end

      it { "Mozilla/4.0 (compatible; MSIE 5.50; Windows 95; SiteKiosk 4.8)".should be_browser("IE").version("5.50").platform("Windows").os("Windows 95").compatible(true) }
      it { "Mozilla/4.0 (compatible; MSIE 5.50; Windows 98; SiteKiosk 4.8)".should be_browser("IE").version("5.50").platform("Windows").os("Windows 98").compatible(true) }

      ["Mozilla/4.0 (compatible; MSIE 5.50; Windows NT; SiteKiosk 4.9; SiteCoach 1.0)",
      "Mozilla/4.0 (compatible; MSIE 5.50; Windows NT; SiteKiosk 4.8; SiteCoach 1.0)",
      "Mozilla/4.0 (compatible; MSIE 5.50; Windows NT; SiteKiosk 4.8)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("5.50").platform("Windows").os("Windows NT").compatible(true)
        end
      end

      ["Mozilla/9.0 (compatible; MSIE 6.0; Windows 98)", "Mozilla/4.0 (compatible;MSIE 6.0;Windows 98;Q312461)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("6.0").platform("Windows").os("Windows 98").compatible(true)
        end
      end

      ["Mozilla/4.0 (MSIE 6.0; Windows NT 5.0)", "Mozilla/4.0 (Windows; MSIE 6.0; Windows NT 5.0)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("6.0").platform("Windows").os("Windows 2000")
        end
      end

      ["Mozilla/6.0 (compatible; MSIE 6.0; Windows NT 5.1)",
      "Mozilla/45.0 (compatible; MSIE 6.0; Windows NT 5.1)",
      "Mozilla/4.08 (compatible; MSIE 6.0; Windows NT 5.1)",
      "Mozilla/4.01 (compatible; MSIE 6.0; Windows NT 5.1)",
      "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)",
      "Mozilla/4.0 (compatible; MSIE 6.0; MSIE 5.5; Windows NT 5.1)",
      "Mozilla/5.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4325)",
      "Mozilla/4.0 (Compatible; Windows NT 5.1; MSIE 6.0) (compatible; MSIE 6.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("6.0").platform("Windows").os("Windows XP").compatible(true)
        end
      end

      ["Mozilla/4.0 (MSIE 6.0; Windows NT 5.1)", "Mozilla/4.0 (Windows; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("6.0").platform("Windows").os("Windows XP")
        end
      end

      it { "Mozilla/4.0 (compatible; MSIE 7.0)".should be_browser("IE").version("7.0").platform(nil).compatible(true) }

      it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.0)".should be_browser("IE").version("7.0").platform("Windows").os("Windows 2000").compatible(true) }
      it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 4.0)".should be_browser("IE").version("7.0").platform("Windows").os("Windows NT 4.0").compatible(true) }
      it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows 95)".should be_browser("IE").version("7.0").platform("Windows").os("Windows 95").compatible(true) }

      ["Mozilla/4.0 (Mozilla/4.0; MSIE 7.0; Windows NT 5.1; FDM; SV1)",
      "Mozilla/4.0 (Windows; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (Mozilla/4.0; MSIE 7.0; Windows NT 5.1; FDM; SV1; .NET CLR 3.0.04506.30)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("7.0").platform("Windows").os("Windows XP")
        end
      end

      it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.2)".should be_browser("IE").version("7.0").platform("Windows").os("Windows XP").compatible(true) }

      ["Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 2.0.50727; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; InfoPath.2; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.1; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 2.0.50727; .NET CLR 1.1.4322; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; MathPlayer 2.10; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; InfoPath.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; WinFX RunTime 3.0.50727; InfoPath.2; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; Avalon 6.0.5070; WinFX RunTime 3.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 3.0.04506.30; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.1; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; InfoPath.2; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 2.0.50727; .NET CLR 3.0.04506.590; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; FDM; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; FDM; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.2; WOW64; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; InfoPath.2; .NET CLR 1.1.4322)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("7.0").platform("Windows").os("Windows Server 2003").compatible(true)
        end
      end

      it { "Mozilla/4.79 [en] (compatible; MSIE 7.0; Windows NT 5.0; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 1.1.4322; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)".should be_browser("IE").version("7.0").platform("Windows").os("Windows 2000").compatible(true).language("en") }
      it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; zh-cn)".should be_browser("IE").version("7.0").platform("Windows").os("Windows XP").compatible(true).language("zh-CN") }
      it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; en-US)".should be_browser("IE").version("7.0").platform("Windows").os("Windows XP").compatible(true).language("en-US") }
      it { "Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 6.0; en-US)".should be_browser("IE").version("7.0").platform("Windows").os("Windows Vista").language("en-US").security(:strong) }

      ["Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1;)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Alexa Toolbar)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; (R1 1.3))",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; MathPlayer 2.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FunWebProducts)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; Alexa Toolbar)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SiteKiosk 6.5 Build 150)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FDM; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0; yplus 5.3.04b)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; (R1 1.5); .NET CLR 1.0.3705)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; (R1 1.3); .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Q312461; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; iOpus-I-M; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; iOpus-I-M; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FDM; SV1; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YComp 5.0.0.0; .NET CLR 1.0.3705)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; Alexa Toolbar)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; (R1 1.5); .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; iOpus-I-M; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; MathPlayer 2.0; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; MEGAUPLOAD 2.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; FunWebProducts; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FunWebProducts; SV1; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; ; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 3.0.04506.30; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0; .NET CLR 2.0.50727; yplus 5.1.04b)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 3.0.04506.03)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Stardock Blog Navigator 1.1; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; (R1 1.3); .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; FDM; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.0.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FunWebProducts; .NET CLR 1.1.4322; PeoplePal 3.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; InfoPath.1; Alexa Toolbar)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.2; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 1.1.4322; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; InfoPath.1; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Tablet PC 1.7)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Tablet PC 1.7; .NET CLR 1.0.3705; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; Alexa Toolbar)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; MEGAUPLOAD 1.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; iOpus-I-M; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; MEGAUPLOAD 2.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FunWebProducts; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FDM; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.2; .NET CLR 2.0.50727; FDM; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; InfoPath.2; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727; .NET CLR 1.1.4322; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; FDM; InfoPath.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.1; FDM; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; Wanadoo 6.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 1.0.3705; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Media Center PC 3.0; .NET CLR 1.0.3705; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; Alexa Toolbar)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; MEGAUPLOAD 1.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FunWebProducts; .NET CLR 1.1.4322; .NET CLR 2.0.50727; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1, .NET CLR 1.1.4322, .NET CLR 2.0.50727, .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; DigExt; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; WinFX RunTime 3.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 3.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Media Center PC 3.0; .NET CLR 1.0.3705; FDM; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; (R1 1.5); .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727; Alexa Toolbar)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.2; Alexa Toolbar; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; MathPlayer 2.0; InfoPath.1; .NET CLR 2.0.50727; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FDM; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR.3.0.04131.06)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FunWebProducts; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; YPC 3.2.0; InfoPath.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; Avalon 6.0.5070; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; (R1 1.3); .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 1.0.3705; InfoPath.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727; .NET CLR 2.0.50215)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; FDM; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; Stardock Blog Navigator 1.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; (R1 1.5); .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 3.0.04506.30; InfoPath.2; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.1; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 1.1.4322; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 1.1.4322; .NET CLR 3.0.04506.30; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; InfoPath.1; .NET CLR 1.1.4322; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.2; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727; .NET CLR 1.0.3705)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; Compatible; SV1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 3.0.04506.590; .NET CLR 3.5.20706)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Tablet PC 1.7; .NET CLR 2.0.40607)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; Tablet PC 1.7; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Media Center PC 3.0; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 3.0.04506.30; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 1.0.3705; Media Center PC 4.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 3.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727; Media Center PC 4.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Media Center PC 3.0; .NET CLR 1.0.3705; .NET CLR 2.0.50727; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; InfoPath.1; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; InfoPath.1; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; WinFX RunTime 3.0.50727; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0; FunWebProducts; .NET CLR 1.1.4322; .NET CLR 2.0.50727; yplus 5.3.04b)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; Alexa Toolbar; MEGAUPLOAD 1.0)",
      "Mozilla/4.0 (compatible; Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727); Windows NT 5.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; Media Center PC 3.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 2.0.50727; .NET CLR 1.1.4322; Media Center PC 4.0; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; FDM; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; (R1 1.5); .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; Media Center PC 2.8)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Tablet PC 1.7; .NET CLR 1.0.3705; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Tablet PC 1.7; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; (R1 1.5); .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0; .NET CLR 1.0.3705; .NET CLR 2.0.50727; .NET CLR 1.1.4322; Media Center PC 4.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FDM; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 3.0.04506.30; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; (R1 1.5); .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 1.0.3705; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FunWebProducts; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; (R1 1.5); Tablet PC 1.7; .NET CLR 1.0.3705; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.2; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Tablet PC 1.7; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; InfoPath.2; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727; Avalon 6.0.5070; WinFX RunTime 3.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 1.1.4322; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.2; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; iOpus-I-M; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.577; .NET CLR 3.5.20526)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1) ; .NET CLR 3.0.04506.648; MEGAUPLOAD 2.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 1.0.3705; InfoPath.1; .NET CLR 2.0.50727; WinFX RunTime 3.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; Alexa Toolbar)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; MEGAUPLOAD 2.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 1.1.4322; MEGAUPLOAD 2.0; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; FDM; InfoPath.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; MathPlayer 2.10b; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 1.0.3705; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727; yplus 5.5.04b)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.590; .NET CLR 3.5.20706; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 1.1.4322; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Tablet PC 1.7; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727; WinFX RunTime 3.0.50727; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; FDM; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; SV1; YPC 3.2.0; FunWebProducts; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 3.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; FDM; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; InfoPath.1; Media Center PC 4.0; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 3.0.04506.590; Alexa Toolbar; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; InfoPath.2; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.1; .NET CLR 2.0.50727; .NET CLR 1.1.4322; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.2; .NET CLR 2.0.50727; .NET CLR 3.0.04506.590; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727; PeoplePal 3.0; SpamBlockerUtility 4.8.4)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; FunWebProducts-MyWay; .NET CLR 1.1.4322; .NET CLR 1.0.3705; .NET CLR 2.0.50727; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; MathPlayer 2.10b; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04324.17; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; .NET CLR 3.5.30428)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 2.0.50727; .NET CLR 1.1.4322; InfoPath.1; InfoPath.2; .NET CLR 3.0.04506.590; .NET CLR 3.5.20706)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 3.0.04506.30; .NET CLR 2.0.50727; .NET CLR 3.0.04506.590)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; YPC 3.2.0; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; yplus 5.1.04b)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Tablet PC 1.7; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; InfoPath.2; .NET CLR 3.0.04506.648)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Tablet PC 1.7; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; o Mozilla/4.0 (compatible; MSIE 7.0 ñ Qwest 1.0; Windows NT 5.1; YPC 3.0.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727))",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; MathPlayer 2.10b; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; InfoPath.2; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022; InfoPath.2; .NET CLR 3.5.30428)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.590; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.590; .NET CLR 3.5.20706; .NET CLR 3.0.04506.648; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.0.3705; .NET CLR 1.1.4322; Media Center PC 4.0; .NET CLR 2.0.50727; InfoPath.1; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)",].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("7.0").platform("Windows").os("Windows XP").compatible(true)
        end
      end

      it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; GTB6; chromeframe; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648; .NET CLR 3.0.4506.2152; .NET CLR 3.5.30729)".should be_browser("IE").version("7.0").platform("Windows").os("Windows XP").compatible(true).chromeframe(true) }
      it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.5)".should be_browser("IE").version("7.0").platform("Windows").os("Windows NT").compatible(true) }
      it { "Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 6.0; en-US)".should be_browser("IE").version("7.0").platform("Windows").os("Windows Vista").language("en-US").security(:strong) }

      ["Mozilla/4.0 (compatible;MSIE 7.0;Windows NT 6.0)",
      "Mozilla /4.0 (compatible;MSIE 7.0;Windows NT6.0)",
      "Mozilla/4.0 (compatible;MSIE 7.0;Windows NT 6.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0;)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; Alexa Toolbar)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SV1; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; WOW64; SLCC1; .NET CLR 3.0.04506)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; .NET CLR 2.0.50727; .NET CLR 3.0.04506)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SV1; InfoPath.1; .NET CLR 1.1.4322; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; .NET CLR 1.1.4322; InfoPath.2; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; InfoPath.2; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; WOW64; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30618)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.5.21022; .NET CLR 3.0.04506; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; .NET CLR 3.5.30729)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; PeoplePal 3.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; InfoPath.2; .NET CLR 1.1.4322; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; FDM; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; .NET CLR 1.1.4322; .NET CLR 3.5.21022; .NET CLR 3.0.04506)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; .NET CLR 1.0.3705)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; WOW64; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; InfoPath.1; Media Center PC 5.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.30618; .NET CLR 3.5.30628)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; FDM; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; WOW64; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.5.30707; .NET CLR 3.0.30618)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 3.0.04506; .NET CLR 3.5.21022; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; .NET CLR 3.5.21022; .NET CLR 1.1.4322; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; MEGAUPLOAD 2.0; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; WOW64; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; Media Center PC 5.0; .NET CLR 3.5.21022; InfoPath.2)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SV1; FunWebProducts; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; WOW64; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; Media Center PC 5.0; .NET CLR 3.5.21022; MEGAUPLOAD 2.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; Tablet PC 2.0; InfoPath.2; .NET CLR 3.5.21022; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; Tablet PC 2.0; .NET CLR 1.1.4322; InfoPath.2; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; WOW64; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; Media Center PC 5.0; .NET CLR 1.1.4322; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; WOW64; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.5.21022; .NET CLR 3.5.30729; .NET CLR 3.0.30618)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; WOW64; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.5.21022; .NET CLR 3.5.30428; .NET CLR 3.0.30422)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; Tablet PC 2.0; InfoPath.2; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; InfoPath.2; .NET CLR 3.5.21022; Tablet PC 2.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; InfoPath.2; FDM; .NET CLR 3.5.21022; .NET CLR 3.5.30729; .NET CLR 3.0.30618)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; WOW64; SLCC1; .NET CLR 2.0.50727; .NET CLR 1.1.4322; InfoPath.2; .NET CLR 3.5.21022; .NET CLR 3.5.30729; .NET CLR 3.0.30618)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; InfoPath.1; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; User-agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; http://bsalsa.com) ; SLCC1; .NET CLR 2.0.50727; .NET CLR 3.0.04506; Media Center PC 5.0)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.5.21022; .NET CLR 3.0.04506; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; InfoPath.2; .NET CLR 3.5.21022; FDM)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; FDM; .NET CLR 3.5.21022; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0; MathPlayer 2.10b; Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) ; SLCC1; .NET CLR 2.0.50727; Media Center PC 5.0; .NET CLR 3.0.04506; Tablet PC 2.0; .NET CLR 1.1.4322; .NET CLR 3.5.21022)",
      "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("7.0").platform("Windows").os("Windows Vista").compatible(true)
        end
      end

      ["Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; FDM; .NET CLR 1.1.4322)",
      "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.1)",
      "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; .NET CLR 1.1.4322; Alexa Toolbar)",
      "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.40607)",
      "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; .NET CLR 1.1.4322; InfoPath.1; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; .NET CLR 1.0.3705; Media Center PC 3.1; Alexa Toolbar; .NET CLR 1.1.4322; .NET CLR 2.0.50727)",
      "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; Media Center PC 3.0; .NET CLR 1.0.3705; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.1)"].each do |user_agent|
        it "should parse #{user_agent}" do
          user_agent.should be_browser("IE").version("7.0b").platform("Windows").os("Windows XP").compatible(true)
        end
      end

      it { "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.2; .NET CLR 1.1.4322; .NET CLR 2.0.50727; InfoPath.2; .NET CLR 3.0.04506.30)".should be_browser("IE").version("7.0b").platform("Windows").os("Windows Server 2003").compatible(true) }
      it { "Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 6.0)".should be_browser("IE").version("7.0b").platform("Windows").os("Windows Vista").compatible(true) }

      it { "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0)".should be_browser("IE").version("8.0").platform("Windows").os("Windows Vista").compatible(true) }
      it { "Mozilla/4.0 (MSIE 8.0; Windows NT 7.1; Avatar26; Intel Mac OS X 10.5; iPad; Android 1.0; X11; Linux i686; Ubuntu 8.04; Macintosh CPU iPhone OS 3_2 like Mac OS X; Symbian OS 9; rv:1.9.1.8; GTB6; .NET".should be_browser("IE").version("8.0").platform("Windows").os("Windows NT 7.1") }
    end


    describe "X11" do
      it { "Mozilla/4.0 (X11; MSIE 6.0; i686; .NET CLR 1.1.4322; .NET CLR 2.0.50727; FDM)".should be_browser("IE").version("6.0").platform("X11") }
    end

    describe "SunOS" do
      it { "Mozilla/5.0 (MSIE 7.0; Macintosh; U; SunOS; X11; gu; SV1; InfoPath.2; .NET CLR 3.0.04506.30; .NET CLR 3.0.04506.648)".should be_browser("IE").version("7.0").platform("SunOS").os("SunOS").language("gu").security(:strong) }
    end

    describe "WebTV" do
      it { "Mozilla/3.0 WebTV/1.2 (compatible; MSIE 2.0)".should be_browser("IE").version("2.0").platform("WebTV").os("WebTV 1.2").compatible(true) }
      it { "WebTV 1.2 Mozilla/3.0 WebTV/1.2 (compatible; MSIE 2.0)".should be_browser("IE").version("2.0").platform("WebTV").os("WebTV").compatible(true) }
      it { "WebTV 2.6 Mozilla/4.0 (compatible; MSIE 4.0; WebTV/2.6)".should be_browser("IE").version("4.0").platform("WebTV").os("WebTV 2.6").compatible(true) }
    end
  end

  describe "Internet Explorer with Chromeframe" do
    it { "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; chromeframe)".should be_browser("IE").version("6.0").platform("Windows").os("Windows XP").compatible(true).chromeframe(true).chromeframe_version(nil) }
    it { "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1) chromeframe/4.0".should be_browser("IE").version("6.0").platform("Windows").os("Windows XP").compatible(true).chromeframe(true).chromeframe_version("4.0") }
    it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; chromeframe/10.0.648.204)".should be_browser("IE").version("7.0").platform("Windows").os("Windows XP").compatible(true).chromeframe(true).chromeframe_version("10.0.648.204") }
    it { "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; chromeframe/10.0.648.204; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0)".should be_browser("IE").version("8.0").platform("Windows").os("Windows 7").compatible(true).chromeframe(true).chromeframe_version("10.0.648.204") }
    it { "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0) chromeframe/10.0.648.204".should be_browser("IE").version("9.0").platform("Windows").os("Windows 7").compatible(true).chromeframe(true).chromeframe_version("10.0.648.204") }
  end

  describe "Internet Explorer mobile" do
    it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows Phone OS 7.0; Trident/3.1; IEMobile/7.0; SAMSUNG; SGH-i917)".should be_browser("IE").version("7.0").platform("Windows Phone").os("Windows Phone OS 7.0").compatible(true).mobile(true) }
    it { "HTC_Touch_3G Mozilla/4.0 (compatible; MSIE 6.0; Windows CE; IEMobile 7.11)".should be_browser("IE").version("6.0").platform("Windows").os("Windows CE").compatible(true).mobile(true) }
    it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows Phone OS 7.0; Trident/3.1; IEMobile/7.0) ASUS;GALAXY6".should be_browser("IE").version("7.0").platform("Windows Phone").os("Windows Phone OS 7.0").compatible(true).mobile(true) }
    it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows Phone OS 7.0; Trident/3.1; IEMobile/7.0) Microsoft Corporation;CEPC".should be_browser("IE").version("7.0").platform("Windows Phone").os("Windows Phone OS 7.0").compatible(true).mobile(true) }
    it { "Mozilla/4.0 (compatible; MSIE 7.0; Windows Phone OS 7.0; Trident/3.1; IEMobile/7.0; LG; LG-E900)".should be_browser("IE").version("7.0").platform("Windows Phone").os("Windows Phone OS 7.0").compatible(true).mobile(true) }
  end

end
