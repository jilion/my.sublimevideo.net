# coding: utf-8
require 'spec_helper'
require 'one_time/stats/sites_stat'

describe OneTime::Stats::SitesStat do
  before do
    ::Stats::SitesStat.create(d: Time.now.yesterday.midnight, tr: { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } })
    ::Stats::SitesStat.create(d: Time.now.midnight, tr: { "plus" => { "m" => 4, "y" => 2 }, "premium" => { "m" => 2, "y" => 1 } })
    ::Stats::SitesStat.create(d: Time.now.tomorrow.midnight, tr: 42)

    ::Stats::SitesStat.count.should eq 3
      
    first_sites_stat = ::Stats::SitesStat.where(d: Time.now.yesterday.midnight).first
    first_sites_stat["tr"].should == { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }
      
    last_sites_stat = ::Stats::SitesStat.where(d: Time.now.midnight).first
    last_sites_stat["tr"].should == { "plus" => { "m" => 4, "y" => 2 }, "premium" => { "m" => 2, "y" => 1 } }
  end
  
  describe '.reduce_trial_hash' do
    it 'merges all the hash count into one integer' do
      described_class.reduce_trial_hash
      
      first_sites_stat = ::Stats::SitesStat.where(d: Time.now.yesterday.midnight).first
      first_sites_stat["tr"].should eq 14
      
      second_sites_stat = ::Stats::SitesStat.where(d: Time.now.midnight).first
      second_sites_stat["tr"].should eq 9
      
      last_sites_stat = ::Stats::SitesStat.where(d: Time.now.tomorrow.midnight).first
      last_sites_stat["tr"].should eq 42
    end
  end
  
end
