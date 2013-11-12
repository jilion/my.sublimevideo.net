require 'spec_helper'

describe ApplicationHelper do
  include Devise::TestHelpers

  describe "#display_bool" do
    it { helper.display_bool(true).should eq "✓" }
    it { helper.display_bool(1).should eq "✓" }
    it { helper.display_bool(0).should eq "–" }

    it { helper.display_bool(false).should eq "–" }
    it { helper.display_bool(nil).should eq "–" }
    it { helper.display_bool('').should eq "–" }
  end

  describe "#display_time" do
    let(:date) { Time.now.utc }
    it { helper.display_time(date).should eq I18n.l(date, format: :minutes_y) }
    it { helper.display_time(nil).should eq "–" }
  end

  describe '#display_integer' do
    it { helper.display_integer(1234).should eq '1,234' }
    it { helper.display_integer(1_234_567).should eq '1.235M' }
  end

  describe '#display_percentage' do
    it { helper.display_percentage(0.123).should eq '12.3%' }
    it { helper.display_percentage(0.12345).should eq '12.35%' }

    it { helper.display_percentage(0.1234567, precision: 1).should eq '12.3%' }
    it { helper.display_percentage(0.1234567, precision: 3).should eq '12.346%' }

    it { helper.display_percentage(0.123, strip_insignificant_zeros: false).should eq '12.30%' }
    it { helper.display_percentage(0.12345, strip_insignificant_zeros: false).should eq '12.35%' }

    it { helper.display_percentage(0.1234567, precision: 1, strip_insignificant_zeros: false).should eq '12.3%' }
    it { helper.display_percentage(0.1234, precision: 3, strip_insignificant_zeros: false).should eq '12.340%' }

    it { helper.display_percentage(0.00004).should eq '< 0.01%' }
    it { helper.display_percentage(0).should eq '0%' }
  end

  describe "#display_amount" do
    it { helper.display_amount(1990).should eq "$19.90" }
    it { helper.display_amount(1990, decimals: 1).should eq "$19.9" }
    it { helper.display_amount(1900).should eq "$19" }
    it { helper.display_amount(1900, decimals: 1).should eq "$19.0" }
  end

  describe "#display_amount_with_sup" do
    it { helper.display_amount_with_sup(1990).should eq "$19<sup>.90</sup><small>/mo</small>" }
    it { helper.display_amount_with_sup(1990.0).should eq "$19<sup>.90</sup><small>/mo</small>" }
    it { helper.display_amount_with_sup(7920).should eq "$79<sup>.20</sup><small>/mo</small>" }
    it { helper.display_amount_with_sup(1900).should eq "$19<small>/mo</small>" }
  end

  describe "#url_host" do
    it { helper.url_host('http://sublimevideo.net/').should eq 'sublimevideo.net' }
    it { helper.url_host('http://sublimevideo.net/foo/bar').should eq 'sublimevideo.net' }
    it { helper.url_host('http://sublimevideo.net/foo/bar?query=value').should eq 'sublimevideo.net' }
    it { helper.url_host('http://sublimevideo.net/#video_framework').should eq 'sublimevideo.net' }
    it { helper.url_host('http://ad-emea.doubleclick.net/N3847/adi/ebay.uk.vip/MPU;sz=300x250;cat=69536;tcat=1;cat=1;cat=14429;cat=69529;items=;seg=AdvGL3rdP;sz=300x250;u=i_1746282867726173717|m_172857;;dcopt=ist;tile=1;ot=1;um=0;us=13;eb_trk=172857;pr=20;xp=20;np=20;uz=Unknown;fbi=;sbi=;fbo=;sbo=;fse=;sse=;fvi=;svi=;kw=hand,signed,karen,pickering,mbe,photo;lkw=;cg=c368a6c913f0a2aac5b53625fff30ce8;ord=1380894945345;').should eq 'ad-emea.doubleclick.net' }
  end

  # describe "#info_box" do
  #   it { helper.info_box { "<p>foo</p>" }.should eq '<div class="info_box"><p>foo</p><span class="arrow"></span></div>' }
  # end

end
