require_dependency 'vat'

module Invoices
  class Builder

    attr_accessor :invoice

    def initialize(attributes = {})
      @invoice = Invoice.new(attributes)
    end

    def add_invoice_item(invoice_item)
      @invoice.invoice_items << invoice_item
    end

    def save
      if @invoice.valid?
        set_invoice_items_amount
        set_vat_rate_and_amount
        set_balance_deduction_amount
        set_amount
        @invoice.save
      else
        false
      end
    end

    private

      def set_invoice_items_amount
        @invoice.invoice_items_amount = @invoice.invoice_items.sum(&:amount)
      end

      def set_vat_rate_and_amount
        @invoice.vat_rate   = Vat.for_country(@invoice.site.user.billing_country)
        @invoice.vat_amount = (@invoice.invoice_items_amount * @invoice.vat_rate).round
      end

      def set_balance_deduction_amount
        @invoice.balance_deduction_amount = @invoice.site.user.balance > 0 ? [@invoice.site.user.balance, @invoice.invoice_items_amount].min : 0
      end

      def set_amount
        @invoice.amount = @invoice.invoice_items_amount + @invoice.vat_amount - @invoice.balance_deduction_amount
      end

  end
end
