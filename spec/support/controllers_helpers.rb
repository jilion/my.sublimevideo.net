module Spec
  module Support
    module ControllersHelpers
      shared_examples_for "redirect when connected as" do |url, roles, verb_actions, params = {}|
        roles = Array.wrap(roles)
        roles.each do |role|
          role_name, role_stubs = if role.is_a?(Array)
            [role[0], role[1]]
          else
            [role, {}]
          end
          context "a #{role_name}" do
            verb_actions.each do |verb, actions|

              actions = Array.wrap(actions)
              actions.each do |action|
                before do
                  case role_name.to_sym
                  when :user
                    @request.host = "my.test.host"
                    sign_in(role_name.to_sym, send("authenticated_#{role_name}", role_stubs))
                  when :admin
                    @request.host = "admin.test.host"
                    sign_in(role_name.to_sym, send("authenticated_#{role_name}", role_stubs))
                  end
                end

                it "should redirect to #{url} on #{verb.upcase} :#{action}" do
                  params = params.nil? ? {} : params.reverse_merge({ id: '1' })
                  send(verb, action, params)

                  response.should redirect_to(url)
                end
              end
            end
          end
        end
      end

      def authenticated_admin(stubs = {})
        @authenticated_admin ||= mock_admin(stubs)
      end

      def authenticated_user(stubs = {})
        @authenticated_user ||= mock_user(stubs)
      end

      def mock_site(stubs = {})
        @mock_site ||= mock_model(Site, stubs)
      end

      def mock_user(stubs = {})
        @mock_user ||= create(:user, stubs)
      end

      def mock_admin(stubs = {})
        @mock_admin ||= create(:admin, stubs)
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

      def mock_plan(stubs = {})
        @mock_plan ||= mock_model(Plan, stubs)
      end

      def mock_transaction(stubs = {})
        @mock_transaction ||= mock_model(Transaction, stubs)
      end

      def mock_tweet(stubs = {})
        @mock_tweet ||= mock_model(Tweet, stubs)
      end

    end
  end
end

RSpec.configuration.include(Spec::Support::ControllersHelpers)