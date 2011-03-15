class TransactionsController < ApplicationController
  respond_to :html

  skip_before_filter :authenticate_user!
  before_filter do |controller|
    if tempered_request?
      render(text: "Tampered request!", status: 400) and return
    end
  end

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

  # Cardholder that have a 3-D Secure card and that successfully authenticated themselves
  # on the Visa/Mastercard 3-D Secure form are redirected to this route.
  # AND
  # As a callback called by Ogone when a transaction succeed
  # In both cases, the transaction parameters are passed along.
  #
  # POST /transaction/ok
  def ok
    if operation_was?(:cc_authorization)
      process_cc_authorization
    else

    end
  end

  # POST /transaction/ko
  def ko
    # FUCK
  end

private

  def operation_was?(operation)
    case operation
    when :cc_authorization
      params["CC_CHECK"] && params["USER_ID"]
    end
  end

  def tempered_request?
    params.delete(:controller)
    params.delete(:action)
    Rails.logger.info "params.inspect: #{params.inspect}"

    sha_out = params.delete("SHASIGN")
    string_to_digest = params.keys.sort { |a, b| a.upcase <=> b.upcase }.map { |s| "#{s.upcase}=#{params[s]}" }.join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]

    Rails.logger.info "string_to_digest: #{string_to_digest}"
    Rails.logger.info "sha_out: #{sha_out}"
    Rails.logger.info "Digest::SHA512.hexdigest(string_to_digest).upcase: #{Digest::SHA512.hexdigest(string_to_digest).upcase}"

    sha_out != Digest::SHA512.hexdigest(string_to_digest).upcase
  end

  def process_cc_authorization
    @user = User.find(params["USER_ID"].to_i)
    @user.process_cc_authorization_response(params, [params["PAYID"], 'RES'].join(';'))

    respond_with do |format|
      if @user.errors.present?
        flash[:alert] = "You credit card could not be authorized, please retry with another credit card."
      else
        flash[:notice] = t("flash.credit_cards.update.notice")
      end
      format.html { redirect_to [:edit, :user_registration] }
    end
  end

end
