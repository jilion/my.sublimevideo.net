# coding: utf-8
require 'spec_helper'
require 'one_time/site'

describe OneTime::Site do

  describe '.regenerate_templates' do
    before do
      create(:site)
      create(:site, state: 'archived')
      Delayed::Job.delete_all
    end

    it 'regenerates loader and license of all sites' do
      lambda { described_class.regenerate_templates(loader: true, license: true) }.should change(
        Delayed::Job.where { handler =~ '%update_loader_and_license%' }, :count
      ).by(1)
    end
  end

  describe '.set_first_billable_plays_at' do
    let(:site1) { create(:site) }
    let(:site2) { create(:site) }
    let(:site3) { create(:site) }
    let(:site4) { create(:site) }
    let(:site5) { create(:site) }
    let(:site6) { create(:site) }

    before do
      create(:site_day_stat, t: site1.token, d: 400.days.ago.midnight, vv: { m: 11 }) # > 10 main views
      create(:site_day_stat, t: site2.token, d: 200.days.ago.midnight, vv: { e: 11 }) # > 10 extra views
      create(:site_day_stat, t: site3.token, d: 100.days.ago.midnight, vv: { em: 11 }) # > 10 embed views
      create(:site_day_stat, t: site4.token, d: 50.days.ago.midnight, vv: { m: 5, e: 3, em: 2 }) # > 10 views
      create(:site_day_stat, t: site5.token, d: 25.day.ago.midnight, vv: { m: 9 }) # less than 10 views
      create(:site_day_stat, t: site6.token, d: 12.day.ago.midnight, vv: { d: 11 }) # > 10 views but dev views
    end

    it 'set first_billable_plays_at to the first day with at least 10 billable views' do
      described_class.set_first_billable_plays_at

      site1.reload.first_billable_plays_at.should eq 400.days.ago.midnight
      site2.reload.first_billable_plays_at.should eq 200.days.ago.midnight
      site3.reload.first_billable_plays_at.should eq 100.days.ago.midnight
      site4.reload.first_billable_plays_at.should eq 50.days.ago.midnight
      site5.reload.first_billable_plays_at.should be_nil
      site6.reload.first_billable_plays_at.should be_nil
    end
  end

end
