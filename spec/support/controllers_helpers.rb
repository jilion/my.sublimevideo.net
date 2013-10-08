module Spec
  module Support
    module ControllersHelpers
      shared_examples_for 'redirect when connected as' do |url, roles, verb_actions, params = {}|
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
                  @request.host = "#{url =~ /admin/ ? 'admin' : 'my'}.test.host"
                  case role_name.to_sym
                  when :user, :admin
                    sign_in(role_name.to_sym, send("authenticated_#{role_name}", role_stubs))
                  end
                end

                it "redirects to #{url} on #{verb.upcase} :#{action}" do
                  params = params.nil? ? {} : params.reverse_merge({ id: '1' })
                  send(verb, action, params)

                  expect(response).to redirect_to(url)
                end
              end
            end
          end
        end
      end

      FORMATS = %i[html js json csv]
      shared_examples_for 'responds to formats' do |formats, verb, actions|
        respond_to_formats = formats & FORMATS
        dont_respond_to_formats = FORMATS - respond_to_formats

        actions.each do |action|
          respond_to_formats.each do |format|
            it "responds to #{format.upcase} on #{verb.upcase} :#{action}" do
              send(verb, action, params.merge(format: format))

              expect(response).to be_success
            end
          end

          dont_respond_to_formats.each do |format|
            it "does not respond to #{format.upcase} on #{verb.upcase} :#{action}" do
              expect { send(verb, action, params.merge(format: format)) }.to \
              raise_error(ActionController::UnknownFormat)
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

      def mock_mail_template(stubs = {})
        @mock_mail_template ||= mock_model(MailTemplate, stubs)
      end

      def mock_mail_letter(stubs = {})
        @mock_mail_letter ||= mock_model(MailLetter, stubs)
      end

      def mock_mail_log(stubs = {})
        @mock_mail_log ||= mock_model(MailLog, stubs)
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

      def mock_design(stubs = {})
        @mock_design ||= mock_model(Design, stubs)
      end

      def mock_addon_plan(stubs = {})
        @mock_addon_plan ||= mock_model(AddonPlan, stubs)
      end

    end
  end
end

RSpec.configure do |config|
  config.include Spec::Support::ControllersHelpers
end
