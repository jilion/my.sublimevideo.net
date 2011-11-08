module Spec
  module Support
    module ControllerHelpers
      extend ActiveSupport::Memoizable

      shared_examples_for "redirect when connected as" do |url, roles, verb_actions, params={}|
        roles = [roles] unless roles.is_a?(Array)
        roles.each do |role|

          role_name, role_stubs = if role.is_a?(Array)
            [role[0], role[1]]
          else
            [role, {}]
          end
          context "a #{role_name}" do
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

      def authenticated_admin(stubs={})
        # admin = mock_admin(stubs.reverse_merge(:confirmed? => true, :authenticatable_salt => "x"))
        # Admin.stub(:find) { admin }
        # Admin.stub(:find_first) { admin }
        # Admin.stub(:find_for_database_authentication) { admin }
        # request.env['warden'] = mock(Warden, :authenticate => admin, :authenticate! => admin, :admin => admin, :user => nil)
        # admin
        mock_admin(stubs)
      end

      def authenticated_user(stubs={})
        # user = mock_user(stubs.reverse_merge(:active? => true, :confirmed? => true, :suspended? => false, :authenticatable_salt => "x"))
        # User.stub(:find) { user }
        # User.stub(:find_first) { user }
        # User.stub(:find_for_database_authentication) { user }
        # Admin.stub(:find) { nil }
        # Admin.stub(:find_first) { nil }
        # Admin.stub(:find_for_database_authentication) { nil }
        # request.env['warden'] = mock(Warden, :authenticate => user, :authenticate! => user, :user => user, :admin => nil)
        # user
        mock_user(stubs)
      end

      def mock_site(stubs={})
        mock_model(Site, stubs)
      end

      def mock_user(stubs={})
        Factory.create(:user, stubs)
      end

      def mock_admin(stubs={})
        Factory.create(:admin, stubs)
      end

      def mock_release(stubs={})
        mock_model(Release, stubs)
      end

      def mock_mail_template(stubs={})
        mock_model(MailTemplate, stubs)
      end

      def mock_mail_letter(stubs={})
        mock_model(MailLetter, stubs)
      end

      def mock_mail_log(stubs={})
        mock_model(MailLog, stubs)
      end

      def mock_delayed_job(stubs={})
        mock_model(Delayed::Job, stubs)
      end

      def mock_ticket(stubs={})
        mock_model(Ticket, stubs).as_null_object
      end

      def mock_plan(stubs={})
        mock_model(Plan, stubs)
      end

      def mock_invoice(stubs={})
        mock_model(Invoice, stubs)
      end

      def mock_transaction(stubs={})
        mock_model(Transaction, stubs)
      end

      def mock_tweet(stubs={})
        mock_model(Tweet, stubs)
      end

      memoize :authenticated_admin, :authenticated_user, :mock_site, :mock_user, :mock_admin, :mock_release, :mock_mail_template, :mock_mail_letter, :mock_mail_log, :mock_delayed_job, :mock_ticket, :mock_plan, :mock_invoice, :mock_transaction, :mock_tweet

    end
  end
end

RSpec.configuration.include(Spec::Support::ControllerHelpers)