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
    to_digest   = @sha_params.sort { |a, b| a[0].upcase <=> b[0].upcase }.map { |k, v| "#{k.upcase}=#{v}" unless v.blank? }.compact.join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]

    params["SHASIGN"] != Digest::SHA512.hexdigest(to_digest).upcase
  end

  def operation_was?(operation)
    case operation
    when :cc_authorization
      params["CHECK_CC_USER_ID"]

    when :payment
      params["PAYMENT"] && params["orderID"]
    end
  end

  def process_cc_authorization
    user = User.find(params["CHECK_CC_USER_ID"].to_i)

    respond_with do |format|
      if user.process_cc_authorize_and_save(@sha_params)
        flash[:notice] = t("flash.credit_cards.update.notice")
      elsif
        flash[:alert] = t("credit_card.errors.#{response}")
      end
      format.html { redirect_to [:edit, :user_registration] }
    end
  end

  def process_payment
    transaction = Transaction.find_by_order_id(params["orderID"])
    render(nothing: true, status: 204) and return if transaction.paid? # already paid

    transaction.process_payment_response(@sha_params)

    respond_with do |format|
      if transaction.paid?
        format.html { redirect_to :sites, :notice => t("flash.sites.create.notice") }

      elsif transaction.failed?
        format.html { redirect_to :sites, :alert => t("transaction.errors.#{transaction.i18n_error_key}") }
      end
    end
  end

end
