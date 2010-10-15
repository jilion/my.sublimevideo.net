require 'spec_helper'

describe Stat::Global do
  let(:site) { Factory(:site) }
  let(:day1) { Date.new(2010, 1, 1) }
  let(:day2) { Date.new(2010, 1, 2) }
  let(:day3) { Date.new(2010, 1, 3) }
  let(:day4) { Date.new(2010, 1, 4) }
  let(:stat_day1) { Factory(:stat_global, :day => day1, :vpv => { "new" => -1 }) }
  let(:stat_day2) { Factory(:stat_global, :day => day2, :vpv => { "new" => 1000 }) }
  let(:stat_day3) { Factory(:stat_global, :day => day3, :vpv => { "new" => 2000 }) }
  let(:stat_day4) { Factory(:stat_global, :day => day4, :vpv => { "new" => 3000 }) }
  
  context "build with valid attributes" do
    subject { Factory.build(:stat_global) }
    
    its(:day)   { should be_instance_of(Date) }
    its(:vpv)   { should == { "new" => -1, "total" => -1 } }
    its(:users) { should == { "new" => -1, "total" => -1 } }
    its(:sites) { should == { "new" => -1, "total" => -1 } }
    
    it { should be_valid }
  end
  
  context "saved with valid attributes" do
    subject { Factory(:stat_global) }
    
    its(:day)   { should be_instance_of(Date) }
    its(:vpv)   { should == { "new" => -1, "total" => -1 } }
    its(:users) { should == { "new" => -1, "total" => -1 } }
    its(:sites) { should == { "new" => -1, "total" => -1 } }
  end
  
  describe "validates" do
    [:day, :new, :total, :new_users, :tot_users, :new_sites, :tot_sites].each do |attr|
      it { should allow_mass_assignment_of(attr) }
    end
    
    # Devise checks presence/uniqueness/format of email, presence/length of password
    it { should validate_presence_of(:day) }
    
    it "should validate uniqueness of day" do
      Factory(:stat_global, :day => day1)
      stat = Factory.build(:stat_global, :day => day1)
      stat.should_not be_valid
      stat.errors[:day].should == ["is already taken"]
    end
  end
  
  describe ".delay_calculate_all_new" do
    it "should delay .calculate_all_new" do
      lambda { Stat::Global.delay_calculate_all_new(Date.today) }.should change(Delayed::Job, :count).by(1)
      Delayed::Job.last.name.should == 'Class#calculate_all_new'
    end
  end
  
  describe ".calculate_all_new" do
    shared_examples_for "with all 'new' field non-existant" do |options|
      it "should delay calculate for each 'new' field * day count in the range given with given options: #{options.inspect}" do
        lambda {
          Stat::Global.calculate_all_new(day1, day3, options)
        }.should change(Delayed::Job, :count).by(Stat::Global.calculated_new_fields.size*3)
        Delayed::Job.all.all? { |j| j.name == 'Class#calculate' }.should be_true
      end
    end
    
    context "with all 'new' field non-existant" do
      it_should_behave_like("with all 'new' field non-existant", {})
      it_should_behave_like("with all 'new' field non-existant", { :force => true })
    end
    
    context "with some fields already calculated" do
      it "should delay calculate for each non-existant 'new' field * day count in the range given with no options given" do
        stat_day1; stat_day2; stat_day3; stat_day4 # instanciate stat objects
        lambda {
          Stat::Global.calculate_all_new(day1, day4, {})
        }.should change(Delayed::Job, :count).by(1)
        Delayed::Job.all.all? { |j| j.name == 'Class#calculate' }.should be_true
      end
      
      it "should delay calculate for each 'new' field * day count in the range given with the :force option given" do
        lambda {
          Stat::Global.calculate_all_new(day1, day4, { :force => true })
        }.should change(Delayed::Job, :count).by(Stat::Global.calculated_new_fields.size*4)
        Delayed::Job.all.all? { |j| j.name == 'Class#calculate' }.should be_true
      end
    end
    
  end
  
  describe ".calculate_vpv" do
    it "should raise an exception if given type is not valid" do
      expect {
        Stat::Global.calculate_vpv('foo', day1)
      }.to raise_error(StandardError, "Impossible to calculate vpv on #{day1} for the type: foo!")
      stat_day1.reload.vpv["new"].should == -1
    end
    
    context "type == 'new'" do
      it "should set new vpv to 0 for the given day if no SiteUsage is available" do
        stub_new_vpv_calculation(day1, nil)
        Stat::Global.calculate_vpv('new', day1).should == 0
        Stat::Global.last.vpv["new"].should == 0
        Stat::Global.last.day.should == day1
      end
      
      it "should calculate new vpv for the given day" do
        stat_day1 # instanciate
        stub_new_vpv_calculation(day1, 12)
        Stat::Global.calculate_vpv('new', day1).should == 12
        stat_day1.reload.vpv["new"].should == 12
      end
      
      it "should calculate new vpv for the given day even if already calculated" do
        stat_day2 # instanciate
        stub_new_vpv_calculation(day2, 2000)
        Stat::Global.calculate_vpv('new', day2).should == 2000
        stat_day2.reload.vpv["new"].should == 2000
      end
    end
    
    context "type == 'total'" do
      before(:each) do
        VCR.use_cassette('one_saved_logs') do
          Factory(:site_usage, :site => site, :player_hits => 1, :log => Factory(:log_voxcast, :name => 'day1', :started_at => day1.beginning_of_day, :ended_at => day1.end_of_day))
          Factory(:site_usage, :site => site, :player_hits => 2, :log => Factory(:log_voxcast, :name => 'day2', :started_at => day2.beginning_of_day, :ended_at => day2.end_of_day))
          Factory(:site_usage, :site => site, :player_hits => 3, :log => Factory(:log_voxcast, :name => 'day3', :started_at => day3.beginning_of_day, :ended_at => day3.end_of_day))
        end
      end
      
      it "should calculate total vpv by adding the vpv of all the days before" do
        Stat::Global.calculate_vpv('total', day1).should == 1
        Stat::Global.calculate_vpv('total', day2).should == 3
        Stat::Global.calculate_vpv('total', day3).should == 6
        Stat::Global.where(:day => day1).first.vpv["total"].should == 1
        Stat::Global.where(:day => day2).first.vpv["total"].should == 3
        Stat::Global.where(:day => day3).first.vpv["total"].should == 6
      end
      
      it "should calculate total vpv for the given day even if already calculated" do
        Stat::Global.calculate_vpv('total', day2).should == 3
        Stat::Global.where(:day => day2).first.vpv["total"].should == 3
      end
    end
  end
  
end

def stub_new_vpv_calculation(date, result)
  r = []
  SiteUsage.stub(:between).with(date.beginning_of_day, date.end_of_day).and_return(r)
  r.stub(:sum).with("player_hits").and_return(result)
end

def stub_total_vpv_calculation(date, result)
  r = []
  SiteUsage.stub(:ended_before).with(date.end_of_day).and_return(r)
  r.stub(:sum).with("player_hits").and_return(result)
end