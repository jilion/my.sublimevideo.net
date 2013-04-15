module Admin::InvoicesHelper

  PAGE_TITLES = {
    search: "matching '%s'",
    user_id: 'for %s',
    paid: 'paid',
    with_state: '%s'
  }

  def admin_invoices_page_title(invoices)
    return unless selected_params = _select_param(:paid, :with_state, :user_id, :search)

    filter_titles = selected_params.reduce([]) { |a, e| a << _page_title_from_filter(*e) }

    [formatted_pluralize(invoices.total_count, 'invoice').titleize, filter_titles.to_sentence].join(' ')
  end

  private

  def _select_param(*keys)
    params.select { |k, _| k.to_sym.in?(keys) }
  end

  def _page_title_from_filter(key, value)
    key = key.to_sym
    PAGE_TITLES[key] ? (PAGE_TITLES[key] % _value_for_filter_title_interpolation(key, value)) : _admin_invoices_page_title(key)
  end

  def _value_for_filter_title_interpolation(key, value)
    case key
    when :user_id
      User.find(value).try(:name_or_email)
    else
      value
    end
  end

  def _admin_invoices_page_title(underscored_name, value = nil)
    ["#{underscored_name.to_s.gsub(/_/, ' ')}", value].compact.join(' ')
  end

end
