# coding: utf-8

module ApplicationHelper

  def display_bool(boolean)
    boolean == 0 || boolean.blank? || !boolean ? '–' : '✓'
  end

  def display_date(date, opts = {})
    opts.reverse_merge!(format: :d_b_Y)

    content_tag(:strong, display_time(date, opts))
  end

  def display_time(date, opts = {})
    opts.reverse_merge!(format: :minutes_y)

    date ? l(date, format: opts[:format]) : '–'
  end

  def display_integer(number, opts = {})
    opts.reverse_merge!(precision: 2, significant: false)

    number_with_delimiter(number, opts)
  end

  def display_percentage(fraction, opts = {})
    opts.reverse_merge!(precision: 2, strip_insignificant_zeros: true)
    fraction ||= 0

    percent = number_to_percentage(fraction * 100.0, precision: opts[:precision], strip_insignificant_zeros: opts[:strip_insignificant_zeros])

    if !fraction.zero? && percent.sub(/%/, '').to_f < 0.01
      '< 0.01%'
    else
      percent
    end
  end

  def display_vat_percentage
    number_to_percentage(Vat.for_country(current_user.billing_country) * 100, precision: 0, strip_insignificant_zeros: true)
  end

  def display_amount(amount_in_cents, opts = {})
    number = amount_in_cents / 100.0
    decimals = !opts[:decimals] && number == number.to_i ? 0 : opts[:decimals] || 2

    number_to_currency(number, precision: decimals)
  end

  def display_amount_with_sup(amount_in_cents)
    units    = amount_in_cents.to_i / 100
    decimals = amount_in_cents.to_i - (units * 100)
    "#{number_to_currency(units, precision: 0)}#{content_tag(:sup, ".#{decimals}") unless decimals.zero?}#{content_tag(:small, '/mo')}".html_safe
  end

  def info_box(options = {}, &block)
    content_tag(:div, class: 'info_box' + (options[:class] ? " #{options[:class]}" : '')) do
      capture_haml(&block).chomp.html_safe + content_tag(:span, nil, class: 'arrow')
    end
  end

  def full_days_until_date(date)
    ((date - Time.now.utc.midnight) / (3600 * 24)).to_i
  end

  def tooltip_box(options = {}, &block)
    content_tag(:div, class: 'tooltip' + (options[:class] ? " #{options[:class]}" : '')) do
      content_tag(
        :a,
        (options[:class] ? "<span>#{options[:class]}</span>".html_safe : '<span></span>'.html_safe),
        href: (options[:href] ? options[:href] : '#'),
        onclick: "#{'window.open(this);' if options[:href]}return false;", class: 'icon') +
        content_tag(:span, class: 'content') do
          content_tag(:span, nil, class: 'arrow') + capture_haml(&block).chomp.html_safe
      end
    end
  end

  def beta_loader_required(site)
    content_tag(:div, id: 'beta_loader_required') do
      tooltip_box(class: 'info') do
        haml_tag(:span, 'The features or settings on this page only apply to the new SublimeVideo player (in beta) powered by SublimeVideo Horizon.', class: 'p')
      end + content_tag(:h5, class: 'label') do
        haml_tag(:a, 'Beta loader required', href: '', class: 'loader_code hl', data: { token: site.token })
        haml_tag(:div, render('sites/code', site: site), id: "loader_code_popup_content_#{site.token}", style: 'display:none')
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

  def url_host(url)
    URI(url).host
  rescue
    url.gsub(%r{https?://([^/]*)/.*}, '\1')
  end

end
