require 'spec_helper'

describe UserAgent::OperatingSystems do

  describe "REGEXP_AND_NAMES" do

    # OS with version detection
    ["FreeBSD", "OpenBSD", "NetBSD", "SunOS", "BeOS", "OS/2", "WebTV", "Nintendo DS",].each do |os|
      describe "#{os} detection" do
        context "no version" do
          subject { described_class::REGEXP_AND_NAMES.detect { |regex_and_platform| regex_and_platform[0] =~ os } }

          it { subject[1].should == os }
          it { $1.should == "" }
        end
        context "version with a dash-separator" do
          subject { described_class::REGEXP_AND_NAMES.detect { |regex_and_platform| regex_and_platform[0] =~ "#{os}-i386" } }

          it { subject[1].should == os }
          it { $1.should == "i386" }
        end
        context "version with a slash-separator" do
          subject { described_class::REGEXP_AND_NAMES.detect { |regex_and_platform| regex_and_platform[0] =~ "#{os}/i386" } }

          it { subject[1].should == os }
          it { $1.should == "i386" }
        end
      end
    end

    # OS with no version detection
    %w[AmigaOS BlackBerryOS].each do |os|
      describe "#{os} detection" do
        context "no version" do
          subject { described_class::REGEXP_AND_NAMES.detect { |regex_and_platform| regex_and_platform[0] =~ os } }

          it { subject[1].should == os }
        end
      end
    end

  end

end
