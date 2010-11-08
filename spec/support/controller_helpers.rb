module Spec
  module Support
    module ControllerHelpers
      
      def mock_site(stubs={})
        @mock_site ||= mock_model(Site, stubs)
      end
      
      def mock_user(stubs={})
        @mock_user ||= mock_model(User, stubs)
      end
      
      def mock_admin(stubs = {})
        @mock_admin ||= mock_model(Admin, stubs)
      end
      
      def logged_in_admin(options = {})
        unless @logged_in_admin
          @logged_in_admin = Factory(:admin, options)
          @logged_in_admin.stub!(:confirmed? => true)
        end
        @logged_in_admin
      end
      
      def logged_in_user(options = {})
        unless @current_user
          @current_user = Factory(:user, options)
          @current_user.stub!(:active? => true, :confirmed? => true)
        end
        @current_user
      end
      
      def mock_mail_template(stubs={})
        @mock_mail_template ||= mock_model(MailTemplate, stubs)
      end
      
      def mock_mail_letter(stubs={})
        @mock_mail_letter ||= mock_model(MailLetter, stubs)
      end
      
      def mock_mail_log(stubs={})
        @mock_mail_log ||= mock_model(MailLog, stubs)
      end
      
      def mock_delayed_job(stubs={})
        @mock_delayed_job ||= mock_model(Delayed::Job, stubs)
      end
      
      def mock_ticket(stubs = {})
        @mock_ticket ||= mock_model(Ticket, stubs).as_null_object
      end
      
    end
  end
end

RSpec.configuration.include(Spec::Support::ControllerHelpers)