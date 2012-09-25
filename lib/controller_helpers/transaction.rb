module ControllerHelpers
  module Transaction

    private

    def notice_and_alert_from_transaction(transaction)
      case transaction.try(:state)
      when "failed", "waiting"
        { notice: "", alert: t("transaction.errors.#{transaction.state}") }
      else
        { notice: nil, alert: nil }
      end
    end

  end
end
