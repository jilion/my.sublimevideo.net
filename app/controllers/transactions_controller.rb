require_dependency 'ogone'

class TransactionsController < ApplicationController
  respond_to :html

  skip_before_filter :authenticate_user!
  before_filter do |controller|
    if tempered_request?
      render(nothing: true, status: 204) and return
    end
  end

  # Cardholder that have a 3-D Secure card and that successfully authenticated themselves
  # on the Visa/Mastercard 3-D Secure form are redirected to this route.
  # AND
  # As a callback called by Ogone when a transaction succeed
  # In both cases, the transaction parameters are passed along.
  #
  # POST /transaction/callback
  def callback
    if operation_was?(:cc_authorization)
      process_cc_authorization
    elsif operation_was?(:payment)
      process_payment
    end
  end

private

  def tempered_request?
    @sha_params = params.select { |k, v| Ogone.sha_out_keys.include?(k.upcase) }
    to_digest   = @sha_params.sort { |a, b| a[0].upcase <=> b[0].upcase }.map { |k, v| "#{k.upcase}=#{v}" unless v.blank? }.compact.join(Ogone.signature_out) + Ogone.signature_out

    params["SHASIGN"] != Digest::SHA512.hexdigest(to_digest).upcase
  end

  def operation_was?(operation)
    case operation
    when :cc_authorization
      params["CHECK_CC_USER_ID"].present?
    when :payment
      params["PAYMENT"].present? && params["orderID"].present?
    end
  end

  def process_cc_authorization
    user = User.find(params["CHECK_CC_USER_ID"].to_i)

    user.process_credit_card_authorization_response(@sha_params)
    render(nothing: true, status: 200)
  end

  def process_payment
    transaction = Transaction.find_by_order_id(params["orderID"])
    render(nothing: true, status: 204) and return if transaction.paid? # already paid

    transaction.process_payment_response(@sha_params)
    redirect_to [:sites], notice_and_alert_from_transaction(transaction)
  end

end
