require 'spec_helper'

describe TransactionsController do

  describe "#callback" do

    context "with a non-tempered request" do
      describe "credit card authorization response" do
        context "that succeeds" do
          before do
            @sha_params = { "PAYID" => "1234", "STATUS" => "5" }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234", "STATUS=5"].join(ENV['OGONE_SIGNATURE_OUT']) + ENV['OGONE_SIGNATURE_OUT']).upcase
            }
            expect(User).to receive(:find).with(1).and_return(@m = mock_user(i18n_notice_and_alert: nil))
          end

          it "should add a notice and redirect to /account" do
            expect(@m).to receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            expect(flash[:notice]).to be_nil
            expect(flash[:alert]).to be_nil
            expect(response.body).to be_blank
            expect(response.status).to eq 200
          end
        end

        context "that's waiting" do
          before do
            @sha_params = { "PAYID" => "1234", "STATUS" => "51" }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234", "STATUS=51"].join(ENV['OGONE_SIGNATURE_OUT']) + ENV['OGONE_SIGNATURE_OUT']).upcase
            }
            expect(User).to receive(:find).with(1).and_return(@m = mock_user(i18n_notice_and_alert: { alert: I18n.t("credit_card.errors.waiting") }))
          end

          it "should add an alert and redirect to /account" do
            expect(@m).to receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            expect(flash[:notice]).to be_nil
            expect(flash[:alert]).to be_nil
            expect(response.body).to be_blank
            expect(response.status).to eq 200
          end
        end

        context "that fails (invalid)" do
          before do
            @sha_params = { "PAYID" => "1234", "STATUS" => "0" }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234", "STATUS=0"].join(ENV['OGONE_SIGNATURE_OUT']) + ENV['OGONE_SIGNATURE_OUT']).upcase
            }
            expect(User).to receive(:find).with(1).and_return(@m = mock_user(i18n_notice_and_alert: { alert: I18n.t("credit_card.errors.invalid") }))
          end

          it "should add an alert and redirect to /account" do
            expect(@m).to receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            expect(flash[:notice]).to be_nil
            expect(flash[:alert]).to be_nil
            expect(response.body).to be_blank
            expect(response.status).to eq 200
          end
        end

        context "that fails (refused)" do
          before do
            @sha_params = { "PAYID" => "1234", "STATUS" => "2" }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234", "STATUS=2"].join(ENV['OGONE_SIGNATURE_OUT']) + ENV['OGONE_SIGNATURE_OUT']).upcase
            }
            expect(User).to receive(:find).with(1).and_return(@m = mock_user(i18n_notice_and_alert: { alert: I18n.t("credit_card.errors.refused") }))
          end

          it "should add an alert and redirect to /account" do
            expect(@m).to receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            expect(flash[:notice]).to be_nil
            expect(flash[:alert]).to be_nil
            expect(response.body).to be_blank
            expect(response.status).to eq 200
          end
        end

        context "that's unknown (status 52)" do
          before do
            @sha_params = { "PAYID" => "1234", "STATUS" => "52" }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234", "STATUS=52"].join(ENV['OGONE_SIGNATURE_OUT']) + ENV['OGONE_SIGNATURE_OUT']).upcase
            }
            expect(User).to receive(:find).with(1).and_return(@m = mock_user(i18n_notice_and_alert: { alert: I18n.t("credit_card.errors.unknown") }))
          end

          it "should add an alert and redirect to /account" do
            expect(@m).to receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            expect(flash[:notice]).to be_nil
            expect(flash[:alert]).to be_nil
            expect(response.body).to be_blank
            expect(response.status).to eq 200
          end
        end

        context "that's unknown (other status)" do
          before do
            @sha_params = { "PAYID" => "1234", "STATUS" => "187" }
            @params = {
              "CHECK_CC_USER_ID" => "1",
              "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234","STATUS=187"].join(ENV['OGONE_SIGNATURE_OUT']) + ENV['OGONE_SIGNATURE_OUT']).upcase
            }
            expect(User).to receive(:find).with(1).and_return(@m = mock_user(i18n_notice_and_alert: { alert: I18n.t("credit_card.errors.unknown") }))
          end

          it "should add an alert and redirect to /account" do
            expect(@m).to receive(:process_credit_card_authorization_response).with(@sha_params)

            post :callback, @params.merge(@sha_params)
            expect(flash[:notice]).to be_nil
            expect(flash[:alert]).to be_nil
            expect(response.body).to be_blank
            expect(response.status).to eq 200
          end
        end
      end

      describe "payment response" do
        before do
          @sha_params = { "PAYID" => "1234", "STATUS" => "9", "orderID" => "dwqdqw756w6q4d654qwd64qw" }
          @params = {
            "PAYMENT" => "TRUE",
            "SHASIGN" => Digest::SHA512.hexdigest(["ORDERID=dwqdqw756w6q4d654qwd64qw", "PAYID=1234", "STATUS=9"].join(ENV['OGONE_SIGNATURE_OUT']) + ENV['OGONE_SIGNATURE_OUT']).upcase
          }
        end

        context "transaction is already paid" do
          it "should return" do
            Transaction.stub_chain(:where, :first!) { mock_transaction }
            allow(mock_transaction).to receive(:paid?) { true }
            expect(mock_transaction).not_to receive(:process_payment_response)

            post :callback, @params.merge(@sha_params)
            expect(flash[:notice]).to be_nil
            expect(flash[:alert]).to be_nil
            expect(response.body).to be_blank
            expect(response.status).to eq 204
          end
        end

        context "transaction not already paid" do
          context "that succeeds" do
            before do
              @sha_params = { "PAYID" => "1234", "STATUS" => "9", "orderID" => "dwqdqw756w6q4d654qwd64qw" }
              @params = {
                "PAYMENT" => "TRUE",
                "SHASIGN" => Digest::SHA512.hexdigest(["ORDERID=dwqdqw756w6q4d654qwd64qw", "PAYID=1234", "STATUS=9"].join(ENV['OGONE_SIGNATURE_OUT']) + ENV['OGONE_SIGNATURE_OUT']).upcase
              }
            end

            it "should add a notice and redirect to /account" do
              Transaction.stub_chain(:where, :first!) { mock_transaction }
              allow(mock_transaction).to receive(:paid?) { false }
              allow(mock_transaction).to receive(:state) { 'paid' }
              expect(mock_transaction).to receive(:process_payment_response).with(@sha_params)

              post :callback, @params.merge(@sha_params)
              expect(flash[:notice]).to be_nil
              expect(flash[:alert]).to be_nil
              expect(response).to redirect_to(sites_url)
            end
          end

          context "that fails" do
            before do
              @sha_params = { "PAYID" => "1234", "STATUS" => "2", "orderID" => "dwqdqw756w6q4d654qwd64qw" }
              @params = {
                "PAYMENT" => "TRUE",
                "SHASIGN" => Digest::SHA512.hexdigest(["ORDERID=dwqdqw756w6q4d654qwd64qw", "PAYID=1234", "STATUS=2"].join(ENV['OGONE_SIGNATURE_OUT']) + ENV['OGONE_SIGNATURE_OUT']).upcase
              }
            end

            it "should add an alert and redirect to /account" do
              Transaction.stub_chain(:where, :first!) { mock_transaction }
              allow(mock_transaction).to receive(:paid?) { false }
              allow(mock_transaction).to receive(:state) { 'failed' }
              expect(mock_transaction).to receive(:process_payment_response).with(@sha_params)

              post :callback, @params.merge(@sha_params)
              expect(flash[:notice]).to eq ""
              expect(flash[:alert]).to eq I18n.t("transaction.errors.failed")
              expect(response).to redirect_to(sites_url)
            end
          end
        end
      end
    end

    context "with a tempered request" do
      before do
        @sha_params = { "PAYID" => "1234", "STATUS" => "5" }
        @params = {
          "CHECK_CC_USER_ID" => "1",
          "SHASIGN" => Digest::SHA512.hexdigest(["PAYID=1234", "STATUS=5"].join(ENV['OGONE_SIGNATURE_OUT']) + ENV['OGONE_SIGNATURE_OUT']).upcase
        }
        @sha_params["STATUS"] = "9" # tempering!!!!!
      end

      it "should void authorization" do
        post :callback, @params.merge(@sha_params)

        expect(response.body).to be_blank
        expect(response.status).to eq 204
      end
    end

  end

end
