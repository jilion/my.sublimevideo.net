require 'spec_helper'

require 'users_tasks'

describe UsersTasks do
  describe '.cancel_failed_invoices_and_unsuspend_everyone' do
    let!(:failed_invoice) { create(:invoice, state: 'failed') }
    let!(:suspended_user) { UserManager.new(build(:user)).tap { |sm| sm.create; sm.suspend }.user }

    it 'cancel failed invoices' do
      expect(failed_invoice).to be_failed

      described_class.cancel_failed_invoices_and_unsuspend_everyone

      expect(failed_invoice.reload).to be_canceled
    end

    it 'unsuspend suspended users' do
      expect(suspended_user).to be_suspended

      described_class.cancel_failed_invoices_and_unsuspend_everyone

      expect(suspended_user.reload).to be_active
    end
  end
end
