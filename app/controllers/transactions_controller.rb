class TransactionsController < ApplicationController
  respond_to :html

  skip_before_filter :authenticate_user!
  before_filter ->{ render(nothing: true, status: 204) }, if: :_tempered_request?

  # Cardholder that have a 3-D Secure card and that successfully authenticated themselves
  # on the Visa/Mastercard 3-D Secure form are redirected to this route.
  # AND
  # As a callback called by OgoneWrapper when a transaction succeed
  # In both cases, the transaction parameters are passed along.
  #
  # POST /transaction/callback
  def callback
    if _operation_was?(:cc_authorization)
      _process_cc_authorization
    elsif _operation_was?(:payment)
      _process_payment
    end
  end

private

  def _tempered_request?
    @sha_params = params.select { |k, v| OgoneWrapper.sha_out_keys.include?(k.upcase) }
    to_digest   = @sha_params.sort { |a, b| a[0].upcase <=> b[0].upcase }.map { |k, v| "#{k.upcase}=#{v}" unless v.blank? }.compact.join(ENV['OGONE_SIGNATURE_OUT'])
    to_digest << ENV['OGONE_SIGNATURE_OUT']
    params['SHASIGN'] != Digest::SHA512.hexdigest(to_digest).upcase
  end

  def _operation_was?(operation)
    case operation
    when :cc_authorization
      params['CHECK_CC_USER_ID'].present?
    when :payment
      params['PAYMENT'].present? && params['orderID'].present?
    end
  end

  def _process_cc_authorization
    user = User.find(params['CHECK_CC_USER_ID'].to_i)

    user.process_credit_card_authorization_response(@sha_params)
    render(nothing: true, status: 200)
  end

  def _process_payment
    transaction = Transaction.where(order_id: params['orderID']).first!
    render(nothing: true, status: 204) and return if transaction.paid? # already paid

    transaction.process_payment_response(@sha_params)
    redirect_to [:sites], notice_and_alert_from_transaction(transaction)
  end

end
