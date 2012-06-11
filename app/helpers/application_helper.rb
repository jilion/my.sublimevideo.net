# coding: utf-8
require_dependency 'vat'

module ApplicationHelper

  def display_bool(boolean)
    boolean == 0 || boolean.blank? || !boolean ? "–" : "✓"
  end

  def display_date(date, options = { format: :d_b_Y })
    content_tag(:strong, display_time(date, options))
  end

  def display_time(date, options = { format: :minutes_y })
    date ? l(date, format: options[:format]) : "–"
  end

  def display_integer(number, options = { significant: false, precision: 2, delimiter: "'" })
    number_with_delimiter(number, options)
  end

  def display_percentage(fraction, options = {})
    number_to_percentage(fraction * 100.0, precision: options[:precision] || 2, strip_insignificant_zeros: true)
  end

  def display_vat_percentage
    number_to_percentage(Vat.for_country(current_user.billing_country) * 100, precision: 0, strip_insignificant_zeros: true)
  end

  def display_amount(amount_in_cents, options={})
    if options[:vat] && current_user.vat?
      vat_rate        = Vat.for_country(current_user.billing_country)
      amount_in_cents = (amount_in_cents * (1.0 + vat_rate)).round
    end
    number = amount_in_cents / 100.0
    number_to_currency(number, precision: (!options[:decimals] && number == number.to_i ? 0 : options[:decimals] || 2))
  end

  def display_amount_with_sup(amount_in_cents)
    units    = amount_in_cents.to_i / 100
    decimals = amount_in_cents.to_i - (units * 100)
    "#{number_to_currency(units, precision: 0)}#{content_tag(:sup, ".#{decimals}") unless decimals.zero?}".html_safe
  end

  def info_box(options = {}, &block)
    content_tag(:div, class: "info_box" + (options[:class] ? " #{options[:class]}" : "")) do
      capture_haml(&block).chomp.html_safe + content_tag(:span, nil, class: "arrow")
    end
  end

  def full_days_until_date(date)
    ((date - Time.now.utc.midnight) / (3600 * 24)).to_i
  end

  def tooltip_box(options = {}, &block)
    content_tag(:div, class: "tooltip" + (options[:class] ? " #{options[:class]}" : "")) do
      content_tag(
        :a,
        (options[:class] ? "<span>#{options[:class]}</span>".html_safe : "<span></span>".html_safe),
        href: (options[:href] ? " #{options[:href]}" : ""),
        onclick: (options[:href] ? "" : "return false"), class: "icon") +
        content_tag(:span, class: "content") do
          content_tag(:span, nil, class: "arrow") + capture_haml(&block).chomp.html_safe
      end
    end
  end

  def https_if_prod_or_staging
    Rails.env.production? || Rails.env.staging? ? 'https' : 'http'
  end

  def asset_url(asset)
    host = request ? '' : ActionController::Base.asset_host
    "#{host}#{asset_path(asset)}"
  end

  def demo_stats_page?
    request.subdomain == 'my' && request.path == '/sites/stats/demo'
  end

end
