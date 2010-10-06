module Spec
  module Support
    module MailerHelpers
      
      def common_mailer_checks(mailer_class, methods = [], *args)
        options = args.extract_options!
        options.reverse_merge!(:from => ["noreply@sublimevideo.net"], :to => [], :content_type => "text/plain; charset=UTF-8")
        
        instance_variables = options[:params].map { |p| instance_variable_get("@#{p.to_s}") }
        
        methods.each do |method|
          describe "common checks for #{mailer_class}.#{method}" do
            before(:each) do
              ActionMailer::Base.deliveries.clear
              mailer_class.send(method, *instance_variables).deliver
              @last_delivery = ActionMailer::Base.deliveries.last
            end
            
            it "should send an email" do
              ActionMailer::Base.deliveries.size.should == 1
            end
            
            it "should send the mail from noreply@sublimevideo.net" do
              @last_delivery.from.should == options[:from]
            end
            
            it "should send the mail to user.email" do
              @last_delivery.to.should == [instance_variables.first.try(:email)] || options[:to]
            end
            
            it "should set content_type to text/plain (set by default by the Mail gem)" do
              @last_delivery.content_type.should == options[:content_type]
            end
          end
        end
      end
      
      # describe "common checks" do
      #   common_mailer_checks(CreditCardMailer, %w[is_expired will_expire], :params => [:user])
      # end
      
    end
  end
end