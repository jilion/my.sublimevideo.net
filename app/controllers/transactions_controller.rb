class TransactionsController < ApplicationController
  respond_to :html

  skip_before_filter :authenticate_user!
  before_filter do |controller|
    if tempered_request?
      render(text: "Tampered request!", status: 400) and return
    end
  end

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

    elsif operation_was?(:payment)

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

    when :payment
      params["PAYMENT"] && params["USER_ID"]
    end
  end

  def tempered_request?
    params.delete(:controller)
    params.delete(:action)

    params_for_sha_out = params.select { |k, v| keys_used_for_sha_out.include?(k.upcase) }

    string_to_digest = params_for_sha_out.sort { |a, b| a[0].upcase <=> b[0].upcase }.map { |k, v| "#{k.upcase}=#{v}" unless v.blank? }.compact.join(Ogone.yml[:signature_out]) + Ogone.yml[:signature_out]

    params["SHASIGN"] != Digest::SHA512.hexdigest(string_to_digest).upcase
  end

  def process_cc_authorization
    @user = User.find(params["USER_ID"].to_i)
    @user.process_cc_authorization_response(params, [params["PAYID"], 'RES'].join(';'))

    respond_with do |format|
      if @user.errors.empty? && @user.save
        flash[:notice] = t("flash.credit_cards.update.notice")
      else
        flash[:alert] = "You credit card could not be authorized, please retry with another credit card."
      end
      format.html { redirect_to [:edit, :user_registration] }
    end
  end

  def keys_used_for_sha_out
    %w[AAVADDRESS AAVCHECK AAVZIP ACCEPTANCE ALIAS AMOUNT BIN BRAND CARDNO CCCTY CN COMPLUS CREATION_STATUS CURRENCY
      CVCCHECK DCC_COMMPERCENTAGE DCC_CONVAMOUNT DCC_CONVCCY DCC_EXCHRATE DCC_EXCHRATESOURCE DCC_EXCHRATETS
      DCC_INDICATOR DCC_MARGINPERC ENTAGE DCC_VALIDHOURS DIGESTC ARDNO ECI ED ENCCARDNO IP IPCTY NBREMAILUSAGE
      NBRIPUSAGE NBRIPUSAGE_ALLTX NBRUSAGE NCERROR ORDERID PAYID PM SCO_CATEGORY SCORING STATUS SUBSC RIPTION_ID TRXDATE VC]
  end

end
