module Spec
  module Support
    module MailersHelpers

      # it_should_behave_like "common mailer checks", %w[is_expired will_expire], params: [FactoryGirl.create(:user, cc_expire_on: 1.day.from_now)]
      shared_examples_for "common mailer checks" do |methods=[], *args|
        options = args.extract_options!
        options.reverse_merge!(from: [I18n.t('mailer.info.email')], to: nil, content_type: %r{multipart/alternative; boundary="--==_mimepart_\w+"; charset=UTF-8})

        methods.each do |method|
          describe "common checks for #{mailer_class}.#{method}" do
            before do
              @params = Array.wrap(options[:params].respond_to?(:call) ? options[:params].call : options[:params])
              ActionMailer::Base.deliveries.clear
              described_class.send(method, *@params).deliver
              @last_delivery = ActionMailer::Base.deliveries.last
            end

            it "should send an email" do
              ActionMailer::Base.deliveries.should have(1).item
            end

            it "should send the mail from #{[options[:from]].flatten}" do
              @last_delivery.from.should eq [options[:from]].flatten
            end

            it "should send the mail to" do
              email = if @params.first.respond_to?(:email)
                @params.first.email
              else
                @params.first.user.email
              end
              @last_delivery.to.should eq [options[:to] || email].flatten
            end

            it "should set content_type to #{options[:content_type]} (set by default by the Mail gem)" do
              @last_delivery.content_type.should =~ options[:content_type]
            end

            it "should #{'not' if options[:no_signature]} include the default signature" do
              if options[:no_signature]
                @last_delivery.body.encoded.should_not include I18n.t("mailer.signature")
              else
                @last_delivery.body.encoded.should include I18n.t("mailer.signature")
              end
            end
          end
        end

      end

    end
  end
end
