require 'spec_helper'

describe StatsExportMailer do
  let(:stats_export) { create(:stats_export) }

  describe '.export_ready' do
    before do
      expect { described_class.export_ready(stats_export).deliver }.to change(ActionMailer::Base.deliveries, :size).by(1)
      last_delivery = ActionMailer::Base.deliveries.last
    end

    it { last_delivery.to.should eq [stats_export.site.user.email] }
    it { last_delivery.from.should eq ['stats@sublimevideo.net'] }

    it 'has a subject' do
      from_date = I18n.l(stats_export.from, format: :d_b_Y)
      to_date = I18n.l(stats_export.to, format: :d_b_Y)
      last_delivery.subject.should eq "Stats export for #{stats_export.site.hostname} (#{from_date} - #{to_date})"
    end

    it 'contains a link to the stats export file' do
      last_delivery.body.encoded.should include url_for(stats_export)
    end

    it 'does not include reply text' do
      last_delivery.body.encoded.should_not include I18n.t("mailer.reply_to_this_email")
    end
  end

end
