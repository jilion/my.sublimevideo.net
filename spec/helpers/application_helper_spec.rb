require 'spec_helper'

describe ApplicationHelper do
  include Devise::TestHelpers

  describe "#display_bool" do
    it { expect(helper.display_bool(true)).to eq "✓" }
    it { expect(helper.display_bool(1)).to eq "✓" }
    it { expect(helper.display_bool(0)).to eq "–" }

    it { expect(helper.display_bool(false)).to eq "–" }
    it { expect(helper.display_bool(nil)).to eq "–" }
    it { expect(helper.display_bool('')).to eq "–" }
  end

  describe "#display_time" do
    let(:date) { Time.now.utc }
    it { expect(helper.display_time(date)).to eq I18n.l(date, format: :minutes_y) }
    it { expect(helper.display_time(nil)).to eq "–" }
  end

  describe '#display_integer' do
    it { expect(helper.display_integer(1234)).to eq '1,234' }
    it { expect(helper.display_integer(1_234_567)).to eq '1.235M' }
  end

  describe '#display_percentage' do
    it { expect(helper.display_percentage(0.123)).to eq '12.3%' }
    it { expect(helper.display_percentage(0.12345)).to eq '12.35%' }

    it { expect(helper.display_percentage(0.1234567, precision: 1)).to eq '12.3%' }
    it { expect(helper.display_percentage(0.1234567, precision: 3)).to eq '12.346%' }

    it { expect(helper.display_percentage(0.123, strip_insignificant_zeros: false)).to eq '12.30%' }
    it { expect(helper.display_percentage(0.12345, strip_insignificant_zeros: false)).to eq '12.35%' }

    it { expect(helper.display_percentage(0.1234567, precision: 1, strip_insignificant_zeros: false)).to eq '12.3%' }
    it { expect(helper.display_percentage(0.1234, precision: 3, strip_insignificant_zeros: false)).to eq '12.340%' }

    it { expect(helper.display_percentage(0.00004)).to eq '< 0.01%' }
    it { expect(helper.display_percentage(0)).to eq '0%' }
  end

  describe "#display_amount" do
    it { expect(helper.display_amount(1990)).to eq "$19.90" }
    it { expect(helper.display_amount(1990, decimals: 1)).to eq "$19.9" }
    it { expect(helper.display_amount(1900)).to eq "$19" }
    it { expect(helper.display_amount(1900, decimals: 1)).to eq "$19.0" }
  end

  describe "#display_amount_with_sup" do
    it { expect(helper.display_amount_with_sup(1990)).to eq "$19<sup>.90</sup><small>/mo</small>" }
    it { expect(helper.display_amount_with_sup(1990.0)).to eq "$19<sup>.90</sup><small>/mo</small>" }
    it { expect(helper.display_amount_with_sup(7920)).to eq "$79<sup>.20</sup><small>/mo</small>" }
    it { expect(helper.display_amount_with_sup(1900)).to eq "$19<small>/mo</small>" }
  end

  describe "#url_host" do
    it { expect(helper.url_host('http://sublimevideo.net/')).to eq 'sublimevideo.net' }
    it { expect(helper.url_host('http://sublimevideo.net/foo/bar')).to eq 'sublimevideo.net' }
    it { expect(helper.url_host('http://sublimevideo.net/foo/bar?query=value')).to eq 'sublimevideo.net' }
    it { expect(helper.url_host('http://sublimevideo.net/#video_framework')).to eq 'sublimevideo.net' }
    it { expect(helper.url_host('http://ad-emea.doubleclick.net/N3847/adi/ebay.uk.vip/MPU;sz=300x250;cat=69536;tcat=1;cat=1;cat=14429;cat=69529;items=;seg=AdvGL3rdP;sz=300x250;u=i_1746282867726173717|m_172857;;dcopt=ist;tile=1;ot=1;um=0;us=13;eb_trk=172857;pr=20;xp=20;np=20;uz=Unknown;fbi=;sbi=;fbo=;sbo=;fse=;sse=;fvi=;svi=;kw=hand,signed,karen,pickering,mbe,photo;lkw=;cg=c368a6c913f0a2aac5b53625fff30ce8;ord=1380894945345;')).to eq 'ad-emea.doubleclick.net' }
  end

  describe "#proxied_image_tag" do
    it "returns image tag via images.weserv.nl" do
      expect(helper.proxied_image_tag('http://sublimevideo.net/image.jpg')).to eq(
        "<img alt=\"Image\" src=\"https://images.weserv.nl?url=sublimevideo.net/image.jpg\" />")
    end

    it "returns image tag via images.weserv.nl with size options" do
      expect(helper.proxied_image_tag('http://sublimevideo.net/image.jpg', size: '60x40')).to eq(
        "<img alt=\"Image\" height=\"40\" src=\"https://images.weserv.nl?url=sublimevideo.net/image.jpg&amp;w=60&amp;h=40\" width=\"60\" />")
    end

    it "returns image tag via images.weserv.nl with scheme less url" do
      expect(helper.proxied_image_tag('sublimevideo.net/image.jpg', size: '60x40')).to eq(
        "<img alt=\"Image\" height=\"40\" src=\"https://images.weserv.nl?url=sublimevideo.net/image.jpg&amp;w=60&amp;h=40\" width=\"60\" />")
    end
  end

end
