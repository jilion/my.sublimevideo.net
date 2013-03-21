class StatsExportMailer < Mailer
  default template_path: "mailers/#{self.mailer_name}", from: I18n.t('mailer.stats.email')

  helper :sites

  def export_ready(stats_export)
    @stats_export = stats_export
    @site         = @stats_export.site
    @user         = @site.user
    @from_date    = I18n.l(stats_export.from, format: :d_b_Y)
    @to_date      = I18n.l(stats_export.to, format: :d_b_Y)
    @no_reply     = true

    mail(to: @user.email,
         subject: _subject(__method__, hostname: @site.hostname, from: @from_date, to: @to_date))
  end

end
