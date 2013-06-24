class FeedbacksPopulator < Populator

  def execute
    PopulateHelpers.empty_tables(Feedback)
    count = 300
    user = User.last

    count.times do
      created_at = rand(24).months.ago
      Timecop.travel(created_at) do
        kind = rand > 0.9 ? :trial : :account_cancellation
        Feedback.create!({
          kind: kind, reason: Feedback::REASONS.sample, user_id: user.id, comment: Faker::Lorem.paragraphs(2).join("\n\n")
        }, without_protection: true)
      end
    end
    puts "#{count} feedbacks created for #{user.name}"
  end

end
