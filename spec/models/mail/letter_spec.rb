require 'spec_helper'

describe Mail::Letter do
  
  describe "Class Methods" do
    describe "#deliver_and_log" do
      let(:user)          { Factory(:user) }
      let(:admin)         { Factory(:admin) }
      let(:attributes)    { { :admin_id => admin.id, :template_id => mail_template.id.to_s, :criteria => "with_activity" } }
      let(:mail_template) { Factory(:mail_template) }
      let(:mail_letter)   { Mail::Letter.new(attributes) }
      
      before(:each) { User.stub_chain(:with_activity, :all).and_return([user]) }
      
      it "should save all the data" do
        ml = mail_letter.deliver_and_log
        
        ml.admin.should    == admin
        ml.template.should == mail_template
        ml.criteria.should == "with_activity"
        ml.user_ids.should == [user.id]
        ml.snapshot.should == mail_template.snapshotize
      end
      
      it "should keep a snapshot that doesn't change when the original template is modified" do
        ml = mail_letter.deliver_and_log
        
        old_snapshot = mail_template.snapshotize
        mail_template.update_attributes(:title => "foo", :subject => "bar", :body => "John Doe")
        
        ml.snapshot.should_not == mail_template.reload.snapshotize
        ml.snapshot.should     == old_snapshot
      end
      
      context "with multiple users to send emails to" do
        before(:each) { User.stub_chain(:with_activity, :all).and_return([user, Factory(:user), Factory(:user)]) }
        
        it "should delay delivery of mails" do
          lambda do
            mail_letter.deliver_and_log
          end.should change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(3)
        end
        
        it "should actually send email when workers do their jobs" do
          mail_letter.deliver_and_log
          lambda { Delayed::Worker.new(:quiet => true).work_off }.should change(ActionMailer::Base.deliveries, :size).by(3)
        end
      end
      
      it "should create a new Mail::Log record" do
        lambda { mail_letter.deliver_and_log }.should change(Mail::Log, :count).by(1)
      end
    end
  end
  
end