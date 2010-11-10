module Spec
  module Support
    module ControllerHelpers
      
      def mock_site(stubs = {})
        @mock_site ||= mock_model(Site, stubs)
      end
      
      def mock_user(stubs = {})
        @mock_user ||= mock_model(User, stubs)
      end
      
      def mock_admin(stubs = {})
        @mock_admin ||= mock_model(Admin, stubs)
      end
      
      def logged_in_admin(options = {})
        unless @current_admin
          @current_admin = Factory(:admin, options)
          @current_admin.stub!(:confirmed? => true)
        end
        @current_admin
      end
      
      def logged_in_user(stubs = {})
        unless @current_user
          @current_user = Factory(:user, stubs)
          @current_user.stub!(:active? => true, :confirmed? => true)
        end
        @current_user
        # @logged_in_user = mock_model(User, stubs.reverse_merge(:active? => true, :confirmed? => true, :suspended? => false))
      end
      
      def mock_release(stubs = {})
        @mock_release ||= mock_model(Release, stubs)
      end
      
      def mock_mail_template(stubs = {})
        @mock_mail_template ||= mock_model(MailTemplate, stubs)
      end
      
      def mock_mail_letter(stubs = {})
        @mock_mail_letter ||= mock_model(MailLetter, stubs)
      end
      
      def mock_mail_log(stubs = {})
        @mock_mail_log ||= mock_model(MailLog, stubs)
      end
      
      def mock_delayed_job(stubs = {})
        @mock_delayed_job ||= mock_model(Delayed::Job, stubs)
      end
      
      def mock_ticket(stubs = {})
        @mock_ticket ||= mock_model(Ticket, stubs).as_null_object
      end
      
    end
  end
end

RSpec.configuration.include(Spec::Support::ControllerHelpers)