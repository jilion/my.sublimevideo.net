require 'fast_spec_helper'
require_relative '../../../lib/goodbye_manager'

describe GoodbyeManager do

  unless defined?(StateMachine)
    module StateMachine
      class Error < StandardError; end
      class InvalidTransition < Error; def initialize(*args); end; end
    end
  end

  unless defined?(ActiveRecord)
    module ActiveRecord
      class Base
        def self.transaction(options = {}, &block); yield; end
      end
      class ActiveRecordError < StandardError; end
      class RecordInvalid < ActiveRecordError; def initialize(*args); end; end
    end
  end

  describe '.archive_user_and_save_feedback' do
    let(:archivable_user)     { stub('user', id: 12) }
    let(:non_archivable_user) { stub('user', id: 13) }
    let(:valid_feedback)      { stub('feedback') }
    let(:invalid_feedback)    { stub('feedback') }

    context 'feedback is valid' do
      context 'user is archivable' do
        before do
          valid_feedback.should_receive(:'user_id=').with(12)
        end

        it 'saves the associated feedback and archives the user' do
          valid_feedback.should_receive(:save!).and_return(true)
          archivable_user.should_receive(:archive!).and_return(true)

          described_class.archive_user_and_save_feedback(archivable_user, valid_feedback)
        end
      end

      context 'user is not archivable' do
        before do
          valid_feedback.should_receive(:'user_id=').with(13)
        end

        it 'dont archive the user and returns false' do
          valid_feedback.should_receive(:save!).and_return(true)
          non_archivable_user.should_receive(:archive!) { raise StateMachine::InvalidTransition.new(mock.as_null_object, mock.as_null_object, :foo) }

          described_class.archive_user_and_save_feedback(non_archivable_user, valid_feedback).should be_false
        end
      end
    end

    context 'feedback is invalid' do
      before do
        invalid_feedback.should_receive(:'user_id=').with(12)
        invalid_feedback.should_receive(:save!) { raise ActiveRecord::RecordInvalid.new(mock.as_null_object) }
      end

      it 'dont archives the user' do
        archivable_user.should_not_receive(:archive!)

        described_class.archive_user_and_save_feedback(archivable_user, invalid_feedback)
      end

      it 'returns false' do
        described_class.archive_user_and_save_feedback(archivable_user, invalid_feedback).should be_false
      end
    end

  end

end
