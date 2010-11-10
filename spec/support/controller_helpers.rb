module Spec
  module Support
    module ControllerHelpers
      
      shared_examples_for "redirect when connected" do |url, roles, verb_actions, params={}|
        roles = [roles] unless roles.is_a?(Array)
        roles.each do |role|
          
          role_name, role_stubs = if role.is_a?(Array)
            [role[0], role[1]]
          else
            [role, {}]
          end
          context "as a #{role_name}" do
            verb_actions.each do |verb, actions|
              
              actions = [actions] unless actions.is_a?(Array)
              actions.each do |action|
                before(:each) do
                  case role_name.to_sym
                  when :user, :admin
                    sign_in(role_name.to_sym, send("authenticated_#{role_name}", role_stubs))
                  end
                end
                
                it "should redirect to #{url} on #{verb.upcase} :#{action}" do
                  params_to_pass = params
                  params_to_pass = (params_to_pass.nil? || [:index, :new].include?(verb.to_sym)) ? {} : params_to_pass.reverse_merge({ :id => '1' })
                  send(verb, action, params_to_pass)
                  response.should redirect_to(url)
                end
              end
            end
          end
        end
      end
      
      def mock_site(stubs = {})
        @mock_site ||= mock_model(Site, stubs)
      end
      
      def mock_user(stubs = {})
        @mock_user ||= mock_model(User, stubs)
      end
      
      def mock_admin(stubs = {})
        @mock_admin ||= mock_model(Admin, stubs)
      end
      
      def authenticated_admin(stubs = {})
        unless @current_admin
          @current_admin = mock_model(Admin, stubs.reverse_merge(:confirmed? => true))
          Admin.stub(:find) { @current_admin }
        end
        @current_admin
      end
      
      def authenticated_user(stubs = {})
        unless @current_user
          @current_user = mock_model(User, stubs.reverse_merge(:active? => true, :confirmed? => true, :suspended? => false))
          User.stub(:find) { @current_user }
        end
        @current_user
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