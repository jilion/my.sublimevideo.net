module My::DealsHelper

  def deal_sentence(deal)
    text = content_tag(:strong, deal.description)
    text += " until #{l(deal.ended_at, format: :named_date)}."
  end

end
