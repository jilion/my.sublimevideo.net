module Admin::FeedbacksHelper

  def display_kind(feedback)
    feedback.kind ? t("feedback.kind.#{feedback.kind}") : 'Cancellation'
  end

  def feedbacks_cancellations_per_month_chart
    line_chart(Feedback.where(kind: 'account_cancellation').group_by_month(:created_at, 'Bern').count, library: { title: { text: '# of cancellation per month' } })
  end

  def feedbacks_reasons_chart
    raw_feedbacks_for_chart = Feedback.group(:reason).count
    total_feedbacks_count = raw_feedbacks_for_chart.sum { |k, v| v }
    feedbacks_for_chart = raw_feedbacks_for_chart.map { |k, v| [k.titleize, display_percentage(v / total_feedbacks_count.to_f)]}

    pie_chart(feedbacks_for_chart, library: { title: { text: 'Reasons for not using SV / cancelling' } })
  end

end
