require 'spec_helper'

describe Mail::Log do
  subject { Factory(:mail_log) }
  
  context "with valid attributes" do
    its(:template) { should be_present }
    its(:admin)    { should be_present }
    its(:criteria)    { should == ["with_activity"] }
    its(:user_ids)    { should == [1,2,3,4,5] }
    its(:snapshot)    { should == { :title => "Blabla", :subject => "Blibli", :body => "Blublu" } }
    
    it { should be_valid }
  end
  
  describe "should be invalid" do
    %w[template_id admin_id criteria user_ids snapshot].each do |attribute|
      it "without #{attribute}" do
        ml = Factory.build(:mail_log, attribute.to_sym => nil)
        ml.should_not be_valid
        ml.errors[attribute.to_sym].should be_present
      end
    end
  end
  
  describe "Class Methods" do
    describe ".deliver_and_save_log" do
      let(:user)         { Factory(:user) }
      let(:admin)         { Factory(:admin) }
      let(:mail_template) { Factory(:mail_template) }
      let(:attributes)    { Factory.attributes_for(:mail_log).merge(:admin_id => admin.id, :template_id => mail_template.id.to_s) }
      
      before(:each) { User.stub_chain(:with_activity, :all).and_return([user]) }
      
      it "should create a new Mail::Log record" do
        lambda do
          Mail::Log.deliver_and_save_log(attributes)
        end.should change(Mail::Log, :count).by(1)
      end
      
      it "should save all the data" do
        ml = Mail::Log.deliver_and_save_log(attributes)
        
        ml.admin.should    == admin
        ml.template.should == mail_template
        ml.criteria.should == ["with_activity"]
        ml.user_ids.should == [user.id]
        ml.snapshot.should == mail_template.snapshotize
      end
      
      it "should keep a snapshot that doesn't change when the original template is modified" do
        ml = Mail::Log.deliver_and_save_log(attributes)
        
        old_snapshot = mail_template.snapshotize
        mail_template.update_attributes(:title => "foo", :subject => "bar", :body => "John Doe")
        
        ml.snapshot.should_not == mail_template.reload.snapshotize
        ml.snapshot.should     == old_snapshot
      end
      
      context "with multiple users to send emails to" do
        before(:each) { User.stub_chain(:with_activity, :all).and_return([user, Factory(:user), Factory(:user)]) }
        
        it "should delay delivery of mails" do
          lambda do
            Mail::Log.deliver_and_save_log(attributes)
          end.should change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(3)
        end
        
        it "should actually send email when workers do their jobs" do
          Mail::Log.deliver_and_save_log(attributes)
          lambda do
            Delayed::Worker.new(:quiet => true).work_off
          end.should change(ActionMailer::Base.deliveries, :size).by(3)
        end
      end
    end
  end
  
end

# == Schema Information
#
# Table name: mail_logs
#
#  id          :integer         not null, primary key
#  template_id :integer
#  admin_id    :integer
#  criteria    :text
#  user_ids    :text
#  snapshot    :text
#  created_at  :datetime
#  updated_at  :datetime
#

