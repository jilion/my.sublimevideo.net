require 'spec_helper'

describe UserAgent::LinuxDistributions do

  describe "REGEXP_AND_NAMES" do

    %w[Debian Kubuntu Ubuntu Fedora SUSE Gentoo Mandriva].each do |distribution|
      describe "#{distribution} detection" do
        context "no version" do
          subject { described_class::REGEXP_AND_NAMES.detect { |regex_and_platform| regex_and_platform[0] =~ distribution } }

          it { subject[1].should == distribution }
          it { $1.should == "" }
        end
        context "version with a space-separator" do
          subject { described_class::REGEXP_AND_NAMES.detect { |regex_and_platform| regex_and_platform[0] =~ "#{distribution} 2.0.0.1+dfsg-2" } }

          it { subject[1].should == distribution }
          it { $1.should == "2.0.0.1+dfsg-2" }
        end
        context "version with a dash-separator" do
          subject { described_class::REGEXP_AND_NAMES.detect { |regex_and_platform| regex_and_platform[0] =~ "#{distribution}-2.0.0.1+dfsg-2" } }

          it { subject[1].should == distribution }
          it { $1.should == "2.0.0.1+dfsg-2" }
        end
        context "version with a slash-separator" do
          subject { described_class::REGEXP_AND_NAMES.detect { |regex_and_platform| regex_and_platform[0] =~ "#{distribution}/1.7.13-0" } }

          it { subject[1].should == distribution }
          it { $1.should == "1.7.13-0" }
        end
      end      
    end
    
  end

end
