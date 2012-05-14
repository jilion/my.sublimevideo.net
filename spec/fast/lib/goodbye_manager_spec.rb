require 'fast_spec_helper'
require_relative '../../../lib/goodbye_manager'

describe GoodbyeManager do

  describe '.archive_user_and_save_feedback' do
    let(:archivable_user)     { stub('user', id: 12, valid?: true, archive: true) }
    let(:non_archivable_user) { stub('user', id: 13, valid?: false) }
    let(:valid_feedback)      { stub('feedback', :'user_id=' => true, valid?: true, save: true) }
    let(:invalid_feedback)    { stub('feedback', :'user_id=' => true, valid?: false) }

    context 'feedback is valid' do
      before do valid_feedback.should_receive(:valid?).and_return(true) end

      context 'user is archivable' do
        before do
          valid_feedback.should_receive(:'user_id=').with(12)
          archivable_user.should_receive(:valid?).and_return(true)
        end

        it 'archives the user' do
          archivable_user.should_receive(:archive)

          described_class.archive_user_and_save_feedback(archivable_user, valid_feedback)
        end

        it 'saves the associated feedback' do
          valid_feedback.should_receive(:save)

          described_class.archive_user_and_save_feedback(archivable_user, valid_feedback)
        end
      end

      context 'user is not archivable' do
        before do
          valid_feedback.should_receive(:'user_id=').with(13)
          non_archivable_user.should_receive(:valid?).and_return(false)
        end

        it 'dont archive the user' do
          non_archivable_user.should_not_receive(:archive)

          described_class.archive_user_and_save_feedback(non_archivable_user, valid_feedback)
        end

        it 'dont save the associated feedback' do
          valid_feedback.should_not_receive(:save)

          described_class.archive_user_and_save_feedback(non_archivable_user, valid_feedback)
        end
      end
    end

    context 'feedback is invalid' do
      before do
        invalid_feedback.should_receive(:'user_id=').with(12)
        invalid_feedback.should_receive(:valid?).and_return(false)
      end

      it 'dont archives the user' do
        archivable_user.should_not_receive(:archive)

        described_class.archive_user_and_save_feedback(archivable_user, invalid_feedback)
      end

      it 'dont save the associated feedback' do
        invalid_feedback.should_not_receive(:save)

        described_class.archive_user_and_save_feedback(archivable_user, invalid_feedback)
      end
    end

  end

end
