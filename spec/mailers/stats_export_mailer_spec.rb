require 'spec_helper'

describe StatsExportMailer do
  let(:stats_export) { create(:stats_export) }

  describe ".export_ready" do
    before do
      described_class.export_ready(stats_export).deliver
      last_delivery = ActionMailer::Base.deliveries.last
    end

    it "send an email" do
      last_delivery.should be_present
    end

    it "send email to stats_export site owner" do
      last_delivery.to.should include stats_export.site.user.email
    end

    it "send email from SV stats email" do
      last_delivery.from.should include "stats@sublimevideo.net"
    end

    it "has a subject" do
      from_date = I18n.l(stats_export.from, format: :d_b_Y)
      to_date = I18n.l(stats_export.to, format: :d_b_Y)
      last_delivery.subject.should eq(
        "Stats export for #{stats_export.site.hostname} (#{from_date} - #{to_date})"
      )
    end

    it "should set a body that contain the link to peak insurance docs" do
      last_delivery.body.encoded.should include url_for(stats_export)
    end

    it "does not include reply text" do
      last_delivery.body.encoded.should_not include I18n.t("mailer.reply_to_this_email")
    end
  end

end
