describe GoodbyeManager do

  describe '.archive_user_and_save_feedback' do
    let(:archivable_user)     { create(:user) }
    let(:valid_feedback)      { GoodbyeFeedback.new(next_player: 'JW Player', reason: 'support', comment: 'foo bar') }
    let(:invalid_feedback)    { GoodbyeFeedback.new(next_player: 'JW Player', reason: 'unknown', comment: 'foo bar') }

    context 'good password is given' do
      it 'archives the user' do
        described_class.archive_user_and_save_feedback(archivable_user, '123456', valid_feedback)

        archivable_user.reload.should be_archived
      end

      it 'saves the associated feedback' do
        described_class.archive_user_and_save_feedback(archivable_user, '123456', valid_feedback)

        feedback = GoodbyeFeedback.last
        feedback.user_id.should eq archivable_user.id
        feedback.next_player.should eq 'JW Player'
        feedback.reason.should eq 'support'
        feedback.comment.should eq 'foo bar'
      end

      context 'feedback is not valid' do
        it 'dont archive the user' do
          described_class.archive_user_and_save_feedback(archivable_user, '123456', invalid_feedback)

          archivable_user.reload.should_not be_archived
        end

        it 'dont save the associated feedback' do
          described_class.archive_user_and_save_feedback(archivable_user, '123456', invalid_feedback)

          feedback = GoodbyeFeedback.last
          feedback.should be_nil
        end
      end
    end

    context 'wrong password is given' do
      it 'dont archives the user' do
        described_class.archive_user_and_save_feedback(archivable_user, '654321', valid_feedback)

        archivable_user.should_not be_archived
      end

      it 'dont save the associated feedback' do
        described_class.archive_user_and_save_feedback(archivable_user, '654321', valid_feedback)

        feedback = GoodbyeFeedback.last
        feedback.should be_nil
      end
    end

  end

end
