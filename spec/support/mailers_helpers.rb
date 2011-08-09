module Spec
  module Support
    module MailersHelpers

      # it_should_behave_like "common mailer checks", %w[is_expired will_expire], :params => [FactoryGirl.create(:user, :cc_expire_on => 1.day.from_now)]
      shared_examples_for "common mailer checks" do |methods=[], *args|
        options = args.extract_options!
        options.reverse_merge!(:from => ["noreply@sublimevideo.net"], :to => nil, :content_type => %r{text/plain; charset=UTF-8})

        methods.each do |method|
          describe "common checks for #{mailer_class}.#{method}" do
            before(:each) do
              ActionMailer::Base.deliveries.clear
              described_class.send(method, *options[:params]).deliver
              @last_delivery = ActionMailer::Base.deliveries.last
            end

            it "should send an email" do
              ActionMailer::Base.deliveries.size.should == 1
            end

            it "should send the mail from #{[options[:from]].flatten}" do
              @last_delivery.from.should == [options[:from]].flatten
            end

            it "should send the mail to" do
              email = if options[:params].first.respond_to?(:email)
                options[:params].first.email
              else
                options[:params].first.user.email
              end
              @last_delivery.to.should == [options[:to] || email].flatten
            end

            it "should set content_type to #{options[:content_type]} (set by default by the Mail gem)" do
              @last_delivery.content_type.should =~ options[:content_type]
            end

            it "should set a body that contain the link to edit the credit card" do
              @last_delivery.body.encoded.should include I18n.t("mailer.signature")
            end
          end
        end
      end

    end
  end
end