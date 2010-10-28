require 'spec_helper'

describe Mail::Letter do
  
  describe "Class Methods" do
    describe "#deliver_and_log" do
      set(:user)          { Factory(:user) }
      set(:admin)         { Factory(:admin) }
      set(:attributes)    { { :admin_id => admin.id, :template_id => mail_template.id.to_s, :criteria => "with_activity" } }
      set(:mail_template) { Factory(:mail_template) }
      set(:mail_letter)   { Mail::Letter.new(attributes) }
      
      before(:each) { User.stub_chain(:with_activity).and_return([user]) }
      
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
        context "with the 'with_activity' filter" do
          before(:each) { User.stub_chain(:with_activity).and_return([user, Factory(:user), Factory(:user)]) }
          
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
        
        context "with the 'with_invalid_site' filter" do
          set(:user_with_invalid_site) { Factory(:user, :invitation_token => nil) }
          set(:mail_letter2)           { Mail::Letter.new(attributes.merge(:criteria => 'with_invalid_site')) }
          before(:all) do
            invalid_site = Factory.build(:site, :user => user_with_invalid_site, :hostname => 'test')
            invalid_site.save(:validate => false)
          end
          
          it "should delay delivery of mails" do
            lambda do
              mail_letter2.deliver_and_log
            end.should change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(1)
          end
          
          it "should actually send email when workers do their jobs" do
            mail_letter2.deliver_and_log
            lambda { Delayed::Worker.new(:quiet => true).work_off }.should change(ActionMailer::Base.deliveries, :size).by(1)
          end
          
          it "should send email to the user with invalid sites when workers do their jobs" do
            ActionMailer::Base.deliveries.clear
            mail_letter2.deliver_and_log
            Delayed::Worker.new(:quiet => true).work_off
            
            ActionMailer::Base.deliveries.last.to.should == [user_with_invalid_site.email]
            ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
          end
        end
      end
      
      it "should create a new Mail::Log record" do
        lambda { mail_letter.deliver_and_log }.should change(Mail::Log, :count).by(1)
      end
    end
  end
  
end