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
        context "with the 'dev' filter" do
          set(:mail_letter_dev) { Mail::Letter.new(attributes.merge(:criteria => 'dev')) }
          before(:each) { User.stub!(:where).with(:email => ["thibaud@jilion.com", "remy@jilion.com", "zeno@jilion.com", "octave@jilion.com"]).and_return([user]) }
          subject { mail_letter_dev.deliver_and_log }
          
          it "should delay delivery of mails" do
            lambda { subject }.should change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(1)
          end
          
          it "should actually send email when workers do their jobs" do
            subject
            lambda { Delayed::Worker.new(:quiet => true).work_off }.should change(ActionMailer::Base.deliveries, :size).by(1)
          end
          
          it "should send email to user with activity sites and should send appropriate template" do
            ActionMailer::Base.deliveries.clear
            subject
            Delayed::Worker.new(:quiet => true).work_off
            
            ActionMailer::Base.deliveries.last.to.should == [user.email]
            ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
          end
          
          it "should not create a new Mail::Log record" do
            lambda { subject }.should_not change(Mail::Log, :count)
          end
        end
        
        context "with the 'with_activity' filter" do
          set(:user_with_activity1) { Factory(:user) }
          set(:user_with_activity2) { Factory(:user) }
          before(:each) { User.stub_chain(:with_activity).and_return([user, user_with_activity1, user_with_activity2]) }
          subject { mail_letter.deliver_and_log }
          
          it "should delay delivery of mails" do
            lambda do
              subject
            end.should change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(3)
          end
          
          it "should actually send email when workers do their jobs" do
            subject
            lambda { Delayed::Worker.new(:quiet => true).work_off }.should change(ActionMailer::Base.deliveries, :size).by(3)
          end
          
          it "should send email to user with activity sites and should send appropriate template" do
            ActionMailer::Base.deliveries.clear
            subject
            Delayed::Worker.new(:quiet => true).work_off
            
            ActionMailer::Base.deliveries.map(&:to).flatten.should == [user.email, user_with_activity1.email, user_with_activity2.email]
            ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
          end
          
          it "should create a new Mail::Log record" do
            lambda { subject }.should change(Mail::Log, :count).by(1)
          end
        end
        
        context "with the 'with_invalid_site' filter" do
          set(:user_with_invalid_site)   { Factory(:user, :invitation_token => nil) }
          set(:user_with_invalid_site2)  { Factory(:user, :invitation_token => nil) }
          set(:mail_letter_invalid_site) { Mail::Letter.new(attributes.merge(:criteria => 'with_invalid_site')) }
          before(:all) do
            invalid_site = Factory.build(:site, :user => user_with_invalid_site, :hostname => 'test')
            invalid_site.save(:validate => false)
            archived_invalid_site = Factory.build(:site, :user => user_with_invalid_site2, :state => 'archived', :hostname => 'test')
            archived_invalid_site.save(:validate => false)
          end
          subject { mail_letter_invalid_site.deliver_and_log }
          
          it "should delay delivery of mails" do
            lambda { subject }.should change(Delayed::Job.where(:handler.matches => "%deliver%"), :count).by(1)
          end
          
          it "should actually send email when workers do their jobs" do
            subject
            lambda { Delayed::Worker.new(:quiet => true).work_off }.should change(ActionMailer::Base.deliveries, :size).by(1)
          end
          
          it "should send email to user with invalid sites and should send appropriate template" do
            ActionMailer::Base.deliveries.clear
            subject
            Delayed::Worker.new(:quiet => true).work_off
            
            ActionMailer::Base.deliveries.last.to.should == [user_with_invalid_site.email]
            ActionMailer::Base.deliveries.last.subject.should =~ /help us shaping the right pricing/
          end
          
          it "should create a new Mail::Log record" do
            lambda { subject }.should change(Mail::Log, :count).by(1)
          end
        end
      end
      
    end
  end
  
end