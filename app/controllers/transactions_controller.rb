class TransactionsController < ApplicationController
  respond_to :html

  skip_before_filter :authenticate_user!
  
  # ORDERID
  # Your order reference
  # AMOUNT
  # Order amount (not multiplied by 100)
  # CURRENCY
  # Order currency
  # PM
  # Payment method
  # ACCEPTANCE
  # Acceptance code returned by acquirer
  # STATUS
  # Transaction status (see Appendix: Status overview)
  # CARDNO
  # Masked card number
  # PAYID
  # Payment reference in our system
  # NCERROR
  # Error code
  # BRAND
  # Card brand (our system derives this from the card number)
  # ED
  # Expiry date
  # TRXDATE
  # Transaction date
  # CN
  # Cardholder/customer name
  # SHASIGN
  # SHA signature calculated by our system (if SHA-1-OUT configured)
  # USER_ID
  # CC_CHECK => true

  def payment_ok
    render(text: "Tampered request!", status: 500) and return unless verify_params_integrity

    if params["USER_ID"] && params["CC_CHECK"] # it was a credit card authorization
      @user = User.find(params["USER_ID"].to_i)
      @user.process_cc_authorization_response(params, [params["PAYID"], 'RES'].join(';'))

      respond_with do |format|
        if @user.errors.empty?
          redirect_to [:edit, :user_registration]
        else
          render :edit
        end
      end
    else

    end
  end

  def payment_ko
    # FUCK
  end

private

  def verify_params_integrity
    params.delete(:controller)
    params.delete(:action)
    Rails.logger.info "params.inspect: #{params.inspect}"

    sha_out = params.delete("SHASIGN")
    string_to_digest = params.keys.sort { |a, b| a.upcase <=> b.upcase }.map { |s| "#{s.upcase}=#{params[s]}" }.join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]

    Rails.logger.info "string_to_digest: #{string_to_digest}"
    Rails.logger.info "sha_out: #{sha_out}"
    Rails.logger.info "Digest::SHA512.hexdigest(string_to_digest).upcase: #{Digest::SHA512.hexdigest(string_to_digest).upcase}"

    sha_out == Digest::SHA512.hexdigest(string_to_digest).upcase
  end

end
